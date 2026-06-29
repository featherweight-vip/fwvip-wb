# ----------------------------------------------------------------------------
# cocotb backend for the Featherweight Wishbone VIP.
#
# Construct a backend with a cocotb handle to a transactor core instance and
# hand it to the matching front-end driver, e.g.:
#
#     from org.fwvip.wb import WbInitiator
#     from org.fwvip.wb.cocotb import CocotbInitiatorBackend
#
#     init = WbInitiator(CocotbInitiatorBackend(dut.u_initiator))
#     await init.reset_done()
#     rsp = await init.write(0x10, 0xDEADBEEF)
# ----------------------------------------------------------------------------
from .backend import (
    CocotbInitiatorBackend,
    CocotbTargetBackend,
    CocotbMonitorBackend,
)

__all__ = [
    "CocotbInitiatorBackend",
    "CocotbTargetBackend",
    "CocotbMonitorBackend",
]
