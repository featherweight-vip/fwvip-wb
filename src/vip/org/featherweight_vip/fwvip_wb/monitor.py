# ----------------------------------------------------------------------------
# Wishbone monitor front-end: a friendly developer API over a MonitorBackend.
# ----------------------------------------------------------------------------
from __future__ import annotations

from .backend import MonitorBackend
from .transaction import WbLayout, WbMonTxn


class WbMonitor:
    def __init__(self, backend: MonitorBackend,
                 addr_width: int = 32, data_width: int = 32):
        self._backend = backend
        self.layout = WbLayout(addr_width, data_width)

    async def reset_done(self) -> None:
        await self._backend.reset_done()

    async def next(self) -> WbMonTxn:
        """Wait for and return the next observed transaction."""
        return self.layout.unpack_mon(await self._backend.pop())

    def __aiter__(self):
        return self

    async def __anext__(self) -> WbMonTxn:
        return await self.next()
