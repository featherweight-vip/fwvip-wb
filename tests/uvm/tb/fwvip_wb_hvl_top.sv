
`include "uvm_macros.svh"
`include "fwvip_wb_macros.svh"

module fwvip_wb_hvl_top;
    import uvm_pkg::*;
    import fwvip_wb_pkg::*;
    import fwvip_core_uvm_pkg::*;
    import fwvip_wb_tests_pkg::*;

`ifdef TRACE_EN
    initial begin
        $dumpfile("sim.vcd");
        $dumpvars;
    end
`endif

    fwvip_wb_hdl_top u_hdl();


    initial begin
        `fwvip_wb_initiator_register(
            32,
            32,
            u_hdl.u_initiator.u_if,
            "uvm_test_top.m_env.m_init*");
        `fwvip_wb_target_register(
            32,
            32,
            u_hdl.u_target.u_if,
            "uvm_test_top.m_env.m_targ*");
        `fwvip_wb_monitor_register(
            32,
            32,
            u_hdl.u_monitor.u_if,
            "uvm_test_top.m_env.m_mon*");

        // Provide monitor config for agent
        fwvip_wb_monitor_config_p#(virtual wb_monitor_xtor_if#(32,32))::set(
            null,
            "uvm_test_top.m_env.m_mon",
            "cfg",
            u_hdl.u_monitor.u_if);

        // Provide the core clock/reset config providers to the env. The env
        // looks these up and the base virtual sequence waits on the reset
        // provider before driving stimulus.
        fwvip_clock_config_p#(virtual fwvip_clock_xtor_if)::set(
            null,
            "uvm_test_top.m_env*",
            "clock",
            u_hdl.u_clk_if);
        fwvip_reset_config_p#(virtual fwvip_reset_xtor_if#(1))::set(
            null,
            "uvm_test_top.m_env*",
            "reset",
            u_hdl.u_rst_if);

        run_test();
    end

endmodule