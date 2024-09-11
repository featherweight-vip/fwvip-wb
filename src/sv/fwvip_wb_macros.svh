
`ifndef INCLUDED_FWVIP_WB_MACROS_SVH
`define INCLUDED_FWVIP_WB_MACROS_SVH

`define fwvip_wb_register_initiator(init, ADDR_WIDTH, DATA_WIDTH) \
    initial begin \
        typedef virtual fwvip_wb_initiator #(ADDR_WIDTH, DATA_WIDTH) vif_t; \
        automatic fwvip_wb_pkg::fwvip_wb_initiator_api_p #(vif_t, ADDR_WIDTH, DATA_WIDTH) api; \
        api = new(init, init``.path()); \
        fwvip_wb_pkg::fwvip_wb_initiator_rgy.register(api); \
    end

`endif /* INCLUDED_FWVIP_WB_MACROS_SVH */
