# Overview

## What a VIP is, and what it is not

`fwvip-wb` is a **methodology layer**. It packages the Wishbone bus as a set of UVM agents and a
Python/cocotb front-end so that a testbench can speak transactions — *write this address*,
*respond to that request*, *observe everything on the bus* — instead of toggling pins.

It deliberately contains **no RTL FSMs, no pin-level timing, and no protocol checker**. Those
belong to the layer beneath it.

## The two layers (and the shared core)

| Layer | Package | Provides |
| --- | --- | --- |
| **Transactor kit** | `fw-proto-wb` | Signal-level cores, SV interfaces, the `wb_*_xtor_bridge` class API, and `wb_proto_checker`. |
| **VIP / methodology** | `fwvip-wb` *(this package)* | UVM agents + a Python/cocotb front-end built **on top of** the kit. |
| **Shared infrastructure** | `fwvip-core` | Clock/reset transactors + UVM config providers, ready/valid FIFO primitives, the cocotb performance pattern. |

The kit **must already exist** — the VIP consumes it; it never creates cores, interfaces,
wrappers, bridges, or checkers. Concretely, the VIP's per-role *config* objects hold a kit
`virtual` interface, construct the matching `wb_*_xtor_bridge`, and forward the kit's
method-level API. Everything the VIP adds is methodology glue around that seam.

## Fast by construction

The protocol and timing reasoning — the part that is easy to get subtly wrong — is solved once
in the `fw-proto-wb` cores and proven with a SymbiYosys formal back-to-back check. The VIP
inherits that correctness. Its cocotb backend follows the `fwvip-core` event-driven handshake
pattern (idle by sleeping on a signal edge; sample at the clock edge), so simulation stays fast
without per-cycle polling. See {doc}`cocotb` and `fwvip-core`'s *cocotb-performance* note.

## Role archetypes

Wishbone is a synchronous, memory-mapped, request/response bus, so its three roles map cleanly
onto the three VIP archetypes:

- **Driving / active — the initiator.** The VIP *calls* the bus: the driver pulls a transaction
  off its sequencer and invokes `request()`/`response()` through the config seam adapter.
- **Callback responder — the target.** There is a real wire response, so the kit's
  `wb_target_xtor_bridge` polls the request FIFO and *calls back* per request. The VIP rides
  that callback into a responder sequence; you fill in read data / error and the response is
  returned automatically.
- **Passive analysis producer — the monitor.** A poll-loop on the bus turns every observed
  access into a `fwvip_wb_transaction` published on a `uvm_analysis_port`.

Because Wishbone *has* a wire response and *is* addressed, the VIP includes both a responder
(the target) and a register-model front door (`fwvip_wb_reg_adapter`) — features a one-way
streaming protocol would omit.

## What ships in the package

- **UVM** (`src/uvm/`): `fwvip_wb_pkg` with the transaction, the three agents, their configs and
  drivers, the target responder plumbing, the register adapter, and the `register` macros; plus
  the small constants package `fwvip_wb_xtor_pkg`.
- **Python/cocotb** (`src/python/org/fwvip/wb/`): a backend-independent front-end
  (`WbInitiator` / `WbTarget` / `WbMonitor`) over a cocotb backend.
- **Tests** (`tests/`): worked UVM and cocotb testbenches, exercised through DFM tasks.
