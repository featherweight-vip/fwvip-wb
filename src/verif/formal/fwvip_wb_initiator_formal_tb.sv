`include "wishbone_macros.svh"
`include "rv_macros.svh"

// Formal testbench: Initiator core + Wishbone checker
module fwvip_wb_initiator_formal_tb(
    input clock,
    input reset
);
    parameter ADDR_WIDTH = 32;
    parameter DATA_WIDTH = 32;

    initial assume(reset);

//    typedef fwvip_wb_initiator_core #(ADDR_WIDTH, DATA_WIDTH) if_t;
    // ::req_s req_s;

    // Clock/reset
//    logic clock = 0;
//    logic reset = 1;
    //always #1 clock = ~clock; // 500MHz nominal (time unit unspecified)
    // initial begin
    //     repeat (4) @(posedge clock);
    //     reset = 0;
    // end

    // Wishbone bus wires (initiator side)
    logic [ADDR_WIDTH-1:0]    iadr;
    logic [DATA_WIDTH-1:0]    idat_w;
    logic [DATA_WIDTH-1:0]    idat_r;
    logic                     iwe;
    logic                     istb;
    logic [DATA_WIDTH/8-1:0]  isel;
    logic                     iack;
    logic                     ierr;
    logic                     icyc;

    // RV request/response channel wires for core (widths per core parameters)
    localparam int REQ_WIDTH = (DATA_WIDTH+ADDR_WIDTH+(DATA_WIDTH/8)+1);
    localparam int RSP_WIDTH = (DATA_WIDTH+1);
    logic [REQ_WIDTH-1:0]  req_dat;
    logic                  req_valid;
    logic                  req_ready;
    logic [RSP_WIDTH-1:0]  rsp_dat;
    logic                  rsp_valid;
    logic                  rsp_ready;

    // Simple ready/valid modeling: always ready, accept single request, respond next cycle
//    assign req_ready = 1'b1;
    assign rsp_ready = 1'b1;
    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            rsp_valid <= 0;
            rsp_dat   <= '0;
        end else begin
            rsp_valid <= 0;
            if (req_valid && req_ready) begin
                // Echo write data (packed vector: adr, dat, stb, we) => slice dat
                // For simplicity just return zeros
                rsp_dat <= '0; // {dat_r, err}
                rsp_valid <= 1'b1;
            end
        end
    end

    // Instantiate initiator core
    fwvip_wb_initiator_core #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_init (
        .clock(clock),
        .reset(reset),
        // Wishbone
        .iadr(iadr),
        .idat_w(idat_w),
        .idat_r(idat_r),
        .iwe(iwe),
        .istb(istb),
        .isel(isel),
        .iack(iack),
        .ierr(ierr),
        .icyc(icyc),
        // RV req (target port)
        .req_dat(req_dat),
        .req_valid(req_valid),
        .req_ready(req_ready),
        // RV rsp (initiator port)
        .rsp_dat(rsp_dat),
        .rsp_valid(rsp_valid),
        .rsp_ready(rsp_ready)
    );

    typedef struct packed {
        bit[ADDR_WIDTH-1:0]     adr;
        bit[DATA_WIDTH-1:0]     dat;
        bit                     we;
        bit[(DATA_WIDTH/8)-1:0] stb;
    } req_s;

    // Simple target model: immediate ACK next cycle, no errors, return constant read data
    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            iack    <= 0;
            ierr    <= 0;
            idat_r  <= '0;
        end else begin
            iack   <= 0;
            if (icyc && istb) begin
                iack   <= 1'b1; // one-cycle termination
                idat_r <= '0;   // constant data
            end
            ierr <= 1'b0;
        end
    end

    always @* begin
        if (!reset && icyc && istb) assume(iadr != 0);
    end

    reg[7:0] rcount;
    reg[7:0] wcount;
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            rcount <= '0;
            wcount <= '0;
        end else begin
            if (icyc && istb && iack) begin
                if (iwe) begin
                    wcount <= wcount + 1;
                end else begin
                    rcount <= rcount + 1;
                end
            end
            cover(rcount == 2 && wcount == 5);
        end
    end

    // Instantiate checker (monitoring initiator bus signals)
    fwvip_wb_checkers #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .MAX_CYCLE_LEN(2)
    ) u_chk (
        .clock(clock),
        .reset(reset),
        .madr(iadr),
        .mdat_w(idat_w),
        .mdat_r(idat_r),
        .mwe(iwe),
        .mstb(istb),
        .msel(isel),
        .mack(iack),
        .merr(ierr),
        .mcyc(icyc)
    );
endmodule
