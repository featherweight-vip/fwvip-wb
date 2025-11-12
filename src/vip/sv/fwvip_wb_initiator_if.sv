`include "rv_macros.svh"
`include "fwvip_macros.svh"

// Top-level Wishbone Initiator BFM integrating core + RV FIFOs
`fwvip_bfm_t fwvip_wb_initiator_if #(
        parameter int ADDR_WIDTH = 32,
        parameter int DATA_WIDTH = 32,
        parameter int REQ_WIDTH  = (ADDR_WIDTH+DATA_WIDTH+(DATA_WIDTH/8)+1),
        parameter int RSP_WIDTH  = (DATA_WIDTH+1)
    ) (
        input                           clock,
        input                           reset,
        // Wishbone initiator signals (simple names for compatibility)
        output      [ADDR_WIDTH-1:0]    adr,
        output      [DATA_WIDTH-1:0]    dat_w,
        input       [DATA_WIDTH-1:0]    dat_r,
        output                          we,
        output                          stb,
        output      [DATA_WIDTH/8-1:0]  sel,
        input                           ack,
        input                           err,
        output                          cyc
    );
    import fwvip_wb_bfm_pkg::*;

    // RV channels between FIFOs and core
    logic [REQ_WIDTH-1:0]  req_dat;
    logic                  req_valid;
    logic                  req_ready;
    logic [RSP_WIDTH-1:0]  rsp_dat;
    logic                  rsp_valid;
    logic                  rsp_ready;

    task put(bit[REQ_WIDTH-1:0] val);
        req_fifo.put(val);
    endtask

    task get(output bit[RSP_WIDTH-1:0] val);
        req_fifo.put(val);
    endtask

    // Ingress FIFO feeds requests into core (core is RV target on req_)
    fwvip_ingress_fifo_if #(
        .WIDTH(REQ_WIDTH)
    ) req_fifo (
        .clock(clock),
        .reset(reset),
        .i_dat(req_dat),
        .i_valid(req_valid),
        .i_ready(req_ready)
    );

    // Egress FIFO captures responses from core (core is RV initiator on rsp_)
    fwvip_egress_fifo_if #(
        .WIDTH(RSP_WIDTH)
    ) rsp_fifo (
        .clock(clock),
        .reset(reset),
        .e_dat(rsp_dat),
        .e_valid(rsp_valid),
        .e_ready(rsp_ready)
    );

    // Internal wires between top-level WB and core WB
//    wire [ADDR_WIDTH-1:0]  iadr;
//    wire [DATA_WIDTH-1:0]  idat_w;
//    wire [DATA_WIDTH-1:0]  idat_r_w = dat_r;
//    wire                    icyc;
//    wire                    ierr = err;
//    wire [DATA_WIDTH/8-1:0] isel;
//    wire                    istb;
//    wire                    iack = ack;
//    wire                    iwe;

    // Drive top-level WB signals from core wires
//    assign adr   = iadr;
//    assign dat_w = idat_w;
//    assign cyc   = icyc;
//    assign we    = iwe;
//    assign sel   = isel;            // 1-bit strobe exposed as 'sel' for legacy TB
//    assign stb   = istb;            // byte enables exposed as 'stb' vector for legacy TB

    // Core transactor
    fwvip_wb_initiator_core #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .REQ_WIDTH(REQ_WIDTH),
        .RSP_WIDTH(RSP_WIDTH)
    ) core (
        .clock(clock),
        .reset(reset),
        // Wishbone initiator port
        .iadr(adr),
        .idat_w(dat_w),
        .idat_r(dat_r),
        .icyc(cyc),
        .ierr(err),
        .isel(sel),
        .istb(stb),
        .iack(ack),
        .iwe(we),
        // RV request/response
        .req_dat(req_dat),
        .req_valid(req_valid),
        .req_ready(req_ready),
        .rsp_dat(rsp_dat),
        .rsp_valid(rsp_valid),
        .rsp_ready(rsp_ready)
    );

    // --------------------------------------------------------------------
    // Helper tasks to preserve existing API behavior
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

    // Wait for reset deassertion and a clock edge
    task wait_reset();
        if (reset) @(negedge reset);
        @(posedge clock);
    endtask

    task request(
        input[ADDR_WIDTH_MAX-1:0]       adr,
        input[DATA_WIDTH_MAX-1:0]       dat,
        input[(DATA_WIDTH_MAX/8)-1:0]   sel,
        input                           we);
        req_s r;
        r = '{adr: adr, dat: dat, we: we, stb: sel};
        req_fifo.put(r);
    endtask

    task response(
        output[ADDR_WIDTH_MAX-1:0]      dat,
        output                          err);
        rsp_s r;
        rsp_fifo.get(r);
        dat = r.dat;
        err = r.err;
    endtask

    // Queue a Wishbone request (classic)
    task queue_req(
        input [ADDR_WIDTH-1:0]      adr,
        input [DATA_WIDTH-1:0]      dat,
        input [DATA_WIDTH/8-1:0]    stb,
        input                       we
    );
        req_s r;
        r = '{adr: adr, dat: dat, we: we, stb: stb};
        req_fifo.put(r);
    endtask

    // Wait for response
    task wait_ack(
        output [DATA_WIDTH-1:0]     dat_r,
        output                      err
    );
        rsp_s r;
        rsp_fifo.get(r);
        dat_r = r.dat;
        err   = r.err;
    endtask

`fwvip_bfm_t_end
