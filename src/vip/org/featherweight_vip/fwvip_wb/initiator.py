# ----------------------------------------------------------------------------
# Wishbone initiator front-end: a friendly developer API over an
# InitiatorBackend. Knows the Wishbone protocol (packing); delegates all
# stream/handshake work to the backend.
# ----------------------------------------------------------------------------
from __future__ import annotations

from typing import Optional

from .backend import InitiatorBackend
from .transaction import WbLayout, WbReq, WbRsp


class WbInitiator:
    def __init__(self, backend: InitiatorBackend,
                 addr_width: int = 32, data_width: int = 32):
        self._backend = backend
        self.layout = WbLayout(addr_width, data_width)

    async def reset_done(self) -> None:
        await self._backend.reset_done()

    async def request(self, req: WbReq) -> WbRsp:
        """Issue an arbitrary request and return its response."""
        await self._backend.push_request(self.layout.pack_req(req))
        return self.layout.unpack_rsp(await self._backend.pop_response())

    async def write(self, adr: int, dat: int, sel: Optional[int] = None) -> WbRsp:
        return await self.request(WbReq(adr=adr, dat=dat, we=True, sel=sel))

    async def read(self, adr: int, sel: Optional[int] = None) -> WbRsp:
        return await self.request(WbReq(adr=adr, dat=0, we=False, sel=sel))
