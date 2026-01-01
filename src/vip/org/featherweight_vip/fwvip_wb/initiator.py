from __future__ import annotations
import zuspec.dataclasses as zdc
from typing import Protocol

class IInitiatorBFM(Protocol):
    pass

class InitiatorBFM(zdc.Component):
    DATA_WIDTH : zdc.u32 = zdc.const(default=32)
    ADDR_WIDTH : zdc.u32 = zdc.const(default=32)
    clock : zdc.bit = zdc.input()
    reset : zdc.bit = zdc.input()
    init : WBInitiator = zdc.bundle(
        init=lambda s:dict(DATA_WIDTH=s.DATA_WIDTH, ADDR_WIDTH=s.ADDR_WIDTH))

    bfm_if : IInitiatorBFM = zdc.export()

    async def read(self, addr : zdc.u64) -> zdc.u64:
        # Setup packed struct
        # Push to request fifo
        # Wait for response from response fifo
        return 0


    pass

class InitiatorBFMCore(zdc.Component):
    init : WBInitiator = zdc.bundle(
        init=lambda s:dict(DATA_WIDTH=s.DATA_WIDTH, ADDR_WIDTH=s.ADDR_WIDTH))
    # FIFO interface bundles for req/rsp 
    pass

class InitiatorBFMSV(InitiatorBFM):
    # TODO: add domain annotations
    pass
