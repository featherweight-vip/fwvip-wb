# ----------------------------------------------------------------------------
# Backend-independent Wishbone VIP transactions and RV-vector bit layout.
#
# The three transactor cores exchange data with their environment over simple
# ready/valid ("FIFO") streams carrying packed-struct bit vectors. The packing
# is a property of the protocol (identical for every backend), so it lives here
# in the front-end rather than in any particular backend.
#
# SystemVerilog packed structs place the first declared field in the most
# significant bits, so the layouts below are MSB-first:
#   REQ (initiator/target): { adr, dat, we, sel(byte-enables) }
#   RSP (initiator/target): { dat, err }
#   MON (monitor):          { adr, dat, we, sel, err }
# ----------------------------------------------------------------------------
from __future__ import annotations

from dataclasses import dataclass
from typing import Optional


@dataclass
class WbReq:
    """A Wishbone access request."""
    adr: int
    dat: int = 0
    we: bool = False
    sel: Optional[int] = None   # byte enables; None -> all bytes selected


@dataclass
class WbRsp:
    """A Wishbone access response."""
    dat: int = 0
    err: bool = False


@dataclass
class WbMonTxn:
    """A transaction observed on the bus by the monitor."""
    adr: int
    dat: int     # write data when we=1, read data when we=0
    we: bool
    sel: int
    err: bool


class WbLayout:
    """Bit-level (un)packing of the RV vectors, parameterized by widths.

    A single instance is shared by a front-end driver and is independent of the
    backend that ultimately moves the bits."""

    def __init__(self, addr_width: int = 32, data_width: int = 32):
        self.addr_width = addr_width
        self.data_width = data_width
        self.sel_width = data_width // 8

        self.req_width = addr_width + data_width + 1 + self.sel_width
        self.rsp_width = data_width + 1
        self.mon_width = addr_width + data_width + self.sel_width + 1 + 1

        self.addr_mask = (1 << addr_width) - 1
        self.data_mask = (1 << data_width) - 1
        self.sel_mask = (1 << self.sel_width) - 1
        self.sel_all = self.sel_mask

    # -- REQ { adr, dat, we, sel } -------------------------------------------
    def pack_req(self, req: WbReq) -> int:
        sel = self.sel_all if req.sel is None else (req.sel & self.sel_mask)
        return (((req.adr & self.addr_mask) << (self.data_width + 1 + self.sel_width))
                | ((req.dat & self.data_mask) << (1 + self.sel_width))
                | ((1 if req.we else 0) << self.sel_width)
                | sel)

    def unpack_req(self, bits: int) -> WbReq:
        bits = int(bits)
        sel = bits & self.sel_mask
        we = (bits >> self.sel_width) & 1
        dat = (bits >> (1 + self.sel_width)) & self.data_mask
        adr = (bits >> (1 + self.sel_width + self.data_width)) & self.addr_mask
        return WbReq(adr=adr, dat=dat, we=bool(we), sel=sel)

    # -- RSP { dat, err } -----------------------------------------------------
    def pack_rsp(self, rsp: WbRsp) -> int:
        return (((rsp.dat & self.data_mask) << 1) | (1 if rsp.err else 0))

    def unpack_rsp(self, bits: int) -> WbRsp:
        bits = int(bits)
        return WbRsp(dat=(bits >> 1) & self.data_mask, err=bool(bits & 1))

    # -- MON { adr, dat, we, sel, err } --------------------------------------
    def unpack_mon(self, bits: int) -> WbMonTxn:
        bits = int(bits)
        err = bits & 1
        sel = (bits >> 1) & self.sel_mask
        we = (bits >> (1 + self.sel_width)) & 1
        dat = (bits >> (1 + self.sel_width + 1)) & self.data_mask
        adr = (bits >> (1 + self.sel_width + 1 + self.data_width)) & self.addr_mask
        return WbMonTxn(adr=adr, dat=dat, we=bool(we), sel=sel, err=bool(err))
