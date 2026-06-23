
`include "uvm_macros.svh"
package fwvip_wb_tests_pkg;
    import uvm_pkg::*;
    import fwvip_wb_xtor_pkg::*;
    import fwvip_wb_pkg::*;
    import fwvip_wb_env_pkg::*;

    `include "fwvip_wb_mon_sub.svh"
    `include "fwvip_wb_test_base.svh"

    // Test-specific virtual sequences (generic ones live in fwvip_wb_env_pkg)
    `include "fwvip_wb_vseq_reg.svh"

endpackage
