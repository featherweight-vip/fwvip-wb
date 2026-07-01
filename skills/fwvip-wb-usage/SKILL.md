---
name: fwvip-wb-usage
description: Connect and drive the fwvip-wb Wishbone Verification IP — bind its initiator /
  target / monitor agents into a UVM env (register macros + config DB), write
  stimulus/responder sequences, run the reg-model front door, and/or drive the cocotb
  front-end. Use when integrating fwvip-wb into a testbench or generating stimulus for it.
tools: Read, Write, Edit, Bash, Grep, Glob
---

# fwvip-wb-usage — connect & drive the `fwvip-wb` VIP

`fwvip-wb` is the UVM + Python/cocotb methodology layer for a synchronous, memory-mapped
**Wishbone** bus (request/response, width-parameterized, register model). It sits on the
`fw-proto-wb` transactor kit (cores + SV interfaces + `wb_*_xtor_bridge` classes + checker) and
the `fwvip-core` clock/reset providers — **it never re-defines those.** DFM package name:
`org.fwvip.wb`.

## Role set (what the VIP provides)

| Role | Archetype | Agent class | Config / driver | Sequence type |
|---|---|---|---|---|
| **initiator** | driving / active — the VIP *calls* `vif.request()/response()` | `fwvip_wb_initiator` | `fwvip_wb_initiator_config(_p)`, `fwvip_wb_initiator_driver` | `uvm_sequence #(fwvip_wb_transaction)` (e.g. `fwvip_wb_initiator_seq`) |
| **target** | callback responder — the kit bridge *calls back* per request | `fwvip_wb_target` | `fwvip_wb_target_config(_p)`, `fwvip_wb_target_driver` | `fwvip_wb_target_seq` (extend it) |
| **monitor** | passive analysis producer — poll-loop on the vif | `fwvip_wb_monitor_agent` (and `fwvip_wb_monitor`) | `fwvip_wb_monitor_config(_p)` | none; `uvm_analysis_port #(fwvip_wb_transaction)` |

Plus: `fwvip_wb_transaction` (the data item), `fwvip_wb_target_if` / `fwvip_wb_target_item`
(responder API + wrapper item), `fwvip_wb_reg_adapter` (reg-model front door). All ship in
`fwvip_wb_pkg` (`src/uvm/`).

### Widths
The class layer is **not** parameterized; fields are sized to `ADDR_WIDTH_MAX` /
`DATA_WIDTH_MAX` (both **64**, from `fwvip_wb_xtor_pkg`). Per-instance widths are threaded into
the vif-aware config via `*_config_p #(vif_t, ADDR_WIDTH, DATA_WIDTH)` and bridged down to the
kit's exact-width API. The transaction:

```sv
class fwvip_wb_transaction extends uvm_sequence_item;   // src/uvm/fwvip_wb_transaction.svh
    rand bit[ADDR_WIDTH_MAX-1:0]     adr;
    rand bit[DATA_WIDTH_MAX-1:0]     dat;   // write data in; read data updated in-place
    rand bit[(DATA_WIDTH_MAX/8)-1:0] sel;   // byte enables
    rand bit                         we;
    bit                              err;   // response: error termination
endclass
```

## DFM dependency to add

Your testbench fileset depends on the VIP's two SV exports (top-level `flow.yaml` already
imports `fw-proto-wb` and `fwvip-core`):

```yaml
needs:
- org.fwvip.wb.xtor-pkg          # fwvip_wb_xtor_pkg (constants) — compiled first
- org.fwvip.wb.vip-uvm-hvlsrc    # fwvip_wb_pkg (the agent classes)
```

`vip-uvm-hvlsrc` already pulls in `fw.proto.wb.xtor-sv` and `fw.proto.wb.class`. For the cocotb
front-end you instead need `fw.proto.wb.xtor-core` plus the `dv-flow-libcocotb` `cocotb.*`
tasks. The Python front-end is importable as `org.fwvip.wb` from `src/python`.

## Bench wiring (`hdl_top` / `hvl_top`)

`hdl_top` instantiates the kit wrappers on a shared bus plus the fwvip-core clock/reset
interfaces (see `tests/uvm/tb/fwvip_wb_hdl_top.sv`):

```sv
`include "wishbone_macros.svh"
localparam int ADDR_WIDTH = 32, DATA_WIDTH = 32;
`WB_WIRES(wb_, ADDR_WIDTH, DATA_WIDTH);
wb_initiator_xtor #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH)) u_initiator (.clock, .reset, `WB_CONNECT( , wb_));
wb_target_xtor    #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH)) u_target    (.clock, .reset, `WB_CONNECT( , wb_));
wb_monitor_xtor   #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH)) u_monitor   (.clock, .reset, `WB_CONNECT( , wb_));
fwvip_clock_xtor_if            u_clk_if (.clock, .reset);   // back the fwvip-core providers
fwvip_reset_xtor_if #(.ACTIVE(1)) u_rst_if (.clock, .reset);
```

`hvl_top` binds them via the register macros and registers the clock/reset providers, then runs
the test (see `tests/uvm/tb/fwvip_wb_hvl_top.sv`). The register macros (from
`fwvip_wb_macros.svh`) are:

```sv
`fwvip_wb_initiator_register(ADDR_WIDTH, DATA_WIDTH, vif, inst)   // -> wb_initiator_xtor_if #(AW,DW)
`fwvip_wb_target_register   (ADDR_WIDTH, DATA_WIDTH, vif, inst)   // -> wb_target_xtor_if    #(AW,DW)
`fwvip_wb_monitor_register  (ADDR_WIDTH, DATA_WIDTH, vif, inst)   // -> wb_monitor_xtor_if   #(AW,DW)
```

```sv
initial begin
    // NOTE: the initiator & target macros set with inst="" (global); the monitor macro honors inst.
    `fwvip_wb_initiator_register(32, 32, u_hdl.u_initiator.u_if, "uvm_test_top.m_env.m_init*");
    `fwvip_wb_target_register   (32, 32, u_hdl.u_target.u_if,    "uvm_test_top.m_env.m_targ*");
    `fwvip_wb_monitor_register  (32, 32, u_hdl.u_monitor.u_if,   "uvm_test_top.m_env.m_mon*");

    // Reset/clock come from the fwvip-core providers — never a fixed delay.
    fwvip_clock_config_p#(virtual fwvip_clock_xtor_if    )::set(null,"uvm_test_top.m_env*","clock",u_hdl.u_clk_if);
    fwvip_reset_config_p#(virtual fwvip_reset_xtor_if#(1))::set(null,"uvm_test_top.m_env*","reset",u_hdl.u_rst_if);
    run_test();
end
```

Pass the wrapper's `.u_if` as the vif — the macro wraps it in the right `virtual ...#(AW,DW)`
type and calls `*_config_p::set(...)` into the config DB. (An uppercase
`FWVIP_WB_INITIATOR_REGISTER` variant exists that uses `fwvip_wb_initiator_if` instead of the
kit `wb_initiator_xtor_if` — use the lowercase one with the kit wrapper.)

The **env** retrieves the providers and hands them to the virtual sequencer; the base virtual
sequence waits on reset before stimulus (see "Sequences" below). See `tests/uvm/env/*` for the
reusable env (`fwvip_wb_env`, vseqr, scoreboard).

## Driving the initiator

The initiator driver pulls a `fwvip_wb_transaction` and calls `m_cfg.access(t)`, which drives
the request and captures the response **in place** (read data lands in `t.dat`, error in
`t.err`):

```sv
// fwvip_wb_initiator_config_p::access()  (the seam adapter)
virtual task access(fwvip_wb_transaction t);
    bit[DATA_WIDTH_MAX-1:0] dat_t;
    vif.request(t.adr, t.dat, t.sel, t.we);
    vif.response(dat_t, t.err);
    if (!t.we) t.dat = dat_t;
endtask
```

Stimulus is any `uvm_sequence #(fwvip_wb_transaction)` on the initiator sequencer. The reusable
single-access sequence (`tests/uvm/env/fwvip_wb_init_access_seq.svh`) sets `adr/dat/sel/we`,
calls `start_item/finish_item`, then reads back `t.dat`/`t.err`. The base vseq exposes
`do_write(adr,dat,sel='1)` / `do_read(adr, dat, err, sel='1)` helpers.

## Writing a target responder

Extend `fwvip_wb_target_seq` and override `handle_request(fwvip_wb_transaction t)`. The kit's
`wb_target_xtor_bridge` polls the request FIFO and calls `config_p.access()`, which rendezvous
through `driver.service()` → sequencer → your `handle_request()`. Fill `t.dat` (reads) / set
`t.err`; the response is sent back automatically. The memory responder
(`tests/uvm/env/fwvip_wb_mem_target_seq.svh`):

```sv
class fwvip_wb_mem_target_seq extends fwvip_wb_target_seq;
    `uvm_object_utils(fwvip_wb_mem_target_seq)
    bit [DATA_WIDTH_MAX-1:0] mem [bit [ADDR_WIDTH_MAX-1:0]];
    virtual task handle_request(fwvip_wb_transaction t);
        bit [ADDR_WIDTH_MAX-1:0] wa = t.adr >> 2;   // word address
        t.err = 1'b0;
        if (t.we) mem[wa] = t.dat;
        else      t.dat   = (mem.exists(wa)) ? mem[wa] : '0;
    endtask
endclass
```

Start it forever on the target sequencer (the base vseq does this via `create_responder()`):

```sv
fwvip_wb_target_seq resp = create_responder();
fork resp.start(p_sequencer.targ_seqr); join_none
```

> Do **not** poll the bus from the responder — the responder is *called*. Only override
> `handle_request()`; `access()`/`body()` and the wrapper-item plumbing are already provided.

## Subscribing to the monitor

`fwvip_wb_monitor_agent` runs a poll loop (`m_cfg.wait_reset(); forever m_cfg.wait_txn(...)`)
and publishes a `fwvip_wb_transaction` per observed access on its `uvm_analysis_port ap`.
Connect any `uvm_analysis_imp`/subscriber:

```sv
m_mon.ap.connect(m_sb.analysis_export);   // see fwvip_wb_env::connect_phase
```

Each published item carries `adr/dat/we/sel/err` (read data is filled for reads).

## Register model front door

`fwvip_wb_reg_adapter` maps `uvm_reg_bus_op` ↔ `fwvip_wb_transaction`: `reg2bus` builds a txn
(`we = (kind==UVM_WRITE)`, `sel='1` full-byte), `bus2reg` returns `status = err ? UVM_NOT_OK :
UVM_IS_OK`, `n_bits = DATA_WIDTH_MAX`. Hook it onto the initiator sequencer's reg map (see
`tests/uvm/tests/fwvip_wb_vseq_reg.svh`):

```sv
fwvip_wb_reg_adapter adapter = fwvip_wb_reg_adapter::type_id::create("adapter");
blk.default_map.set_sequencer(p_sequencer.init_seqr, adapter);
blk.r.write(status, 'hA5A5A5A5, .parent(this));
blk.r.read (status, rdat,       .parent(this));
```

The background memory responder must be running for front-door reads to read back writes.

## Python / cocotb front-end

The backend-independent front-end (`src/python/org/fwvip/wb/`) lets the same VIP drive cocotb,
DPI, or pure-Python. Dataclasses + `WbLayout` (MSB-first packing of the RV vectors):

```python
from org.fwvip.wb import WbInitiator, WbTarget, WbMonitor        # transaction.py: WbReq/WbRsp/WbMonTxn/WbLayout
# WbReq(adr, dat=0, we=False, sel=None)   WbRsp(dat=0, err=False)
# WbMonTxn(adr, dat, we, sel, err)        WbLayout(addr_width=32, data_width=32)
from org.fwvip.wb.cocotb import (CocotbInitiatorBackend, CocotbTargetBackend, CocotbMonitorBackend)

initiator = WbInitiator(CocotbInitiatorBackend(dut, "init_"))    # default widths 32/32
target    = WbTarget(CocotbTargetBackend(dut, "tgt_"))
monitor   = WbMonitor(CocotbMonitorBackend(dut, "mon_"))
```

Front-end method signatures:
- `WbInitiator`: `await request(WbReq) -> WbRsp`, `await write(adr, dat, sel=None) -> WbRsp`,
  `await read(adr, sel=None) -> WbRsp`, `await reset_done()`.
- `WbTarget`: `await next_request() -> WbReq`, `await respond(WbRsp)`,
  `await serve_memory(mem=None, err=None)` (forever; word index = `adr >> 2`).
- `WbMonitor`: `await next() -> WbMonTxn`, async-iterable (`async for txn in monitor:`).

The cocotb backend (`cocotb/backend.py`) binds to the cocotb **top handle** with a per-role
signal prefix and drives **top-level** RV signals (`init_req_*/init_rsp_*`, `tgt_req_*/tgt_rsp_*`,
`mon_*`) — not core sub-instance ports — so the same backend runs on both Verilator and Icarus.
The handshake uses the canonical event-driven `_rv_get` / `_rv_put` primitives (idle: sleep on
the signal edge; sample/check at the clock edge). The monitor backend runs a background sampler
and `pop()` drains via an `Event` (no polling). See `fwvip-core/docs/cocotb-performance.md`.

## Pitfalls

- **Don't rebuild the kit.** Cores, SV interfaces, wrappers, `wb_*_xtor_bridge`, `wb_proto_if`,
  and `wb_proto_checker` belong to `fw-proto-wb`. The VIP only consumes them.
- **The seam adapter is the config** — `*_config_p` holds the vif, owns the kit bridge, and
  forwards the kit API. Bind it only through the `register` macros; access through the config.
- **Reset comes from the fwvip-core providers**, never a fixed delay. Wait on
  `reset_provider.wait_reset()` (the base vseq already does) before stimulus.
- **Target is a responder, not a poller** — override `handle_request()`; never read the bus
  from the sequence. The monitor *is* the passive observer (analysis port).
- **No `typedef virtual <if> #(…)` in procedural code** (Verilator crash). Use the macros; in
  any interface code you touch use `always @(posedge clock)`, never `always_ff`.
- **cocotb drives top-level signals only.** Verilator recomputes sub-instance input ports each
  eval, so cocotb writes to them are ignored; keep the cocotb-driven inputs top-level
  regs/logic and let the backend's event-driven `_rv_*` primitives do the handshake.
- The class layer is sized to `*_WIDTH_MAX` (64); per-instance widths must be threaded through
  `*_config_p #(vif_t, AW, DW)` and the `register` macro args, matching the wrapper params.

## Runnable example

The worked example lives in `tests/` (`tests/uvm/{tb,env,tests}/`, `tests/cocotb/`). DFM
targets:

```sh
# UVM smoke: block of writes + self-checked read-back (SEQ=fwvip_wb_vseq_smoke)
dfm run org.fwvip.wb.uvm-test-smoke
# other UVM scenarios: uvm-test-write / -read / -rand / -sel / -err / -reg (reg-model front door)
dfm run org.fwvip.wb.uvm-test-reg

# cocotb front-end check (Verilator); Icarus variant: org.fwvip.wb.cocotb-ivl-check
dfm run org.fwvip.wb.cocotb-check
```

All UVM scenarios share one image + `UVM_TESTNAME=fwvip_wb_test_base`, selected by
`+SEQ=<vseq>`; extra knobs (`+NUM_TXNS`, `+BASE_ADDR`) append as plusargs.
