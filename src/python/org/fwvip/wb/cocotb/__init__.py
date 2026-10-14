# ----------------------------------------------------------------------------
# cocotb backend for the Featherweight Wishbone VIP.
#
# Construct a backend from the cocotb top-level handle and the role's signal
# prefix (the top-level ready/valid ports it drives; see backend.py), and hand
# it to the matching front-end driver, e.g.:
#
#     from org.fwvip.wb import WbInitiator
#     from org.fwvip.wb.cocotb import CocotbInitiatorBackend
#
#     init = WbInitiator(CocotbInitiatorBackend(dut, "init_"))
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
