# Architecture

The VIP is a small set of UVM components and one packing-aware Python front-end. This page
covers the SystemVerilog side: the package layout, the seam between VIP and kit, and how widths
are handled.

## Package layout

| File / package | Role |
| --- | --- |
| `fwvip_wb_xtor_pkg` (`src/uvm/fwvip_wb_xtor_pkg.sv`) | Consumer-side constants: `ADDR_WIDTH_MAX` / `DATA_WIDTH_MAX` (both 64). Compiled first. |
| `fwvip_wb_pkg` (`src/uvm/fwvip_wb_pkg.sv`) | The VIP proper: transaction, three agents, configs/drivers, target responder plumbing, register adapter. |
| `fwvip_wb_macros.svh` | The `register` macros that bind a kit vif into the config DB. |

`fwvip_wb_pkg` imports `uvm_pkg`, `fwvip_wb_xtor_pkg` (constants), and the kit's class layer
(`wb_proto_pkg` — interface-classes + `wb_*_xtor_bridge`). The `.svh` class files are pulled in
through the include directory; only `fwvip_wb_pkg.sv` is named in the DFM fileset so the
constants package is not double-compiled.

## The seam adapter is the config

Every role follows one pattern: an **abstract config** that components depend on, plus a
**vif-aware specialization** `*_config_p` that holds the kit `virtual` interface, constructs the
matching `wb_*_xtor_bridge`, forwards the kit's method API, and has a static `set()` into the
config DB. This `*_config_p` is the single seam between the VIP and the kit.

```systemverilog
// fwvip_wb_initiator_config_p::access()  — the seam adapter forwarding to the kit vif
virtual task access(fwvip_wb_transaction t);
    bit[DATA_WIDTH_MAX-1:0] dat_t;
    vif.request(t.adr, t.dat, t.sel, t.we);
    vif.response(dat_t, t.err);
    if (!t.we) t.dat = dat_t;   // read data captured in place
endtask
```

A generic active agent wires the rest: it fetches its config from the DB in `build_phase`,
creates a `uvm_sequencer #(fwvip_wb_transaction)` and a driver, and connects them in
`connect_phase`. Components only ever see the **abstract** config type, so they stay
vif-agnostic; the widths and the kit bridge live entirely inside `*_config_p`.

## Widths

The class layer is **not** parameterized. Transaction fields are sized to the maxima from
`fwvip_wb_xtor_pkg`:

```systemverilog
class fwvip_wb_transaction extends uvm_sequence_item;   // src/uvm/fwvip_wb_transaction.svh
    rand bit[ADDR_WIDTH_MAX-1:0]     adr;
    rand bit[DATA_WIDTH_MAX-1:0]     dat;   // write data in; read data updated in place
    rand bit[(DATA_WIDTH_MAX/8)-1:0] sel;   // byte enables
    rand bit                         we;
    bit                              err;   // response: error termination
endclass
```

Per-instance widths are threaded into the **vif-aware** config and bridged down to the kit's
exact-width API:

```systemverilog
class fwvip_wb_initiator_config_p #(type vif_t=int, int ADDR_WIDTH=32, int DATA_WIDTH=32)
    extends fwvip_wb_initiator_config;
```

The `register` macros (see {doc}`integration`) thread the same `ADDR_WIDTH` / `DATA_WIDTH` and
must match the kit wrapper's parameters.

## The three role shapes

- **Initiator — active.** Driver pulls a transaction and calls `m_cfg.access(t)`; no background
  thread. (Pattern detail in {doc}`sequences`.)
- **Target — callback responder.** The kit's `wb_target_xtor_bridge` polls the request FIFO and
  calls back through the config → `driver.service()` → sequencer → your `handle_request()`. The
  wrapper-item plumbing (`fwvip_wb_target_if` / `fwvip_wb_target_item`) exists because UVM
  forbids handing a sequence to `start_item`.
- **Monitor — passive analysis producer.** `fwvip_wb_monitor_agent` runs
  `m_cfg.wait_reset(); forever m_cfg.wait_txn(...)` and publishes one `fwvip_wb_transaction` per
  observed access on a `uvm_analysis_port`.

## Relationship to the kit and core

```
        fwvip-wb (this package)
        ├── fwvip_wb_pkg ............ agents, configs, drivers, reg adapter
        │       │  consumes
        │       ▼
        ├── fw-proto-wb ............. cores, *_xtor_if, wb_*_xtor_bridge, wb_proto_checker
        └── fwvip-core ............. fwvip_clock/reset_xtor_if + UVM config providers
```

The VIP never re-defines anything in the lower two boxes — it imports the kit's class layer and
binds the kit's `virtual` interfaces, and it pulls clock/reset from the `fwvip-core` providers.
