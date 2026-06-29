# ----------------------------------------------------------------------------
# Cocotb testbench for fwvip_wb_cocotb_top, exercising the backend-independent
# Wishbone VIP front-end (org.fwvip.wb) over its cocotb
# backend. The test code talks only to the friendly front-end API; the cocotb
# backends handle all FIFO/handshake interaction with the transactor cores.
# ----------------------------------------------------------------------------
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge

from org.fwvip.wb import WbInitiator, WbTarget, WbMonitor
from org.fwvip.wb.cocotb import (
    CocotbInitiatorBackend,
    CocotbTargetBackend,
    CocotbMonitorBackend,
)


async def apply_reset(dut, cycles=5):
    dut.reset.value = 1
    for _ in range(cycles):
        await RisingEdge(dut.clock)
    await FallingEdge(dut.clock)
    dut.reset.value = 0


@cocotb.test()
async def test_wb_write_read(dut):
    """3 writes then 3 reads via the VIP front-end, checked through the monitor."""
    cocotb.start_soon(Clock(dut.clock, 10, unit="ns").start())

    # Front-end drivers, each bound to a cocotb backend constructed from the
    # top-level dut handle and the corresponding role signal prefix. Driving
    # top-level signals (rather than core sub-instance ports) is what lets this
    # run on both Verilator and Icarus.
    initiator = WbInitiator(CocotbInitiatorBackend(dut, "init_"))
    target = WbTarget(CocotbTargetBackend(dut, "tgt_"))
    monitor = WbMonitor(CocotbMonitorBackend(dut, "mon_"))

    await apply_reset(dut)
    await initiator.reset_done()

    # Target services accesses from a fresh word memory in the background.
    mem = {}
    cocotb.start_soon(target.serve_memory(mem))

    # Collect observed transactions in the background.
    seen = []

    async def collect():
        while True:
            seen.append(await monitor.next())
    cocotb.start_soon(collect())

    vectors = [
        (0x0000_0000, 0xA5A5_0000),
        (0x0000_0004, 0x5A5A_1111),
        (0x0000_0008, 0xDEAD_BEEF),
    ]

    # Writes
    for adr, dat in vectors:
        rsp = await initiator.write(adr, dat)
        assert not rsp.err, f"unexpected err on write @0x{adr:08x}"

    # Reads (check readback)
    for adr, dat in vectors:
        rsp = await initiator.read(adr)
        assert not rsp.err, f"unexpected err on read @0x{adr:08x}"
        assert rsp.dat == dat, \
            f"readback mismatch @0x{adr:08x}: got 0x{rsp.dat:08x} exp 0x{dat:08x}"

    # Let the monitor drain the final transaction
    for _ in range(5):
        await RisingEdge(dut.clock)

    assert len(seen) == 2 * len(vectors), \
        f"monitor saw {len(seen)} transactions, expected {2 * len(vectors)}"

    for i, (adr, dat) in enumerate(vectors):
        m = seen[i]
        assert m.we and m.adr == adr and m.dat == dat, f"monitor write[{i}] mismatch: {m}"
    for i, (adr, dat) in enumerate(vectors):
        m = seen[len(vectors) + i]
        assert not m.we and m.adr == adr and m.dat == dat, f"monitor read[{i}] mismatch: {m}"

    dut._log.info("Completed %d accesses via VIP front-end, monitor saw %d transactions",
                  2 * len(vectors), len(seen))
