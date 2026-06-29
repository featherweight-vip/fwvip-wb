# fwvip-wb — Wishbone Verification IP (UVM)

This VIP provides the **verification infrastructure** for Wishbone: the UVM agent
layer (drivers, monitors, sequences, configs, register adapter), assertions, the
Python/cocotb backend, and the PSS model.

## Where the core transactor lives

The **core signal-level transactor** (the methodology-independent
interface/core/integration modules that bridge a blocking task API to the
Wishbone wire protocol) is **no longer part of this repo**. It was migrated to the
standalone **`fw-proto-wb`** protocol package (`packages/fw-proto-wb`, module
prefix `wb_*`). This VIP consumes it as a dependency:

- Build wiring: the top `flow.yaml` imports `fw-proto-wb`; the UVM source
  (`src/vip/vip.yaml : vip-uvm-hvlsrc`) `needs` the transactor-only exports
  `wb.proto.xtor-core` / `wb.proto.xtor-sv`.
- The UVM layer binds to the transactor via `virtual wb_{initiator,target,monitor}_xtor_if #(ADDR_WIDTH, DATA_WIDTH)`
  and the individual-argument task API (`request`/`response`, `wait_req`/`send_rsp`,
  `wait_txn`, `wait_reset`).
- Consumer-side width constants (`ADDR_WIDTH_MAX` / `DATA_WIDTH_MAX`) stay here in
  `src/vip/pkg/fwvip_wb_xtor_pkg.sv` (they size the class-based, non-parameterized
  UVM transaction/config fields — not a transactor concern).

The full migration record is in [`doc/wb-core-transactor-migration-plan.md`](../../doc/wb-core-transactor-migration-plan.md).

## What a VIP consists of

- One or more BFMs / transactors (here: consumed from `fw-proto-wb`)
- A UVM agent layer over them (`src/vip/uvm/`)
- Protocol assertions (`src/vip/assertions/`)
- Optional alternate backends (`src/vip/org/...` — Python/cocotb)
