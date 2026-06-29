# ----------------------------------------------------------------------------
# cocotb backend for the Featherweight Wishbone VIP.
#
# Each backend is constructed with the cocotb top handle and a per-role signal
# prefix -- CocotbInitiatorBackend(dut, "init_"), CocotbTargetBackend(dut,
# "tgt_"), CocotbMonitorBackend(dut, "mon_") -- and drives/samples the
# corresponding TOP-LEVEL ready/valid ("FIFO") signals (init_req_*/init_rsp_*,
# tgt_req_*/tgt_rsp_*, mon_*). Driving top-level signals (rather than a core's
# sub-instance ports) is what lets the same backend run on BOTH Verilator and
# Icarus: Verilator does not honour cocotb writes to a sub-instance's input
# ports (it recomputes them every eval), so the cocotb-driven inputs must be
# top-level regs/logic. See the cocotb driving note + cocotb-performance.md.
#
# The ready/valid handshake is implemented through the two canonical
# Featherweight primitives `_rv_get` (consumer) / `_rv_put` (producer) -- the
# same pattern every Featherweight cocotb interface uses (see
# packages/fwvip-core/docs/cocotb-performance.md): event-driven while idle (sleep
# on the signal edge, never poll the clock), and SAMPLE/CHECK AT THE CLOCK EDGE
# in a loop so the value is settled (correct for the WB cores' *combinational*
# req/rsp data as well as registered data) and a stale post-transfer read can't
# shift a beat.
#
# NOTE: `import cocotb` here resolves to the top-level cocotb package, not this
# subpackage (Python 3 uses absolute imports), so there is no name clash.
# ----------------------------------------------------------------------------
from __future__ import annotations

from typing import Any, List, Optional

import cocotb
from cocotb.triggers import Event, FallingEdge, RisingEdge

from ..backend import InitiatorBackend, TargetBackend, MonitorBackend


def _ival(sig) -> int:
    """Read a 1-bit control signal as int, treating X/Z (unresolved before the
    first edge) as 0 -- i.e. 'not valid/ready yet', so we wait on its edge."""
    try:
        return int(sig.value)
    except ValueError:
        return 0


class _CocotbBackendBase:
    def __init__(self, dut: Any, prefix: str,
                 clock: Optional[Any] = None,
                 reset: Optional[Any] = None):
        self.dut = dut
        self.prefix = prefix
        self.clock = clock if clock is not None else dut.clock
        self.reset = reset if reset is not None else getattr(dut, "reset", None)

    def _sig(self, name: str) -> Any:
        """Resolve a role signal by its top-level name (prefix + name)."""
        return getattr(self.dut, self.prefix + name)

    # ---- the ready/valid handshake (the one place it is implemented) --------
    async def _rv_get(self, valid: Any, dat: Any) -> int:
        """Consumer (we hold ready high): block until a transfer and return the
        data. Event-driven while idle; sampled AT the clock edge (settled)."""
        while True:
            if not _ival(valid):
                await RisingEdge(valid)        # idle: sleep until valid asserts
            await RisingEdge(self.clock)       # a clock edge
            if _ival(valid):                   # valid & ready held -> transfer here
                return int(dat.value)          # sample at the (settled) transfer edge
            # valid deasserted before this edge -> re-arm

    async def _rv_put(self, valid: Any, ready: Any, dat: Any, value: int) -> None:
        """Producer: drive valid+data, block until accepted, then deassert valid."""
        dat.value = value
        valid.value = 1
        while True:
            if not _ival(ready):
                await RisingEdge(ready)        # busy: sleep until the core is ready
            await RisingEdge(self.clock)       # a clock edge
            if _ival(ready):                   # valid & ready held -> accepted here
                break
            # ready deasserted before this edge -> re-arm
        valid.value = 0

    async def reset_done(self) -> None:
        if self.reset is None:
            return
        await RisingEdge(self.clock)           # settle past t=0
        if _ival(self.reset):
            await FallingEdge(self.reset)


class CocotbInitiatorBackend(_CocotbBackendBase, InitiatorBackend):
    def __init__(self, dut, prefix="init_", clock=None, reset=None):
        super().__init__(dut, prefix, clock, reset)
        self._sig("req_valid").value = 0
        self._sig("rsp_ready").value = 1       # always ready to accept responses

    async def push_request(self, data: int) -> None:
        await self._rv_put(self._sig("req_valid"), self._sig("req_ready"),
                           self._sig("req_dat"), data)

    async def pop_response(self) -> int:
        return await self._rv_get(self._sig("rsp_valid"), self._sig("rsp_dat"))


class CocotbTargetBackend(_CocotbBackendBase, TargetBackend):
    def __init__(self, dut, prefix="tgt_", clock=None, reset=None):
        super().__init__(dut, prefix, clock, reset)
        self._sig("req_ready").value = 1       # always ready to accept produced requests
        self._sig("rsp_valid").value = 0

    async def pop_request(self) -> int:
        return await self._rv_get(self._sig("req_valid"), self._sig("req_dat"))

    async def push_response(self, data: int) -> None:
        await self._rv_put(self._sig("rsp_valid"), self._sig("rsp_ready"),
                           self._sig("rsp_dat"), data)


class CocotbMonitorBackend(_CocotbBackendBase, MonitorBackend):
    """The monitor egress stream fires autonomously as bus accesses complete; a
    background sampler consumes each observed vector via the shared `_rv_get`
    (mon_ready held high) and buffers it; `pop()` drains via an Event (no poll)."""

    def __init__(self, dut, prefix="mon_", clock=None, reset=None):
        super().__init__(dut, prefix, clock, reset)
        self._sig("ready").value = 1
        self._buf: List[int] = []
        self._ev = Event()
        self._sampler = cocotb.start_soon(self._sample())

    async def _sample(self) -> None:
        await RisingEdge(self.clock)           # settle past t=0 before any read
        while True:
            self._buf.append(await self._rv_get(self._sig("valid"), self._sig("dat")))
            self._ev.set()

    async def pop(self) -> int:
        while not self._buf:
            self._ev.clear()
            await self._ev.wait()
        return self._buf.pop(0)
