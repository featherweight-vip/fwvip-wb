# Verification

The VIP *is* the thing under test — other projects rely on it to drive and observe Wishbone
traffic, so its correctness against WISHBONE B.3 is the deliverable. This page summarizes the
feature scope, the verification levels, and what runs in CI. The full test plan lives in
`doc/wb_vip_test_plan.md`.

## Feature scope

The transactor cores implement **single-beat WISHBONE Classic** with a **single outstanding
transaction**. Verification effort is spent on what is implemented:

| In scope | Out of scope (documented gaps / roadmap) |
| --- | --- |
| Reset/init (CYC,STB negated on reset) | RTY termination |
| SINGLE READ / SINGLE WRITE cycles | BLOCK READ/WRITE, RMW |
| Handshake (CYC envelopes STB; held until ACK/ERR) | Registered-feedback bursts (CTI/BTE) |
| Slave wait states (delayed ACK) | TAG signals (TGA/TGD/TGC) |
| ERR termination (ACK/ERR mutually exclusive) | Master wait states (STB held continuously) |
| SEL byte-enables (transport only) | Endianness / byte-lane steering (handled above the transactor) |

The reduced classic signal set per core is `clock, reset, adr, dat_w, dat_r, cyc, stb, ack,
err, sel, we` — no `rty`, no `cti`/`bte`, no tags, split `dat_w`/`dat_r`.

## Verification levels

| Level | Target | Method |
| --- | --- | --- |
| **L0 — formal** | kit `*_xtor_core` | SymbiYosys BMC against the kit's `wb_proto_checker` |
| **L1 — core sim** | kit cores | directed SV TBs (`tests/uvm/tb/fwvip_wb_transactor_core_b2b.sv`, `…_monitor_core_tb.sv`) |
| **L4 — UVM VIP** | agents, drivers, sequences, monitor, reg adapter | UVM tests + reusable scoreboard |

```{admonition} Formal lives in the kit
:class: note
The protocol checker and formal proofs belong to `fw-proto-wb`. The VIP's formal testbenches
instantiate the kit's `wb_proto_checker` (RULE 3.20/3.25/3.35/3.45/3.60 + single-outstanding +
bounded-liveness + SVA X-checks) — the VIP does not vendor its own checker.
```

## The UVM test suite

All L4 tests are built on a single base test (`fwvip_wb_test_base`) driving a plusarg-selected
virtual sequence — adding a scenario is a new vseq plus a one-line DFM task, no new test class.
The reusable env (`tests/uvm/env/`) provides the virtual sequencer, an analysis-port scoreboard
that self-checks read-back, the memory responder, and the sequence library.

| DFM task | Sequence | Covers |
| --- | --- | --- |
| `uvm-test-smoke` | `fwvip_wb_vseq_smoke` | writes + self-checked read-back, monitor |
| `uvm-test-write` | `fwvip_wb_vseq_write` | write traffic |
| `uvm-test-read` | `fwvip_wb_vseq_read` | read-back checking |
| `uvm-test-rand` | `fwvip_wb_vseq_rand` | randomized mixed traffic |
| `uvm-test-sel` | `fwvip_wb_vseq_sel` | partial byte-select transport |
| `uvm-test-err` | `fwvip_wb_vseq_err` | ERR termination |
| `uvm-test-reg` | `fwvip_wb_vseq_reg` | `uvm_reg` front door |

All seven run `UVM_TESTNAME=fwvip_wb_test_base` with `+SEQ=<vseq>`; knobs such as `+NUM_TXNS`
and `+BASE_ADDR` append as plusargs. Run any with `dfm run org.fwvip.wb.<task>` (see
{doc}`getting-started`).

## cocotb

The Python front-end is checked end-to-end on both simulators (`org.fwvip.wb.cocotb-check` on
Verilator, `org.fwvip.wb.cocotb-ivl-check` on Icarus): writes and reads issued through the
front-end are verified through the monitor stream. See {doc}`cocotb`.

## Continuous integration

`.github/workflows/ci.yml` runs on every push/PR to `main`:

1. **`fvutils/ivpm-setup`** fetches the `default` + `default-dev` dependency sets (the kit, the
   dv-flow libraries, UVM, Verilator, the dfm Python venv).
2. **`dv-flow/run-dvflow`** runs the DFM sim tasks — `core-b2b-sim-run`, `mon-sim-run`, and the
   seven `uvm-test-*` entrypoints — failing the job on any failed task and publishing a report
   bundle.

A separate `Docs` workflow builds and publishes this site (see the repository's
`.github/workflows/docs.yml`). Formal proofs are not yet wired into CI.
