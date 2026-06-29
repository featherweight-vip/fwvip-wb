// Ready/valid testbench convenience macros (connections).
//
// Vendored locally into the fwvip-wb VIP so the project no longer depends on the
// external fwprotocol-defs package (migration owner directive). Only the macro the
// VIP's TBs use is kept: RV_CONNECT.
`ifndef INCLUDED_RV_MACROS_SVH
`define INCLUDED_RV_MACROS_SVH

`define RV_CONNECT(P_PREFIX, W_PREFIX) \
	.P_PREFIX``dat( W_PREFIX``dat ), \
	.P_PREFIX``valid( W_PREFIX``valid ), \
	.P_PREFIX``ready( W_PREFIX``ready )

`endif /* INCLUDED_RV_MACROS_SVH */
