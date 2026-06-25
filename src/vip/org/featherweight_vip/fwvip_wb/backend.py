# ----------------------------------------------------------------------------
# Backend-independent contracts for the Wishbone VIP.
#
# A backend's sole job is to move raw bit vectors across a transactor's
# ready/valid ("FIFO") streams and to expose the reset state. All Wishbone
# semantics (packing, memory models, ...) live in the front-end, so a backend
# can be implemented for any execution environment (cocotb, a C/DPI bridge, a
# pure-Python model, ...) without re-deriving the protocol.
#
# Every method is async so a backend can suspend until the simulator (or other
# environment) is ready to make progress.
# ----------------------------------------------------------------------------
from __future__ import annotations

from abc import ABC, abstractmethod


class Backend(ABC):
    """Common backend capability: observe the transactor's reset."""

    @abstractmethod
    async def reset_done(self) -> None:
        """Return once the transactor is out of reset."""


class InitiatorBackend(Backend):
    """Drives the initiator transactor's request stream and consumes its
    response stream."""

    @abstractmethod
    async def push_request(self, data: int) -> None:
        """Send one request vector, completing the ready/valid handshake."""

    @abstractmethod
    async def pop_response(self) -> int:
        """Receive one response vector, completing the ready/valid handshake."""


class TargetBackend(Backend):
    """Consumes the target transactor's request stream and drives its response
    stream."""

    @abstractmethod
    async def pop_request(self) -> int:
        """Receive one request vector, completing the ready/valid handshake."""

    @abstractmethod
    async def push_response(self, data: int) -> None:
        """Send one response vector, completing the ready/valid handshake."""


class MonitorBackend(Backend):
    """Consumes the monitor transactor's egress stream of observed accesses."""

    @abstractmethod
    async def pop(self) -> int:
        """Receive one observed-transaction vector."""
