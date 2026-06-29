# ----------------------------------------------------------------------------
# Wishbone target front-end: a friendly developer API over a TargetBackend.
# Provides low-level request/respond primitives plus a ready-made word-memory
# responder.
# ----------------------------------------------------------------------------
from __future__ import annotations

from typing import Callable, Dict, Optional

from .backend import TargetBackend
from .transaction import WbLayout, WbReq, WbRsp


class WbTarget:
    def __init__(self, backend: TargetBackend,
                 addr_width: int = 32, data_width: int = 32):
        self._backend = backend
        self.layout = WbLayout(addr_width, data_width)

    async def reset_done(self) -> None:
        await self._backend.reset_done()

    async def next_request(self) -> WbReq:
        """Wait for and return the next request the transactor observed."""
        return self.layout.unpack_req(await self._backend.pop_request())

    async def respond(self, rsp: WbRsp) -> None:
        """Provide the response for the most recent request."""
        await self._backend.push_response(self.layout.pack_rsp(rsp))

    async def serve_memory(self,
                           mem: Optional[Dict[int, int]] = None,
                           err: Optional[Callable[[WbReq], bool]] = None
                           ) -> Dict[int, int]:
        """Service requests forever from a simple word-addressable memory.

        *mem* maps word index (adr >> 2) to data; a fresh dict is used if not
        given. *err* is an optional predicate to inject error responses. The
        backing store is returned (handy if a fresh one was created) although
        this coroutine only returns if cancelled."""
        if mem is None:
            mem = {}
        await self.reset_done()
        while True:
            req = await self.next_request()
            is_err = bool(err(req)) if err is not None else False
            if is_err:
                await self.respond(WbRsp(dat=0, err=True))
                continue
            idx = req.adr >> 2
            if req.we:
                mem[idx] = req.dat & self.layout.data_mask
                dat = mem[idx]
            else:
                dat = mem.get(idx, 0)
            await self.respond(WbRsp(dat=dat, err=False))
        return mem
