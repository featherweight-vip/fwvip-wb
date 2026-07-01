# fwvip-wb — Wishbone Verification IP

`fwvip-wb` is the **Verification IP** for the **Wishbone B3** bus — the *methodology layer*
(UVM agents plus a Python/cocotb front-end) that lets a testbench drive, respond to, and
observe Wishbone traffic at the transaction level.

It is built in two layers it never re-implements:

- the [`fw-proto-wb`](https://github.com/featherweight-vip/fw-proto-wb) **transactor kit** —
  signal-level cores, SV interfaces, `wb_*_xtor_bridge` classes, and the `wb_proto_checker`; and
- [`fwvip-core`](https://github.com/featherweight-vip/fwvip-core) — the shared clock/reset
  transactors and their UVM config providers, plus the cocotb performance pattern.

Because the protocol and timing reasoning is solved once in the verified kit cores, the agents
and tests built on top are correct and **fast by construction**.

```{admonition} DFM package
:class: note
The VIP is the DFM package **`org.fwvip.wb`**. Its SystemVerilog source lives in `src/uvm/`,
the Python/cocotb front-end in `src/python/org/fwvip/wb/`, and worked testbenches in `tests/`.
```

## The three roles

| Role | Archetype | Agent class | Drives / taps |
| --- | --- | --- | --- |
| **initiator** (master) | driving / active — the VIP *calls* `request()`/`response()` | `fwvip_wb_initiator` | CYC/STB/ADR/DAT_O/WE/SEL |
| **target** (slave) | callback responder — the kit bridge *calls back* per request | `fwvip_wb_target` | ACK/ERR/DAT_O |
| **monitor** | passive analysis producer — poll-loops the bus | `fwvip_wb_monitor_agent` | — (taps only) |

A register-model front door (`fwvip_wb_reg_adapter`) rides the initiator for `uvm_reg` access.

## Where to start

- New here? Read the {doc}`overview` for the design philosophy and how the layers fit, then
  {doc}`getting-started` to build and run the example tests.
- Wiring the VIP into a bench? See {doc}`integration` (hdl/hvl tops, register macros, clock/reset).
- Writing stimulus? See {doc}`sequences` (initiator stimulus + target responder) and
  {doc}`register-model` (the `uvm_reg` front door).
- Driving from Python? See {doc}`cocotb`.
- What's tested and how? See {doc}`verification`.

```{toctree}
:maxdepth: 2
:caption: Guide

overview
getting-started
architecture
integration
sequences
register-model
cocotb
verification
```
