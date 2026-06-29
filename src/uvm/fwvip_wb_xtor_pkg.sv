// Consumer-side width constants for the (non-parameterized, class-based) UVM VIP
// layer. ADDR_WIDTH_MAX / DATA_WIDTH_MAX size the transaction/config/monitor/
// reg-adapter fields independently of any per-instance transactor width.
//
// Per migration Decision D4 these are NOT a property of the core transactor (which
// moved to the fw-proto-wb package and is per-instance parameterized): they belong
// to the non-parameterized class-based consumers -- i.e. this VIP. Kept here so the
// UVM/env/tests packages import a stable `fwvip_wb_xtor_pkg`.
package fwvip_wb_xtor_pkg;
    parameter int ADDR_WIDTH_MAX = 64;
    parameter int DATA_WIDTH_MAX = 64;

endpackage
