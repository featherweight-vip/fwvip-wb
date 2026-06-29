`include "uvm_macros.svh"
package fwvip_wb_env_pkg;
    import uvm_pkg::*;
    import fwvip_wb_xtor_pkg::*;
    import fwvip_wb_pkg::*;
    // Core clock/reset providers: fwvip_core_pkg supplies the abstract
    // fwvip_clock_if / fwvip_wait_reset_if APIs; fwvip_core_uvm_pkg supplies the
    // concrete config objects retrieved from the config DB.
    import fwvip_core_pkg::*;
    import fwvip_core_uvm_pkg::*;

    // Reusable infrastructure
    `include "fwvip_wb_vseqr.svh"
    `include "fwvip_wb_scoreboard.svh"

    // Reusable sequence library
    `include "fwvip_wb_mem_target_seq.svh"
    `include "fwvip_wb_init_access_seq.svh"
    `include "fwvip_wb_vseq_base.svh"
    `include "fwvip_wb_vseq_lib.svh"

    // Environment
    `include "fwvip_wb_env.svh"

endpackage
