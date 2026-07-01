# Integrating the VIP into a testbench

This page shows how to drop `fwvip-wb` into a UVM bench: the DFM dependency, the `hdl_top` /
`hvl_top` wiring, and the `register` macros. The worked source is in
`tests/uvm/tb/fwvip_wb_hdl_top.sv` and `tests/uvm/tb/fwvip_wb_hvl_top.sv`.

## DFM dependency

The top-level `flow.yaml` already imports `fw-proto-wb` and `fwvip-core`. Your testbench
fileset depends on the VIP's two SV exports:

```yaml
needs:
- org.fwvip.wb.xtor-pkg          # fwvip_wb_xtor_pkg (constants) — compiled first
- org.fwvip.wb.vip-uvm-hvlsrc    # fwvip_wb_pkg (the agent classes)
```

`vip-uvm-hvlsrc` already pulls in the kit's `fw.proto.wb.xtor-sv` (interfaces + wrappers) and
`fw.proto.wb.class` (the bridge class layer). For the Python/cocotb front-end you instead need
`fw.proto.wb.xtor-core` plus the `dv-flow-libcocotb` `cocotb.*` tasks (see {doc}`cocotb`).

## `hdl_top` — instantiate the kit wrappers + clock/reset interfaces

`hdl_top` puts the three kit wrappers on a shared Wishbone bus and instantiates the `fwvip-core`
clock/reset transactor interfaces that back the providers:

```systemverilog
`include "wishbone_macros.svh"
localparam int ADDR_WIDTH = 32, DATA_WIDTH = 32;
`WB_WIRES(wb_, ADDR_WIDTH, DATA_WIDTH);

wb_initiator_xtor #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH))
    u_initiator (.clock, .reset, `WB_CONNECT( , wb_));
wb_target_xtor    #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH))
    u_target    (.clock, .reset, `WB_CONNECT( , wb_));
wb_monitor_xtor   #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH))
    u_monitor   (.clock, .reset, `WB_CONNECT( , wb_));

fwvip_clock_xtor_if               u_clk_if (.clock, .reset);   // back the fwvip-core providers
fwvip_reset_xtor_if #(.ACTIVE(1)) u_rst_if (.clock, .reset);
```

## `hvl_top` — register the configs, then `run_test`

`hvl_top` binds each wrapper's `.u_if` into the config DB through a `register` macro, registers
the clock/reset providers from `fwvip-core`, and starts the test. The macros (from
`fwvip_wb_macros.svh`) thread the widths and wrap the vif in the right `virtual` type:

```systemverilog
`fwvip_wb_initiator_register(ADDR_WIDTH, DATA_WIDTH, vif, inst)   // -> wb_initiator_xtor_if #(AW,DW)
`fwvip_wb_target_register   (ADDR_WIDTH, DATA_WIDTH, vif, inst)   // -> wb_target_xtor_if    #(AW,DW)
`fwvip_wb_monitor_register  (ADDR_WIDTH, DATA_WIDTH, vif, inst)   // -> wb_monitor_xtor_if   #(AW,DW)
```

```systemverilog
initial begin
    `fwvip_wb_initiator_register(32, 32, u_hdl.u_initiator.u_if, "uvm_test_top.m_env.m_init*");
    `fwvip_wb_target_register   (32, 32, u_hdl.u_target.u_if,    "uvm_test_top.m_env.m_targ*");
    `fwvip_wb_monitor_register  (32, 32, u_hdl.u_monitor.u_if,   "uvm_test_top.m_env.m_mon*");

    // Reset/clock come from the fwvip-core providers — never a fixed delay.
    fwvip_clock_config_p#(virtual fwvip_clock_xtor_if    )::set(null,"uvm_test_top.m_env*","clock",u_hdl.u_clk_if);
    fwvip_reset_config_p#(virtual fwvip_reset_xtor_if#(1))::set(null,"uvm_test_top.m_env*","reset",u_hdl.u_rst_if);

    run_test();
end
```

Pass the wrapper's `.u_if` as the `vif` argument — the macro wraps it in the right
`virtual wb_*_xtor_if #(AW,DW)` type and calls `*_config_p::set(...)`.

```{admonition} Use the lowercase macro with the kit wrapper
:class: tip
An uppercase `FWVIP_WB_INITIATOR_REGISTER` variant exists that binds against
`fwvip_wb_initiator_if` instead of the kit `wb_initiator_xtor_if`. With the kit wrapper, use the
lowercase `fwvip_wb_initiator_register`.
```

## The env

The reusable env (`tests/uvm/env/`) builds the three agents, a virtual sequencer, and a
scoreboard; wires the vseqr to the sub-sequencers and configs; and connects the monitor's
analysis port to the scoreboard. It **retrieves the clock/reset providers** and hands them to
the vseqr, and the base virtual sequence waits on reset before issuing stimulus — so reset is
never a fixed delay. The reusable sequence library lives in the env/test packages, not in
`fwvip_wb_pkg`.

```{admonition} Reset comes from the providers
:class: warning
Always wait on the reset provider (`reset_provider.wait_reset()` — the base vseq already does)
before driving stimulus. Do not hard-code a delay.
```
