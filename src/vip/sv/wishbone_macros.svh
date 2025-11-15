`ifndef INCLUDED_WISHBONE_MACROS_SVH
`define INCLUDED_WISHBONE_MACROS_SVH

// Initiator (master) port bundle, signal prefix 'i'
`define WB_INITIATOR_PORT(pfx, ADDR_WIDTH, DATA_WIDTH) \
    input  logic [ADDR_WIDTH-1:0]    ``pfx``adr, \
    input  logic [DATA_WIDTH-1:0]    ``pfx``dat_w, \
    input  logic [DATA_WIDTH-1:0]    ``pfx``dat_r, \
    input  logic                     ``pfx``we, \
    input  logic                     ``pfx``stb, \
    input  logic [DATA_WIDTH/8-1:0]  ``pfx``sel, \
    input  logic                     ``pfx``ack, \
    input  logic                     ``pfx``err, \
    input  logic                     ``pfx``cyc

// Target (slave) port bundle, signal prefix 't'
`define WB_TARGET_PORT(pfx, ADDR_WIDTH, DATA_WIDTH) \
    input  logic [ADDR_WIDTH-1:0]    ``pfx``adr, \
    input  logic [DATA_WIDTH-1:0]    ``pfx``dat_w, \
    output logic [DATA_WIDTH-1:0]    ``pfx``dat_r, \
    input  logic                     ``pfx``we, \
    input  logic                     ``pfx``stb, \
    input  logic [DATA_WIDTH/8-1:0]  ``pfx``sel, \
    output logic                     ``pfx``ack, \
    output logic                     ``pfx``err, \
    input  logic                     ``pfx``cyc

`endif // INCLUDED_WISHBONE_MACROS_SVH
