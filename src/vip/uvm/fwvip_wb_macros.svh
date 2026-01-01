
`ifndef INCLUDED_FWVIP_WB_MACROS_SVH
`define INCLUDED_FWVIP_WB_MACROS_SVH

`define fwvip_wb_initiator_register(ADDR_WIDTH,DATA_WIDTH,vif,inst) \
    fwvip_wb_initiator_config_p #(virtual fwvip_wb_initiator_if #(ADDR_WIDTH,DATA_WIDTH), ADDR_WIDTH, DATA_WIDTH)::set( \
      null, "", "cfg", vif);

`define FWVIP_WB_INITIATOR_REGISTER(ADDR_WIDTH,DATA_WIDTH,vif,inst) \
    fwvip_wb_initiator_config_p #(virtual fwvip_wb_initiator_if #(ADDR_WIDTH,DATA_WIDTH), ADDR_WIDTH, DATA_WIDTH)::set( \
      null, "", "cfg", vif);

`define fwvip_wb_target_register(ADDR_WIDTH,DATA_WIDTH,vif,inst) \
    fwvip_wb_target_config_p #(virtual fwvip_wb_target_if #(ADDR_WIDTH,DATA_WIDTH), ADDR_WIDTH, DATA_WIDTH)::set( \
      null, "", "cfg", vif);

`define fwvip_wb_monitor_register(ADDR_WIDTH,DATA_WIDTH,vif,inst) \
    fwvip_wb_monitor_config_p #(virtual fwvip_wb_monitor_if #(ADDR_WIDTH,DATA_WIDTH))::set( \
      null, inst, "cfg", vif);

`endif /* INCLUDED_FWVIP_WB_MACROS_SVH */
