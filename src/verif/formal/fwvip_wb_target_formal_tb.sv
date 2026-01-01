`include "wishbone_macros.svh"
`include "rv_macros.svh"

// Formal testbench: Target core + Wishbone checker
module fwvip_wb_target_formal_tb;
    parameter ADDR_WIDTH = 32;
    parameter DATA_WIDTH = 32;

    // Clock/reset
    logic clock = 0;
    logic reset = 1;
    always #1 clock = ~clock;
    initial begin
        repeat (4) @(posedge clock);
        reset = 0;
    end

    // Wishbone bus wires (target side)
    logic [ADDR_WIDTH-1:0]    tadr;
    logic [DATA_WIDTH-1:0]    tdat_w;
    logic [DATA_WIDTH-1:0]    tdat_r;
    logic                     twe;
    logic                     tstb;
    logic [DATA_WIDTH/8-1:0]  tsel;
    logic                     tack;
    logic                     terr;
    logic                     tcyc;

    // RV request/response channel wires for core
    localparam int REQ_WIDTH = (ADDR_WIDTH + DATA_WIDTH + (DATA_WIDTH/8) + 1);
    localparam int RSP_WIDTH = (DATA_WIDTH + 1);
    logic [REQ_WIDTH-1:0] req_dat;
    logic                 req_valid;
    logic                 req_ready;
    logic [RSP_WIDTH-1:0] rsp_dat;
    logic                 rsp_valid;
    logic                 rsp_ready;

    // Simple modeling of upstream master driving Wishbone: generate single-cycle accesses
    logic [3:0] access_cnt;
    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            tcyc <= 0; tstb <= 0; twe <= 0; tadr <= '0; tdat_w <= '0; tsel <= '0; access_cnt <= 0; 
        end else begin
            // Basic pattern: issue one write then one read repeatedly
            if (!tcyc && access_cnt < 8) begin
                tcyc   <= 1'b1;
                tstb   <= 1'b1;
                twe    <= access_cnt[0]; // alternate we
                tadr   <= access_cnt; // small address space
                tdat_w <= {DATA_WIDTH{1'b0}} | access_cnt;
                tsel   <= {DATA_WIDTH/8{1'b1}};
                access_cnt <= access_cnt + 1'b1;
            end else if (tack || terr) begin
                // Terminate
                tcyc <= 1'b0; tstb <= 1'b0; twe <= 1'b0;
            end
        end
    end

    // RV channel behavior for target core
    assign req_ready = 1'b1;
    assign rsp_ready = 1'b1;
    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            req_valid <= 0; req_dat <= '0; rsp_valid <= 0; rsp_dat <= '0; tdat_r <= '0; terr <= 0; tack <= 0; 
        end else begin
            // Drive req_valid when Wishbone active and core in IDLE captured inside core, so tie low here
            // Provide response immediately when requested
            rsp_valid <= 0;
            if (req_valid && req_ready) begin
                rsp_dat   <= '0; // {dat_r, err}
                rsp_valid <= 1'b1;
            end
            // Capture core outputs tack/terr combinationally
        end
    end

    // Instantiate target core
    fwvip_wb_target_core #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_tgt (
        .clock(clock),
        .reset(reset),
        .tadr(tadr),
        .tdat_w(tdat_w),
        .tdat_r(tdat_r),
        .twe(twe),
        .tstb(tstb),
        .tsel(tsel),
        .tack(tack),
        .terr(terr),
        .tcyc(tcyc),
        .req_dat(req_dat),
        .req_valid(req_valid),
        .req_ready(req_ready),
        .rsp_dat(rsp_dat),
        .rsp_valid(rsp_valid),
        .rsp_ready(rsp_ready)
    );

    // Checker monitors target bus signals (mapped to m*)
    fwvip_wb_checkers #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_chk (
        .clock(clock),
        .reset(reset),
        .madr(tadr),
        .mdat_w(tdat_w),
        .mdat_r(tdat_r),
        .mwe(twe),
        .mstb(tstb),
        .msel(tsel),
        .mack(tack),
        .merr(terr),
        .mcyc(tcyc)
    );
endmodule
