
`include "uvm_macros.svh"
`include "fwvip_wb_macros.svh"

module fwvip_wb_hvl_top;
    import uvm_pkg::*;
    import fwvip_wb_pkg::*;
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
            u_hdl.u_initiator,
            "uvm_test_top.m_env.m_init*");
        `fwvip_wb_target_register(
            32,
            32,
            u_hdl.u_target,
            "uvm_test_top.m_env.m_targ*");
        `fwvip_wb_monitor_register(
            32,
            32,
            u_hdl.u_monitor,
            "uvm_test_top.m_env.m_mon*");

        // Provide monitor config for agent
        fwvip_wb_monitor_config_p#(virtual fwvip_wb_monitor_if#(32,32))::set(
            null,
            "uvm_test_top.m_env.m_mon",
            "cfg",
            u_hdl.u_monitor);

        run_test();
    end

endmodule