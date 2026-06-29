# Featherweight Wishbone VIP — Verification Test Plan

**Status:** Draft for review
**Date:** 2026-06-23
**Reference spec:** WISHBONE SoC Interconnection Architecture, Revision B.3 (`doc/wbspec_b3.md`)
**DUT-under-test:** `fwvip-wb` transactors (`src/vip/sv`) and UVM VIP (`src/vip/uvm`)

---

## 1. Purpose & Scope

This plan defines the tests needed to verify the *Featherweight Wishbone Verification IP* — i.e. we are
verifying the VIP itself (transactors + UVM layer), not an external Wishbone DUT. The VIP is what other
projects will rely on to drive/observe Wishbone traffic, so its correctness against WB B.3 is the
deliverable.

The VIP comprises three signal-level transactor cores, SV interface wrappers that add FIFOs and a
blocking task API, and a UVM agent layer (initiator, target, monitor) plus a register adapter.

### 1.1 Implementation reality vs. WB B.3 — feature scope

The transactor cores implement a **single-beat WISHBONE *Classic* protocol** with a **single outstanding
transaction**. This drives what is *in scope* to verify. The following table maps WB B.3 features to VIP
support so test effort is spent only on implemented behavior (and gaps are recorded explicitly).

| WB B.3 feature | Spec ref | VIP support | Test scope |
|---|---|---|---|
| Reset / initialization (CYC,STB negated on reset) | RULE 3.00, 3.05, 3.20 | Yes (all cores reset CYC/STB low) | **In scope** |
| SINGLE READ cycle | §3.2.1 | Yes | **In scope** |
| SINGLE WRITE cycle | §3.2.2 | Yes | **In scope** |
| Handshake: CYC+STB held until ACK/ERR | RULE 3.25, 3.35 | Yes | **In scope** |
| SLAVE wait states (delayed ACK) | §3.1.3 | Yes (initiator waits on `term`; target via rsp latency) | **In scope** |
| MASTER wait states (delayed STB within a cycle) | §3.1.3 | **No** — STB asserted continuously per access | Negative / not-supported |
| ERR termination | PERMISSION 3.20 | Yes (`err` path, ACK=~ERR) | **In scope** |
| RTY termination | PERMISSION 3.25 | **No** — no RTY signal | Gap (document) |
| SEL byte-enable pass-through | §3.5 | Partial — carried, not decoded/checked | **In scope (transport only)** |
| Endianness / byte-lane data organization | §3.5.3–3.5.6 | **No** — no lane steering | Gap (document) |
| BLOCK READ/WRITE cycle | §3.3 | **No** — single outstanding only | Gap (document) |
| RMW cycle | §3.4 | **No** | Gap (document) |
| Registered Feedback (CTI/BTE bursts) | Chapter 4 | **No** — no CTI/BTE ports | Gap (document) |
| TAG signals (TGA/TGD/TGC) | §3.1.5 | **No** | Gap (document) |

> **Decision (resolved):** BLOCK / RMW / Registered-Feedback / RTY *will* be added later — the "Gap" rows
> are **planned future test phases** (see §9), not permanent waivers. Until then the VIP datasheet should
> declare the supported cycle set explicitly so users do not expect them. Endianness/byte-lane organization
> (§3.5) is *not* on the roadmap: it is handled above the transactor, where `SEL` is transport-only metadata.

### 1.2 VIP signal set (per core)

The cores use a reduced classic signal set: `clock, reset, adr, dat_w, dat_r, cyc, stb, ack, err, sel, we`.
Note there is **no separate `rty`**, no `cti`/`bte`, no tags, and `dat_w`/`dat_r` are split (not a shared bus).

---

## 2. Verification Architecture / Levels

| Level | Target | Method | Existing assets |
|---|---|---|---|
| L0 — Core unit (formal) | `*_xtor_core` modules | Formal (assume/assert/cover) + protocol checker | `tests/formal/*_formal_tb.sv`, `fwvip_wb_checkers` |
| L1 — Core unit (sim) | `*_xtor_core` modules | Directed SV TB driving RV + WB sides | `tb/fwvip_wb_transactor_core_b2b.sv`, `tb/fwvip_wb_monitor_core_tb.sv` |
| L2 — Interface/FIFO | `*_xtor_if` (FIFO + task API) | Directed SV TB exercising put/get/request/response | *new* |
| L3 — Integrated transactor | `*_xtor` (if+core) | Back-to-back initiator↔target through task API | partial (`hdl_top`/`hvl_top`) |
| L4 — UVM VIP | agents, driver, seq, monitor, reg adapter | UVM tests w/ scoreboard | `tests/uvm/tests/*`, `tests/uvm/env/*` (implemented — see §2.1) |

Each test below is tagged with the level(s) at which it should run.

---

## 2.1 Implemented UVM Test Architecture (L4) — IMPLEMENTED

All L4 simulation tests are UVM tests built on a **single base test driving a plusarg-selected virtual
sequence**. Adding a test = adding a virtual sequence + a one-line DFM task; no new test class.

**Components (reusable, in `tests/uvm/env/`, package `fwvip_wb_env_pkg`):**
- `fwvip_wb_vseqr` — virtual sequencer; holds handles to the initiator and target sub-sequencers and the
  initiator config (for reset sync). Instantiated in `fwvip_wb_env` and wired in its `connect_phase`.
- `fwvip_wb_scoreboard` — reusable subscriber on the monitor analysis port (Decision 4). Builds a reference
  memory from observed writes and self-checks observed read data; reports `mismatch`/`uninit`/`err` counts.
- `fwvip_wb_mem_target_seq` — reusable target memory responder with an optional ERR address policy
  (`err_mask`/`err_match`).
- `fwvip_wb_init_access_seq` — single read/write access on the initiator (read data returned in-place).
- `fwvip_wb_vseq_base` — base virtual sequence: reads plusargs (`+NUM_TXNS`, `+BASE_ADDR`), waits for reset,
  forks the responder, exposes `do_write()`/`do_read()`; scenarios override `stimulus()`.
- `fwvip_wb_vseq_lib` — generic scenarios: `write`, `read`, `smoke`, `rand`, `sel`, `err`.

**Test + scenario selection (in `tests/uvm/tests/`, package `fwvip_wb_tests_pkg`):**
- `fwvip_wb_test_base` — the *only* UVM test class. Builds the env + `fwvip_wb_mon_sub`, reads `+SEQ=<vseq
  type name>` (default `fwvip_wb_vseq_smoke`), creates that virtual sequence via the factory, and runs it on
  `m_env.m_vseqr`. `report_phase` flags zero monitor traffic.
- `fwvip_wb_vseq_reg` — register-model virtual sequence (carries the `uvm_reg` block) for `+SEQ=…_reg`.

**DFM entrypoints (one root task per test, in `tests/uvm/tests/tests.yaml`):** each runs `uvm-sim-img` with
`+UVM_TESTNAME=fwvip_wb_test_base +SEQ=<vseq>`. Run with `dfm run org.fwvip.wb.<task>`.

| DFM task | `+SEQ=` | Plan coverage | Status |
|---|---|---|---|
| `uvm-test-smoke` | `fwvip_wb_vseq_smoke` | SWR-01/04, SRD-01/03, MON-01 | ✅ pass (16w/16r, 0 mismatch) |
| `uvm-test-write` | `fwvip_wb_vseq_write` | SWR-01/04 | ✅ pass |
| `uvm-test-read`  | `fwvip_wb_vseq_read`  | SRD-01/02/03 | ✅ pass (readback checked) |
| `uvm-test-rand`  | `fwvip_wb_vseq_rand`  | UVM-06 | ✅ pass |
| `uvm-test-sel`   | `fwvip_wb_vseq_sel`   | SWR-03 | ✅ pass |
| `uvm-test-err`   | `fwvip_wb_vseq_err`   | ERR-01, ERR-04 | ✅ pass (8 ERR observed) |
| `uvm-test-reg`   | `fwvip_wb_vseq_reg`   | REG-01 | ✅ pass (0xA5A5A5A5 ✓) |

> All seven verified on Verilator 5.049 (`sim=vlt`), 0 UVM_ERROR / 0 UVM_FATAL. The `UVM/COMP/NAME` warnings
> are a benign UVM-without-DPI artifact (UVM's own internal port names) and are unrelated to the VIP.
> **Knobs:** append e.g. `+NUM_TXNS=64`, `+BASE_ADDR=1000` as plusargs to any task.

> **Scope note:** L0 (formal) and L1/L2 (core/FIFO SV unit TBs) are *not* UVM tests — they exercise pure
> modules / the FIFO task API below the UVM layer and remain directed SV / formal benches.

---

## 3. Test Cases

Test IDs are grouped by feature area. Each lists: **Objective / Stimulus / Checks / Level**.

### 3.1 Reset & Initialization (RST)

**RST-01 — Reset negates control outputs (initiator & target).** *(L0/L1)*
Stimulus: assert `reset` ≥1 cycle, then several cycles. Checks: during reset and on the cycle after,
`cyc==0 && stb==0` on initiator; `ack==0 && err==0` on target; `req_valid==0`, `rsp_valid==0`,
`mon_valid==0`. (RULE 3.20)

**RST-02 — Reset during an active transaction.** *(L0/L1)*
Stimulus: start a request, assert `reset` mid-cycle (BUS / WAIT_RSP state). Checks: outputs go to the
reset/idle state within one clock, FSM returns to IDLE, no spurious ACK/response after dropout. (RULE 3.10)

**RST-03 — FIFO pointers/counters clear on reset.** *(L2)*
Stimulus: enqueue partial entries, assert reset. Checks: `req_cnt/rsp_cnt/mon_cnt == 0`, wr/rd pointers 0,
`*_gnt` low; no stale data is returned by the next `get`.

**RST-04 — `wait_reset()` task semantics.** *(L2/L4)*
Stimulus: call `wait_reset()` while reset asserted and while already de-asserted. Checks: returns on the
first `posedge clock` after `negedge reset`; returns promptly (one clock) if reset already low.

### 3.2 SINGLE WRITE Cycle (SWR)

**SWR-01 — Basic single write.** *(L1/L3/L4)*
Stimulus: one write request (adr/dat/sel=all/we=1). Checks (bus side): one cycle where `cyc&stb` high,
`we==1`, `adr`/`dat_w`/`sel` match request and are stable while STB held; cycle ends the clock after ACK;
`cyc`&`stb` de-assert together. Response `err==0` returned to initiator. (§3.2.2, RULE 3.25/3.60)

**SWR-02 — Write data/addr stability under wait states.** *(L1)*
Stimulus: target delays ACK by N cycles (model rsp latency). Checks: `adr/dat_w/sel/we/cyc/stb` remain
stable and unchanged every cycle until `term` (ACK). (RULE 3.60, signals qualified by STB)

**SWR-03 — Partial SEL on write.** *(L1/L3)*
Stimulus: writes with `sel` = `4'h1`, `4'h3`, `4'hC`, `4'hF`. Checks: `sel` is transported unchanged on the
bus and delivered to the target task `wait_req` / monitor unchanged. (Transport-only; no lane decode.)

**SWR-04 — Back-to-back writes.** *(L1/L3/L4)*
Stimulus: stream of writes to incrementing addresses (existing b2b TB does 3). Checks: each completes
before the next starts (single-outstanding); request order preserved; FIFO does not drop/duplicate.

### 3.3 SINGLE READ Cycle (SRD)

**SRD-01 — Basic single read.** *(L1/L3/L4)*
Stimulus: write a known value, then read same address (use memory responder). Checks: bus `we==0` during
read; initiator captures `dat_r` presented at ACK; returned `dat` equals written value. (§3.2.1)

**SRD-02 — Read data capture timing.** *(L0/L1)*
Stimulus: target presents `dat_r` only on the ACK cycle, garbage otherwise. Checks: initiator latches the
value coincident with `term`, not earlier/later (`dat_r_q <= dat_r` on the ACK cycle). 

**SRD-03 — Interleaved write/read sequence.** *(L1/L3/L4)*
Stimulus: existing b2b pattern (3 writes then 3 reads) + randomized variant. Checks: read-back data matches
prior writes per address; response count == request count.

### 3.4 Error Termination (ERR)

**ERR-01 — Target ERR response.** *(L1/L3/L4)*
Stimulus: target responds with `err=1` (via `send_rsp(.,1)`). Checks: bus shows `err==1 && ack==0` for one
cycle (mutual exclusion, RULE 3.45); initiator `response()` returns `err==1`; FSM returns to IDLE.

**ERR-02 — ACK/ERR mutual exclusion.** *(L0)*
Formal assert: target never drives `ack && err` simultaneously. (RULE 3.45)

**ERR-03 — ERR maps to UVM status.** *(L4)*
Stimulus: reg/read access that errors. Checks: `fwvip_wb_reg_adapter.bus2reg` sets `status==UVM_NOT_OK`
when `t.err`; `UVM_IS_OK` otherwise.

**ERR-04 — Initiator termination on ERR without ACK.** *(L0/L1)*
Note implementation: initiator `term = ack || err` (does **not** gate on cyc/stb). Verify ERR alone
terminates the bus cycle and produces a response. *(Also see RISK-1 below.)*

### 3.5 Handshake / Protocol Compliance (HSK)

**HSK-01 — CYC envelope around STB.** *(L0)*
Formal assert: `stb |-> cyc` (CYC asserted no later than STB, negated no earlier). (RULE 3.25)

**HSK-02 — Single outstanding / no new STB until prior terminates.** *(L0/L1)*
Assert: initiator does not start a second cycle until the first response is consumed; target does not accept
a new bus access until its response handshake completes.

**HSK-03 — No ACK/response without a request.** *(L0/L1)*
Assert: target produces `req_valid`/ACK only in response to `cyc&stb`; monitor emits a txn only on
`(ack||err)&&cyc&&stb` (`term`). No emission on idle bus.

**HSK-04 — Master early-abort handling (target).** *(L1)*
Stimulus: drive `cyc&stb`, then drop `cyc` before the response is ready (target `active_cycle` deasserts in
REQ/WAIT_RSP). Checks: target FSM returns to IDLE, drops `req_valid`, does not later drive a stale ACK.

**HSK-05 — Bus-side max cycle length.** *(L0)*
Cover/assert (mirrors `fwvip_wb_checkers` `MAX_CYCLE_LEN`): a cycle terminates within the bounded number
of cycles given a responsive slave; flag livelock.

### 3.6 RV FIFO & Task API (FIFO)

The `*_xtor_if` modules contain hand-written depth-4 circular FIFOs with a `req/gnt` (one-cycle-latency)
put/get handshake. These are the highest-risk hand-coded logic and need dedicated tests.

**FIFO-01 — put/get round-trip integrity.** *(L2)*
Stimulus: `put()` a sequence of known vectors, `get()` them back. Checks: FIFO order preserved (FIFO not
LIFO), values bit-exact, no loss/duplication.

**FIFO-02 — Fill to DEPTH and back-pressure.** *(L2)*
Stimulus: push until full (`cnt==DEPTH`). Checks: producer side de-asserts ready (`req_ready`/`rsp_ready`
low at full), `put()` blocks until space frees; no overflow/pointer corruption. Likewise underflow: `get()`
blocks on empty, no `gnt` when `cnt==0`.

**FIFO-03 — Wrap-around.** *(L2)*
Stimulus: push/pop across the DEPTH-1→0 pointer wrap repeatedly. Checks: data integrity through ≥2 full
wraps. (Pointer-width param `REQ_PTR_W = $clog2(DEPTH)`.)

**FIFO-04 — Simultaneous push & pop.** *(L2)*
Stimulus: drive producer and consumer concurrently at steady state. Checks: `{do_push,do_pop}` count logic
keeps `cnt` correct; no off-by-one. (Targets the `case({do_push,do_pop})` arm.)

**FIFO-05 — put/get grant latency.** *(L2)*
Checks: `put()` returns only after `*_put_gnt`; the documented one-cycle `gnt` pulse occurs exactly once per
operation (no double-grant, no missed grant). Same for `get()`/`*_get_gnt`.

**FIFO-06 — DEPTH=1 corner.** *(L2)*
Stimulus: parameterize `DEPTH=1` (param guards `REQ_PTR_W = (DEPTH<=1)?1:...`). Checks: degenerate FIFO
still does put/get correctly.

**FIFO-07 — request()/response() & wait_req()/send_rsp() field mapping.** *(L2)*
Checks: struct pack/unpack is lossless — `request(adr,dat,sel,we)` → core `req_u` fields → target
`wait_req` returns identical adr/dat/sel/we. Note initiator REQ field is named `stb` (byte-enables) while
target REQ field is named `sel`; verify they line up bit-for-bit through the bus. *(See RISK-2.)*

### 3.7 Monitor (MON)

**MON-01 — One transaction per completed access.** *(L1/L4)*
Stimulus: drive N writes/reads on the observed bus. Checks: exactly N monitor transactions emitted; none on
idle/aborted cycles. (Existing `monitor_core_tb` drives 3.)

**MON-02 — Correct data-direction capture.** *(L1)*
Checks: monitor records `dat = we ? dat_w : dat_r` — write captures write data, read captures read data;
`adr/sel/we/err` fields correct.

**MON-03 — Monitor back-pressure / single-entry buffer.** *(L1/L2)*
Stimulus: hold `mon_ready` low across a bus termination, then a second termination before consume. Checks:
single-entry core buffer holds the first txn; behavior when a second `term` arrives while buffer full is
characterized (drop vs. hold). *(See RISK-3 — possible dropped transaction.)*

**MON-04 — Monitor passivity.** *(L0/L1)*
Assert: monitor never drives any WB signal (inputs only); cannot perturb the bus.

**MON-05 — UVM monitor → analysis port.** *(L4)*
Checks: every `wait_txn` produces one `ap.write`; `fwvip_wb_mon_sub` subscriber count equals driven
transaction count (the base test's `report_phase` checks `txn_count != 0` — strengthen to exact match per
scenario). The reusable `fwvip_wb_scoreboard` (§2.1) consumes the same stream for data checking.

### 3.8 UVM Agent Layer (UVM)

**UVM-01 — Initiator agent build/connect & config delivery.** *(L4)*
Checks: `uvm_config_db` get of `cfg` succeeds (currently only `$display` on failure — should be
`uvm_fatal`); sequencer↔driver connected; one `seq` item drives one `access()`.

**UVM-02 — Driver get_next_item/item_done handshake.** *(L4)*
Checks: initiator driver loops 1:1 request→response; target driver primes-then-responds without a 0-time
loop, using **clock-edge synchronization instead of the current `#10ns` guard** (per REQ-NODELAY / Decision
3). No item_done without a matching get_next_item.

**UVM-03 — Config polymorphism / parameterization.** *(L4)*
Stimulus: register vif via `fwvip_wb_*_register` macros with ADDR/DATA widths. Checks: `getADDR_WIDTH()/
getDATA_WIDTH()` return configured values; access task uses the parameterized vif.

**UVM-04 — Target memory responder sequence.** *(L4)*
Stimulus: `fwvip_wb_mem_target_seq` over a write/read stream. Checks: read returns last written value per
word address (`adr>>2`); default read of unwritten address returns 0, `err=0`.

**UVM-05 — End-of-test / `final_phase` shutdown.** *(L4)*
Checks: target driver `m_active=0` in `final_phase` cleanly unblocks the forever loop; no hang at end of
test (objection drop completes). Confirm shutdown does not depend on any absolute delay (REQ-NODELAY).

**UVM-06 — Transaction randomization.** *(L4)*
Checks: `fwvip_wb_transaction` rand `adr/dat/sel/we` produce legal stimulus; constrained random regression
of mixed read/write traffic checked against the reusable `fwvip_wb_scoreboard` (Decision 4).

### 3.9 Register Abstraction (REG)

**REG-01 — reg2bus / bus2reg round-trip.** *(L4 — `uvm-test-reg`)*
Implemented as `fwvip_wb_vseq_reg`: write `0xA5A5A5A5` then read. Checks: `reg2bus` sets `we`, full `sel='1`,
addr/data; `bus2reg` returns data and status; read-back equals written. To extend: multiple registers and
randomized values.

**REG-02 — Reg model write/read status propagation.** *(L4)*
Stimulus: target returns `err` on a register access. Checks: `uvm_reg` write/read `status==UVM_NOT_OK`.

**REG-03 — n_bits / endianness.** *(L4)*
Checks: `rw.n_bits == DATA_WIDTH_MAX`; map declared `UVM_LITTLE_ENDIAN` behaves consistently for the 32-bit
single-word case. *(Byte-lane endianness is handled above the transactor (Decision 2); `SEL` is transport-only
here, so no lane-steering checks at the transactor level — see §1.1.)*

### 3.10 Parameterization (PARAM)

**PARAM-01 — Width sweep.** *(L1/L2)*
Stimulus: build cores/if with `{ADDR_WIDTH, DATA_WIDTH}` ∈ {(16,16),(32,32),(64,64),(32,8),(64,32)}.
Checks: derived `REQ_WIDTH/RSP_WIDTH/MON_WIDTH` and `sel` width (`DATA_WIDTH/8`) are consistent; basic
write/read passes at each width. (Confirms `DATA_WIDTH` divisible-by-8 assumption.)

**PARAM-02 — FIFO DEPTH sweep.** *(L2)*
Stimulus: `DEPTH` ∈ {1,2,4,8}. Checks: FIFO-01..05 pass at each depth.

---

## 4. Functional Coverage Model

Collected at L1/L4 (bus-facing) via a covergroup sampled on each bus termination and each monitor txn:

- **cp_direction:** read, write.
- **cp_term:** ACK, ERR. *(RTY bin unreachable this phase — becomes live in Phase 2, §9.)*
- **cp_sel:** byte-enable patterns — at minimum {none?, single-byte ×N, contiguous pairs, all}. (Cross with
  direction.)
- **cp_addr_region:** low/mid/high address buckets; word-aligned vs unaligned (if exercised).
- **cp_wait_states:** ACK latency buckets {0, 1, 2, 3+ cycles}.
- **cp_fifo_occupancy:** empty, 1, mid, full(DEPTH), and full→backpressure event.
- **cp_b2b:** consecutive same-direction vs. direction-change transitions (cross cp_direction × prev).
- **cross:** direction × term × sel; direction × wait_states.

Coverage closure goal: 100% of reachable bins; RTY/BLOCK/RMW/CTI/BTE bins are deferred to the future phases
in §9 (tracked, not permanently waived).

---

## 5. Assertions / Protocol Checker (SVA)

Centralize in / extend `fwvip_wb_checkers` (already bound in formal TBs). Bus-side properties:

- **A1:** `stb |-> cyc` (CYC envelopes STB). RULE 3.25.
- **A2:** at most one of `{ack, err}` (and `rty` if added) asserted per cycle. RULE 3.45.
- **A3:** while `cyc&stb` and not yet terminated, `adr/dat_w/we/sel` stable. RULE 3.60.
- **A4:** every `cyc&stb` is followed within MAX_CYCLE_LEN by a termination (liveness, bounded).
- **A5:** `ack`/`err` only asserted in response to `cyc&stb` (no unsolicited termination on the target side).
- **A6:** after reset de-assert, first registered state has `cyc==0,stb==0`. RULE 3.20.
- **A7 (monitor):** monitor outputs are never driven onto bus signals (connectivity check).

Run A1–A6 in **formal** (initiator and target formal TBs) and as runtime assertions in L1/L3/L4 sims.

---

## 6. Risks / Findings to Confirm During Bring-up

These were noted while reading the RTL and should be validated (each becomes a directed test or a waiver):

- **RISK-1 — Initiator `term = ack || err` is not gated by `cyc/stb`.** In the integrated point-to-point
  case the target only drives ACK/ERR during a cycle, so it is benign; but if the initiator is ever
  connected to a slave that holds ACK high (RULE 3.55 says masters must tolerate this), a stray ACK could
  prematurely terminate. Covered by **ERR-04 / HSK-03**.
- **RISK-2 — REQ field naming asymmetry.** Initiator REQ struct field is `stb` (byte-enables) while target
  REQ struct field is `sel`; both occupy the same bit positions. Confirm bit-exact alignment under the
  width sweep — **FIFO-07 / PARAM-01**.
- **RISK-3 — Monitor single-entry buffer may drop a transaction** if two bus terminations occur while
  `mon_ready` is held low (no internal queue in the core; the IF FIFO is downstream). Characterize with
  **MON-03**.
- **RISK-4 — UVM config-get failures only `$display`** (initiator agent/driver) rather than `uvm_fatal`,
  so a misconfigured env runs with a null cfg. **UVM-01** should assert proper error reporting.
- **RISK-5 — Absolute `#10ns` delay in the target driver** ("UVM doesn't like 0-time"). Per Decision 3 this
  is a **defect**: transactors must be clock-period agnostic with no `#<delay>` literals. Replace with
  clock-edge synchronization and verify via **REQ-NODELAY / UVM-02 / UVM-05**.

---

## 7. Test ↔ Asset Mapping & Gaps

| Area | Existing asset | New work |
|---|---|---|
| Core b2b single R/W | `tb/fwvip_wb_transactor_core_b2b.sv` | add wait-states, partial SEL, ERR, randomization |
| Monitor core | `tb/fwvip_wb_monitor_core_tb.sv` | add back-pressure/drop (MON-03), read-direction (MON-02) |
| Formal | `formal/*_formal_tb.sv` + `fwvip_wb_checkers` | add A2/A3/A5/A6 properties; target-side covers |
| UVM L4 framework | `env/*` (vseqr, scoreboard, seq lib), `tests/fwvip_wb_test_base.svh` | ✅ implemented — base test + plusarg vseq + 7 DFM tasks (§2.1) |
| Reusable scoreboard (L4) | `env/fwvip_wb_scoreboard.svh` | ✅ implemented — shared across all tests (Decision 4) |
| UVM scenarios | `env/fwvip_wb_vseq_lib.svh`, `tests/fwvip_wb_vseq_reg.svh` | ✅ smoke/write/read/rand/sel/err/reg; still to add: ERR→UVM status (ERR-03), exact-count assertions |
| No-delay cleanup | target driver `#10ns` | **still open** — remove absolute delays; clock-edge sync (REQ-NODELAY) |
| FIFO/IF (L2) | — | **all new** (FIFO-01..07, RST-03/04) — not UVM (below the UVM layer) |
| Param sweeps | — | **all new** |

---

## 8. Design Decisions (Resolved)

These were open questions during drafting; the resolutions below are now reflected throughout the plan.

1. **Advanced cycles (BLOCK / RMW / Registered-Feedback CTI/BTE, RTY) are planned future growth.** The VIP
   will grow to support more-complex protocols, but that is out of scope for this phase. The §1.1 "Gap" rows
   are therefore **future test phases**, not permanent waivers — see §9 for the phasing.
2. **Endianness / byte-lane data organization is out of scope for the transactor.** Any endianness
   configuration is assumed to happen *above* the transactor; at the transactor level `SEL` is strictly
   transport metadata (carried, not decoded). No lane-steering tests at L0–L3.
3. **The VIP must be clock-period agnostic — no fixed `#<delay>` may appear in the transactors.** The current
   target driver `#10ns` prime (and any other absolute delay) is a defect to be removed; synchronization must
   be clock-edge based. This is now a hard requirement, tracked as **REQ-NODELAY** below and reflected in
   RISK-5 / UVM-02 / UVM-05.
4. **Scoreboards are reusable components.** L4 uses a reusable `fwvip_wb_scoreboard` (analysis-export based)
   component rather than in-test scoreboard logic, so it can be shared across tests and reused by VIP users.

### REQ-NODELAY — No absolute time delays in transactors *(L1–L4)*
Static/lint check + review: grep the transactor and UVM driver source for `#<delay>` literals; there must be
none. Functionally, re-run the directed suite at multiple clock periods (e.g. 4 ns, 10 ns, 13 ns) and confirm
identical behavior. Removes the clock-period coupling called out in RISK-5.

---

## 9. Future Phases (out of scope this cycle, planned)

Recorded so the §1.1 gaps are tracked as a roadmap rather than forgotten. Each becomes a test sub-plan when
the corresponding transactor support lands:

- **Phase 2 — RTY termination:** add `rty` signal/path; extend HSK/ERR tests and the `cp_term` coverpoint
  (the currently-waived RTY bin becomes live); A2 mutual-exclusion grows to `{ack,err,rty}`.
- **Phase 3 — BLOCK READ/WRITE:** multi-phase CYC-held cycles, per-phase STB toggling, MASTER/SLAVE wait
  states within a burst, multiple-outstanding handling.
- **Phase 4 — RMW cycle:** read-then-write under a single held CYC.
- **Phase 5 — Registered Feedback:** `CTI_O`/`BTE_O` ports; Classic/Constant-address/Incrementing/End-of-burst
  decode and the BTE wrap modes.
- **Phase 6 — TAG signals (TGA/TGD/TGC):** qualification timing per §3.1.5.

Endianness/byte-lane organization (§3.5) is intentionally **not** in this roadmap — it lives above the
transactor (Decision 2).

---

## 10. Continuous Integration

GitHub Actions runs the simulation suite on every push/PR to `main` (`.github/workflows/ci.yml`):

1. **`fvutils/ivpm-setup@v1`** — installs IVPM and runs `ivpm update` for the `default` + `default-dev`
   dep-sets, fetching `fwprotocol-defs` (TB macros + protocol-defs flow package), the dv-flow libraries,
   UVM, Verilator, and the dfm Python venv. Content-addressed dependency caching is on by default.
2. **`dv-flow/run-dvflow@v1`** — runs the DFM sim tasks via the project `.envrc` (direnv), publishing a
   report bundle as a job-summary + artifact and failing the job on any failed task. Tasks run:
   `core-b2b-sim-run`, `mon-sim-run`, and the seven `uvm-test-*` entrypoints.

**Dependency cleanup (fragility removal):** `fwvip-common` was removed entirely — it was unused (all TB
macros come from `fwprotocol-defs`; no dfm task referenced it) and its GitHub HEAD is an incompatible rename
(`org.fwvip.common`) that a fresh `ivpm update` would otherwise fetch and fail importing. `fwprotocol-defs`
is now a **direct** `ivpm.yaml` dependency (previously reached only transitively through fwvip-common), and
the `packages/fwvip-common/flow.yaml` import was dropped from `flow.yaml`. Verified locally: the image
rebuilds and the UVM suite passes with no fwvip-common present.

> Formal tasks are not yet in CI (the sandbox's `dv-flow-libformal` only exposes BMC; the cover bench is
> commented out — see the sim-setup notes). Add once a formal toolchain is wired into the CI image.
