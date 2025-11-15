`include "wishbone_macros.svh"
`include "rv_macros.svh"
`include "fwvip_macros.svh"

// Top-level Wishbone Monitor BFM integrating core + RV egress FIFO
`fwvip_bfm_t fwvip_wb_monitor_if #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int MON_WIDTH  = (ADDR_WIDTH + DATA_WIDTH + (DATA_WIDTH/8) + 1 + 1)
) (
    input                           clock,
    input                           reset,
    // Observed Wishbone signals
    `WB_MONITOR_PORT(i, ADDR_WIDTH, DATA_WIDTH)
);
    import fwvip_wb_bfm_pkg::*;

    // RV channel between core and FIFO
    logic [MON_WIDTH-1:0]  mon_dat;
    logic                  mon_valid;
    logic                  mon_ready;

    // Egress FIFO captures transactions produced by monitor core
    fwvip_egress_fifo_if #(
        .WIDTH(MON_WIDTH)
    ) mon_fifo (
        .clock(clock),
        .reset(reset),
        .e_dat(mon_dat),
        .e_valid(mon_valid),
        .e_ready(mon_ready)
    );

    // Core transactor
    fwvip_wb_monitor_core #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .MON_WIDTH(MON_WIDTH)
    ) core (
        .clock(clock),
        .reset(reset),
        .iadr(iadr),
        .idat_w(idat_w),
        .idat_r(idat_r),
        .iwe(iwe),
        .istb(istb),
        .isel(isel),
        .iack(iack),
        .ierr(ierr),
        .icyc(icyc),
        .mon_dat(mon_dat),
        .mon_valid(mon_valid),
        .mon_ready(mon_ready)
    );

    // Payload struct for API
    typedef struct packed {
        bit [ADDR_WIDTH-1:0]      adr;
        bit [DATA_WIDTH-1:0]      dat;
        bit                        we;
        bit [(DATA_WIDTH/8)-1:0]  sel;
        bit                        err;
    } mon_s;

    // Wait for reset release
    task wait_reset();
        if (reset) @(negedge reset);
        @(posedge clock);
    endtask

    // Blocking wait for next observed transaction
    task wait_txn(
        output [ADDR_WIDTH_MAX-1:0]     o_adr,
        output [DATA_WIDTH_MAX-1:0]     o_dat,
        output [(DATA_WIDTH_MAX/8)-1:0] o_sel,
        output                           o_we,
        output                           o_err
    );
        mon_s r;
        mon_fifo.get(r);
        o_adr = r.adr;
        o_dat = r.dat;
        o_sel = r.sel;
        o_we  = r.we;
        o_err = r.err;
    endtask

`fwvip_bfm_t_end
