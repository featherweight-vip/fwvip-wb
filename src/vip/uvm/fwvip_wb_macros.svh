
`ifndef INCLUDED_FWVIP_WB_MACROS_SVH
`define INCLUDED_FWVIP_WB_MACROS_SVH

`define fwvip_wb_initiator_register(ADDR_WIDTH,DATA_WIDTH,vif,inst) \
begin \
    typedef virtual fwvip_wb_initiator_if #(ADDR_WIDTH,DATA_WIDTH) vif_t; \
    fwvip_wb_initiator_config_p #(vif_t, ADDR_WIDTH, DATA_WIDTH)::set( \
      null, "", "cfg", vif); \
end

`endif /* INCLUDED_FWVIP_WB_MACROS_SVH */
