// Wishbone testbench convenience macros (port lists / wires / connections).
//
// Vendored locally into the fwvip-wb VIP so the project no longer depends on the
// external fwprotocol-defs package (migration owner directive). Only the macros
// the VIP's TBs/checker use are kept: WB_MONITOR_PORT, WB_WIRES, WB_CONNECT.
`ifndef INCLDUDED_WISHBONE_MACROS_SVH
`define INCLDUDED_WISHBONE_MACROS_SVH

`define WB_MONITOR_PORT(PREFIX,ADDR_WIDTH,DATA_WIDTH) \
	input[ADDR_WIDTH-1:0]			PREFIX``adr, \
	input[DATA_WIDTH-1:0]			PREFIX``dat_w, \
	input[DATA_WIDTH-1:0]			PREFIX``dat_r, \
	input							PREFIX``cyc, \
	input							PREFIX``err, \
	input[DATA_WIDTH/8-1:0]			PREFIX``sel, \
	input							PREFIX``stb, \
	input							PREFIX``ack, \
	input							PREFIX``we

`define WB_WIRES(PREFIX,ADDR_WIDTH,DATA_WIDTH) \
	wire[ADDR_WIDTH-1:0]			PREFIX``adr; \
	wire[DATA_WIDTH-1:0]			PREFIX``dat_w; \
	wire[DATA_WIDTH-1:0]			PREFIX``dat_r; \
	wire							PREFIX``cyc; \
	wire							PREFIX``err; \
	wire[DATA_WIDTH/8-1:0]			PREFIX``sel; \
	wire							PREFIX``stb; \
	wire							PREFIX``ack; \
	wire							PREFIX``we;

`define WB_CONNECT(P_PREFIX,W_PREFIX) 	\
	.P_PREFIX``adr(W_PREFIX``adr), 		\
	.P_PREFIX``dat_w(W_PREFIX``dat_w), 	\
	.P_PREFIX``dat_r(W_PREFIX``dat_r), 	\
	.P_PREFIX``cyc(W_PREFIX``cyc), 		\
	.P_PREFIX``err(W_PREFIX``err), 		\
	.P_PREFIX``sel(W_PREFIX``sel), 		\
	.P_PREFIX``stb(W_PREFIX``stb), 		\
	.P_PREFIX``ack(W_PREFIX``ack), 		\
	.P_PREFIX``we(W_PREFIX``we)

`endif /* INCLDUDED_WISHBONE_MACROS_SVH */
