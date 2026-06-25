# ----------------------------------------------------------------------------
# Featherweight Wishbone VIP -- backend-independent Python API.
#
# The front-end (WbInitiator / WbTarget / WbMonitor) provides a friendly
# developer API and owns all Wishbone protocol knowledge. It is driven by a
# backend implementing the contracts in `backend`; a cocotb backend lives in
# the `cocotb` subpackage.
# ----------------------------------------------------------------------------
from .transaction import WbReq, WbRsp, WbMonTxn, WbLayout
from .backend import (
    Backend,
    InitiatorBackend,
    TargetBackend,
    MonitorBackend,
)
from .initiator import WbInitiator
from .target import WbTarget
from .monitor import WbMonitor

__all__ = [
    "WbReq", "WbRsp", "WbMonTxn", "WbLayout",
    "Backend", "InitiatorBackend", "TargetBackend", "MonitorBackend",
    "WbInitiator", "WbTarget", "WbMonitor",
]
