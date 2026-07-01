# Python / cocotb front-end

`fwvip-wb` ships a backend-independent Python front-end so the same VIP can drive cocotb, DPI,
or pure Python. It lives in `src/python/org/fwvip/wb/` and is importable as `org.fwvip.wb`
(the `.envrc` puts `src/python` on `PYTHONPATH`).

## Layers

```
org.fwvip.wb
├── transaction.py ... WbReq / WbRsp / WbMonTxn dataclasses + WbLayout (bit packing)
├── backend.py ....... abstract InitiatorBackend / TargetBackend / MonitorBackend
├── initiator.py ..... WbInitiator   (friendly front-end over a backend)
├── target.py ........ WbTarget
├── monitor.py ....... WbMonitor
└── cocotb/backend.py  CocotbInitiatorBackend / CocotbTargetBackend / CocotbMonitorBackend
```

`WbLayout` does the MSB-first packing/unpacking of the ready/valid vectors, matching the kit's
packed structs. The front-end classes only move transactions; the backend only moves raw bit
vectors and exposes reset — so swapping cocotb for another backend changes nothing above it.

## Constructing the front-end (cocotb)

Each cocotb backend binds to the cocotb **top handle** with a per-role signal prefix:

```python
from org.fwvip.wb import WbInitiator, WbTarget, WbMonitor
from org.fwvip.wb import WbReq, WbRsp, WbMonTxn, WbLayout
from org.fwvip.wb.cocotb import (
    CocotbInitiatorBackend, CocotbTargetBackend, CocotbMonitorBackend,
)

initiator = WbInitiator(CocotbInitiatorBackend(dut, "init_"))   # default widths 32/32
target    = WbTarget(CocotbTargetBackend(dut, "tgt_"))
monitor   = WbMonitor(CocotbMonitorBackend(dut, "mon_"))
```

## Driving traffic

```python
# Initiator: request/response, with write/read shortcuts
rsp = await initiator.write(0x1000, 0xA5A5_A5A5)     # -> WbRsp(dat, err)
rsp = await initiator.read(0x1000)                   # rsp.dat holds the data
rsp = await initiator.request(WbReq(adr=0x4, dat=0, we=False, sel=None))
await initiator.reset_done()

# Target: respond manually, or serve a memory model forever
req = await target.next_request()                    # -> WbReq
await target.respond(WbRsp(dat=0xDEAD, err=False))
await target.serve_memory()                          # word index = adr >> 2

# Monitor: pull observed transactions, or async-iterate
txn = await monitor.next()                            # -> WbMonTxn(adr, dat, we, sel, err)
async for txn in monitor:
    ...
```

## How the backend drives the bus

The cocotb backend drives **top-level** ready/valid signals (`init_req_*` / `init_rsp_*`,
`tgt_req_*` / `tgt_rsp_*`, `mon_*`) — never core sub-instance ports — so the same backend runs
on both Verilator and Icarus. The handshake uses the canonical event-driven primitives from the
`fwvip-core` performance pattern: stay idle by sleeping on a signal edge, then sample/check at
the clock edge (`_rv_get` / `_rv_put`). The monitor fires autonomously, so its backend runs a
background sampler and `pop()` drains it via an `Event` — no per-cycle polling.

```{admonition} cocotb drives top-level signals only
:class: warning
Verilator recomputes sub-instance input ports each `eval`, so cocotb writes to them are ignored.
Keep cocotb-driven inputs as top-level reg/logic and let the event-driven `_rv_*` primitives do
the handshake. See `fwvip-core`'s *cocotb-performance* note for the full rationale.
```

## Running it

```console
$ dfm run org.fwvip.wb.cocotb-check        # Verilator
$ dfm run org.fwvip.wb.cocotb-ivl-check    # Icarus
```

The test (`tests/cocotb/test_fwvip_wb.py`) issues writes and reads through the front-end and
checks them through the monitor stream — the same backend-independent API shown above.
