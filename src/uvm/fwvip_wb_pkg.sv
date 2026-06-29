`include "uvm_macros.svh"
`include "fwvip_wb_macros.svh"

package fwvip_wb_pkg;
    import uvm_pkg::*;
    import fwvip_wb_xtor_pkg::*;
    // Class layer of the WB protocol kit: wb_proto_if + wb_*_xtor_bridge. The
    // target config implements wb_proto_if and owns a wb_target_xtor_bridge.
    import fw_proto_wb_pkg::*;

    // Data item + responder interface first: they are used as the parameter
    // type of the target sequencer/driver, so must be fully defined before the
    // components that specialize on them.
    `include "fwvip_wb_transaction.svh"
    `include "fwvip_wb_target_if.svh"
    `include "fwvip_wb_target_item.svh"

    `include "fwvip_wb_initiator.svh"
    `include "fwvip_wb_initiator_config.svh"
    `include "fwvip_wb_initiator_driver.svh"
    `include "fwvip_wb_initiator_seq.svh"
    `include "fwvip_wb_target_seq.svh"
    `include "fwvip_wb_target_config.svh"
    `include "fwvip_wb_target_driver.svh"
    `include "fwvip_wb_target.svh"

    `include "fwvip_wb_monitor_config.svh"
    `include "fwvip_wb_monitor.svh"
    `include "fwvip_wb_monitor_agent.svh"

    `include "fwvip_wb_reg_adapter.svh"
 
 endpackage
