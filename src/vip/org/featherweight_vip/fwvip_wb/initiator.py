from __future__ import annotations
import zuspec.dataclasses as zdc
from typing import Protocol, Tuple
from org.featherweight_ip.protocol.core.wishbone import WishboneInitiator


class IInitiator(Protocol):
    async def access(
            self, 
            adr : zdc.u64, 
            dat_w : zdc.u64,
            sel : zdc.u8,
            we : zdc.bit) -> Tuple[zdc.bit, zdc.u64]: 
        ...


@zdc.dataclass(profile=zdc.profiles.RetargetableProfile)
class InitiatorXtor(zdc.XtorComponent[IInitiator]):
    """Implements """
    DATA_WIDTH : zdc.u32 = zdc.const(default=32)
    ADDR_WIDTH : zdc.u32 = zdc.const(default=32)
    clock : zdc.bit = zdc.input()
    reset : zdc.bit = zdc.input()
    init : WishboneInitiator = zdc.bundle(
        kwargs=lambda s: dict(
            DATA_WIDTH=lambda s: s.DATA_WIDTH, 
            ADDR_WIDTH=lambda s: s.ADDR_WIDTH))
    _adr : zdc.u32 = zdc.field()
    _dat_w : zdc.u32 = zdc.field()
    _dat_r : zdc.u32 = zdc.field()
    _sel : zdc.u4 = zdc.field()
    _we : zdc.bit = zdc.field()
    _err : zdc.bit = zdc.field()
    _req : zdc.bit = zdc.field()
    _ack : zdc.bit = zdc.field()
    _req_state : zdc.u8 = zdc.field()

    def __bind__(self):
        return (
            (self.xtor_if.access, self.access)
        )
    
    async def access(
            self,
            adr : zdc.u64, 
            dat_w : zdc.u64,
            sel : zdc.u8,
            we : zdc.bit) -> Tuple[zdc.bit, zdc.u64]:
        """Accepts data and control for an access. Returns data and error status"""
        self._adr = adr
        self._dat_w = dat_w
        self._sel = sel
        self._we = we

        await zdc.posedge(self.clock)
        while self.reset:
            await zdc.posedge(self.clock)

        self._req = 1
        await zdc.posedge(self.clock)

        while not self._ack:
            await zdc.posedge(self.clock)

        self._req = 0

        return (self._err, self._dat_r)

    @zdc.sync(clock=lambda s: s.clock, reset=lambda s: s.reset)
    def _req_fsm(self):
        if (self.reset):
            self._req_state = 0
            self.init.cyc = 0
        else:
            match self._req_state:
                case 0:
                    self._ack = 0
                    if self._req:
                        self.init.cyc = 1
                        self.init.adr = self._adr
                        self.init.dat_w = self._dat_w
                        self.init.we = self._we
                        self.init.sel = self._sel
                        self._req_state = 1
                case 1:
                    if self.init.ack:
                        self._ack = 1
                        self._req_state = 0
                        self._dat_r = self.init.dat_r
                        self._err = self.init.err
                        self.init.cyc = 0
    pass

