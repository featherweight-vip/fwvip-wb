"""Simple Wishbone target component for testing."""
import zuspec.dataclasses as zdc


@zdc.dataclass
class WishboneTarget(zdc.Component):
    """Simple Wishbone target that responds to read/write transactions."""
    DATA_WIDTH : zdc.u32 = zdc.const(default=32)
    ADDR_WIDTH : zdc.u32 = zdc.const(default=32)
    clock : zdc.bit = zdc.input()
    reset : zdc.bit = zdc.input()
    adr : zdc.bitv = zdc.input(width=lambda s:s.ADDR_WIDTH)
    dat_w : zdc.bitv = zdc.input(width=lambda s:s.DATA_WIDTH)
    dat_r : zdc.bitv = zdc.output(width=lambda s:s.DATA_WIDTH)
    cyc : zdc.bit = zdc.input()
    ack : zdc.bit = zdc.output()
    err : zdc.bit = zdc.output()
    sel : zdc.bitv = zdc.input(width=lambda s:int(s.DATA_WIDTH/8))
    we : zdc.bit = zdc.input()
    
    _state : zdc.u8 = zdc.field()
    _mem : zdc.u64 = zdc.field()
    
    @zdc.sync(clock=lambda s:s.clock, reset=lambda s:s.reset)
    def _target_fsm(self):
        if self.reset:
            self._state = 0
            self.ack = 0
            self.err = 0
            self.dat_r = 0
        else:
            match self._state:
                case 0:
                    if self.cyc:
                        self._state = 1
                        self.ack = 1
                        if self.we:
                            # Write: store dat_w in memory
                            self._mem = self.dat_w
                        else:
                            # Read: provide data from memory
                            self.dat_r = self._mem
                case 1:
                    self.ack = 0
                    self._state = 0
