`include "wishbone_macros.svh"
`include "rv_macros.svh"
`include "fwvip_macros.svh"

// Top-level Wishbone Target BFM integrating core + RV FIFOs
`fwvip_bfm_t fwvip_wb_target_if #(
        parameter int ADDR_WIDTH = 32,
        parameter int DATA_WIDTH = 32,
        parameter int REQ_WIDTH  = (ADDR_WIDTH+DATA_WIDTH+(DATA_WIDTH/8)+1),
        parameter int RSP_WIDTH  = (DATA_WIDTH+1)
    ) (
        input clock,
        input reset,
        `WB_TARGET_PORT(t, ADDR_WIDTH, DATA_WIDTH)
    );
    import fwvip_wb_bfm_pkg::*;

    // RV channels between core and FIFOs
    logic [REQ_WIDTH-1:0]  req_dat;
    logic                  req_valid;
    logic                  req_ready;
    logic [RSP_WIDTH-1:0]  rsp_dat;
    logic                  rsp_valid;
    logic                  rsp_ready;

    // Egress FIFO captures requests produced by target core (req_)
    fwvip_egress_fifo_if #(
        .WIDTH(REQ_WIDTH)
    ) req_fifo (
        .clock(clock),
        .reset(reset),
        .e_dat(req_dat),
        .e_valid(req_valid),
        .e_ready(req_ready)
    );

    // Ingress FIFO provides responses to target core (rsp_)
    fwvip_ingress_fifo_if #(
        .WIDTH(RSP_WIDTH)
    ) rsp_fifo (
        .clock(clock),
        .reset(reset),
        .i_dat(rsp_dat),
        .i_valid(rsp_valid),
        .i_ready(rsp_ready)
    );

    // Core transactor
    fwvip_wb_target_core #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .REQ_WIDTH(REQ_WIDTH),
        .RSP_WIDTH(RSP_WIDTH)
    ) core (
        .clock(clock),
        .reset(reset),
        // Wishbone target port
        .tadr(tadr),
        .tdat_w(tdat_w),
        .tdat_r(tdat_r),
        .tcyc(tcyc),
        .terr(terr),
        .tsel(tsel),
        .tstb(tstb),
        .tack(tack),
        .twe(twe),
        // RV request/response
        .req_dat(req_dat),
        .req_valid(req_valid),
        .req_ready(req_ready),
        .rsp_dat(rsp_dat),
        .rsp_valid(rsp_valid),
        .rsp_ready(rsp_ready)
    );

    // --------------------------------------------------------------------
    // API tasks to access request/response FIFOs from HVL side
    // --------------------------------------------------------------------
    typedef struct packed {
        bit[ADDR_WIDTH-1:0]     adr;
        bit[DATA_WIDTH-1:0]     dat;
        bit                      we;
        bit[(DATA_WIDTH/8)-1:0] stb;
    } req_s;

    typedef struct packed {
        bit[DATA_WIDTH-1:0]     dat;
        bit                      err;
    } rsp_s;

    // Wait for reset release
    task wait_reset();
        if (reset) @(negedge reset);
        @(posedge clock);
    endtask

    task wait_req(
        output [ADDR_WIDTH_MAX-1:0]     adr,
        output [DATA_WIDTH_MAX-1:0]     dat,
        output [(DATA_WIDTH_MAX/8)-1:0] sel,
        output                          we);
        req_s r;
        $display("--> %0t wait_req", $time);
        req_fifo.get(r);
        adr = r.adr;
        dat = r.dat;
        sel = r.stb;
        we  = r.we;
        $display("<-- %0t wait_req", $time);
    endtask

    task send_rsp(
        input [DATA_WIDTH_MAX-1:0]    dat,
        input                         err);
        rsp_s r;
        r = '{dat: dat[DATA_WIDTH-1:0], err: err};
        rsp_fifo.put(r);
    endtask

    // Get next incoming Wishbone request (produced by core)
    task get_req(
        output [ADDR_WIDTH-1:0]      adr,
        output [DATA_WIDTH-1:0]      dat,
        output [DATA_WIDTH/8-1:0]    stb,
        output                       we
    );
        req_s r;
        req_fifo.get(r);
        adr = r.adr;
        dat = r.dat;
        stb = r.stb;
        we  = r.we;
    endtask

    // Provide a response
    task put_rsp(
        input [DATA_WIDTH-1:0]      dat,
        input                       err
    );
        rsp_s r;
        r = '{dat: dat, err: err};
        rsp_fifo.put(r);
    endtask

`fwvip_bfm_t_end
