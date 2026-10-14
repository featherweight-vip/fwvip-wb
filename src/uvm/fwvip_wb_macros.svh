
`ifndef INCLUDED_FWVIP_WB_MACROS_SVH
`define INCLUDED_FWVIP_WB_MACROS_SVH

// Each macro publishes the role's config as "cfg" for the components under
// `inst` (a uvm_config_db instance path, e.g. "uvm_test_top.m_env.m_init*").
// The agent and its driver both look it up as get(this, "", "cfg", ...), so
// `inst` must match them -- a trailing `*` covers the agent's children.
`define fwvip_wb_initiator_register(ADDR_WIDTH,DATA_WIDTH,vif,inst) \
    fwvip_wb_initiator_config_p #(virtual wb_initiator_xtor_if #(ADDR_WIDTH,DATA_WIDTH), ADDR_WIDTH, DATA_WIDTH)::set( \
      null, inst, "cfg", vif);

`define fwvip_wb_target_register(ADDR_WIDTH,DATA_WIDTH,vif,inst) \
    fwvip_wb_target_config_p #(virtual wb_target_xtor_if #(ADDR_WIDTH,DATA_WIDTH), ADDR_WIDTH, DATA_WIDTH)::set( \
      null, inst, "cfg", vif);

`define fwvip_wb_monitor_register(ADDR_WIDTH,DATA_WIDTH,vif,inst) \
    fwvip_wb_monitor_config_p #(virtual wb_monitor_xtor_if #(ADDR_WIDTH,DATA_WIDTH))::set( \
      null, inst, "cfg", vif);

`endif /* INCLUDED_FWVIP_WB_MACROS_SVH */
