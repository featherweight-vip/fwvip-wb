# ----------------------------------------------------------------------------
# cocotb backend for the Featherweight Wishbone VIP.
#
# Each backend is constructed with a cocotb handle to a transactor *core*
# instance (e.g. dut.u_initiator) and drives/samples that core's generic
# ready/valid ("FIFO") ports -- req_*/rsp_* (initiator, target) or mon_*
# (monitor). Because it works off the core's own port names it is independent
# of any particular top-level wiring or signal naming.
#
# The clock and reset default to the core's own `clock`/`reset` ports but may
# be overridden (e.g. when reset is generated elsewhere).
#
# NOTE: `import cocotb` here resolves to the top-level cocotb package, not this
# subpackage (Python 3 uses absolute imports), so there is no name clash.
# ----------------------------------------------------------------------------
from __future__ import annotations

from typing import Any, List, Optional

import cocotb
from cocotb.triggers import RisingEdge

from ..backend import InitiatorBackend, TargetBackend, MonitorBackend


class _CocotbBackendBase:
    def __init__(self, transactor: Any,
                 clock: Optional[Any] = None,
                 reset: Optional[Any] = None):
        self.x = transactor
        self.clock = clock if clock is not None else transactor.clock
        # reset is optional; default to the core's reset port if present
        if reset is not None:
            self.reset = reset
        else:
            self.reset = getattr(transactor, "reset", None)

    async def reset_done(self) -> None:
        if self.reset is None:
            return
        while int(self.reset.value) != 0:
            await RisingEdge(self.clock)


class CocotbInitiatorBackend(_CocotbBackendBase, InitiatorBackend):
    def __init__(self, transactor, clock=None, reset=None):
        super().__init__(transactor, clock, reset)
        # Idle: not requesting, always ready to accept responses
        self.x.req_valid.value = 0
        self.x.rsp_ready.value = 1

    async def push_request(self, data: int) -> None:
        x = self.x
        x.req_dat.value = data
        x.req_valid.value = 1
        await RisingEdge(self.clock)
        while not int(x.req_ready.value):
            await RisingEdge(self.clock)
        x.req_valid.value = 0

    async def pop_response(self) -> int:
        x = self.x
        x.rsp_ready.value = 1
        while not int(x.rsp_valid.value):
            await RisingEdge(self.clock)
        data = int(x.rsp_dat.value)
        await RisingEdge(self.clock)
        return data


class CocotbTargetBackend(_CocotbBackendBase, TargetBackend):
    def __init__(self, transactor, clock=None, reset=None):
        super().__init__(transactor, clock, reset)
        # Idle: always ready to accept produced requests, not responding
        self.x.req_ready.value = 1
        self.x.rsp_valid.value = 0

    async def pop_request(self) -> int:
        x = self.x
        x.req_ready.value = 1
        await RisingEdge(self.clock)
        while not (int(x.req_valid.value) and int(x.req_ready.value)):
            await RisingEdge(self.clock)
        return int(x.req_dat.value)

    async def push_response(self, data: int) -> None:
        x = self.x
        x.rsp_dat.value = data
        x.rsp_valid.value = 1
        await RisingEdge(self.clock)
        while not (int(x.rsp_valid.value) and int(x.rsp_ready.value)):
            await RisingEdge(self.clock)
        x.rsp_valid.value = 0


class CocotbMonitorBackend(_CocotbBackendBase, MonitorBackend):
    """The monitor egress stream fires autonomously as bus accesses complete,
    so a background sampler holds `mon_ready` high and captures every observed
    vector into a buffer that `pop()` drains -- decoupling observation from
    consumption so transactions are never missed."""

    def __init__(self, transactor, clock=None, reset=None):
        super().__init__(transactor, clock, reset)
        self.x.mon_ready.value = 1
        self._buf: List[int] = []
        self._sampler = cocotb.start_soon(self._sample())

    async def _sample(self) -> None:
        x = self.x
        while True:
            await RisingEdge(self.clock)
            if self.reset is not None and int(self.reset.value):
                continue
            if int(x.mon_valid.value) and int(x.mon_ready.value):
                self._buf.append(int(x.mon_dat.value))

    async def pop(self) -> int:
        while not self._buf:
            await RisingEdge(self.clock)
        return self._buf.pop(0)
