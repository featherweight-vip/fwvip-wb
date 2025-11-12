`include "uvm_macros.svh"
`include "fwvip_wb_macros.svh"

package fwvip_wb_pkg;
    import uvm_pkg::*;
    import fwvip_wb_bfm_pkg::*;

    `include "fwvip_wb_initiator.svh"
    `include "fwvip_wb_initiator_driver.svh"
    `include "fwvip_wb_initiator_seq.svh"
    `include "fwvip_wb_config.svh"
    `include "fwvip_wb_transaction.svh"

endpackage
