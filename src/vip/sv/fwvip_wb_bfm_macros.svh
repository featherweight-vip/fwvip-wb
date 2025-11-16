
`ifndef INCLUDED_FWVIP_WB_BFM_MACROS_SVH
`define INCLUDED_FWVIP_WB_BFM_MACROS_SVH

`define FWVIP_WB_INITIATOR_REQ_S(ADDR_WIDTH, DATA_WIDTH) \
    struct packed { \
        bit[ADDR_WIDTH-1:0]     adr; \
        bit[DATA_WIDTH-1:0]     dat; \
        bit                     we;  \
        bit[(DATA_WIDTH/8)-1:0] stb; \
    } 

`define FWVIP_WB_INITIATOR_RSP_S(ADDR_WIDTH, DATA_WIDTH) \
    struct packed { \
        bit[DATA_WIDTH-1:0]     dat; \
        bit                     err; \
    }

`define FWVIP_WB_TARGET_REQ_S(ADDR_WIDTH, DATA_WIDTH) \
    struct packed { \
        bit [ADDR_WIDTH-1:0]      adr; \
        bit [DATA_WIDTH-1:0]      dat; \
        bit                       we; \
        bit [(DATA_WIDTH/8)-1:0]  sel; \
    }

`define FWVIP_WB_TARGET_RSP_S(ADDR_WIDTH, DATA_WIDTH) \
    struct packed { \
        bit [DATA_WIDTH-1:0]      dat; \
        bit                       err; \
    }


`endif /* INCLUDED_FWVIP_WB_BFM_MACROS_SVH */
