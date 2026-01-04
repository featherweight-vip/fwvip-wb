
from __future__ import annotations
import zuspec.dataclasses as zdc
from typing import Protocol, Tuple
from org.featherweight_ip.protocol.core.wishbone import WishboneTarget

class ITarget(Protocol):
    async def get_request(self) -> Tuple[zdc.u64, zdc.u64, zdc.u8, zdc.bit]:
        """Collect a request from the bus. Returns (adr, dat_w, sel, we)"""
        ...
    
    async def put_response(self, dat_r : zdc.u64, err : zdc.bit) -> None:
        """Submit response data to the bus"""
        ...

@zdc.dataclass
class TargetXtor(zdc.XtorComponent[ITarget]):
    """Target transactor implementing Wishbone target interface"""
    DATA_WIDTH : zdc.u32 = zdc.const(default=32)
    ADDR_WIDTH : zdc.u32 = zdc.const(default=32)
    clock : zdc.bit = zdc.input()
    reset : zdc.bit = zdc.input()
    targ : WishboneTarget = zdc.bundle(
        kwargs=lambda s:dict(
            DATA_WIDTH=lambda s:s.DATA_WIDTH, 
            ADDR_WIDTH=lambda s:s.ADDR_WIDTH))
    _adr : zdc.u32 = zdc.field()
    _dat_w : zdc.u32 = zdc.field()
    _dat_r : zdc.u32 = zdc.field()
    _sel : zdc.u4 = zdc.field()
    _we : zdc.bit = zdc.field()
    _err : zdc.bit = zdc.field()
    _req_valid : zdc.bit = zdc.field()
    _resp_ready : zdc.bit = zdc.field()
    _resp_state : zdc.u8 = zdc.field()

    def __bind__(self): return (
        (self.xtor_if.get_request, self.get_request),
        (self.xtor_if.put_response, self.put_response)
    )

    async def get_request(self) -> Tuple[zdc.u64, zdc.u64, zdc.u8, zdc.bit]:
        """Wait for and collect a request from the bus"""
        await zdc.posedge(self.clock)
        while self.reset:
            await zdc.posedge(self.clock)

        while not self._req_valid:
            await zdc.posedge(self.clock)

        adr = self._adr
        dat_w = self._dat_w
        sel = self._sel
        we = self._we
        
        self._req_valid = 0
        
        return (adr, dat_w, sel, we)
    
    async def put_response(self, dat_r : zdc.u64, err : zdc.bit) -> None:
        """Submit response data back to the initiator"""
        self._dat_r = dat_r
        self._err = err
        self._resp_ready = 1
        
        await zdc.posedge(self.clock)
        while self._resp_state != 0:
            await zdc.posedge(self.clock)
        
        self._resp_ready = 0

    @zdc.sync(clock=lambda s:s.clock, reset=lambda s:s.reset)
    def _resp_fsm(self):
        if (self.reset):
            self._resp_state = 0
            self.targ.ack = 0
            self.targ.dat_r = 0
            self.targ.err = 0
        else:
            match self._resp_state:
                case 0:
                    if self.targ.cyc:
                        self._adr = self.targ.adr
                        self._dat_w = self.targ.dat_w
                        self._sel = self.targ.sel
                        self._we = self.targ.we
                        self._req_valid = 1
                        self._resp_state = 1
                case 1:
                    if self._resp_ready:
                        self.targ.ack = 1
                        self.targ.dat_r = self._dat_r
                        self.targ.err = self._err
                        self._resp_state = 2
                case 2:
                    if not self.targ.cyc:
                        self.targ.ack = 0
                        self._resp_state = 0
    pass
