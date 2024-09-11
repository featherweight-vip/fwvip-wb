
`include "fwvip_macros.svh"

`fwvip_bfm_t fwvip_wb_initiator #(
        parameter ADDR_WIDTH = 32,
        parameter DATA_WIDTH = 32
    ) (
        input                           clock,
        input                           reset,
        output reg [ADDR_WIDTH-1:0]     adr,
        output reg [DATA_WIDTH-1:0]     dat_w,
        input [DATA_WIDTH-1:0]          dat_r,
        output reg                      we,
        output reg                      sel,
        output reg[DATA_WIDTH/8-1:0]    stb,
        input                           ack,
        input                           err,
        output reg                      cyc
    );

    reg[1:0]                state;
    reg[DATA_WIDTH-1:0]     dat_w_r;

    reg[ADDR_WIDTH-1:0]     adr_q;
    reg[DATA_WIDTH-1:0]     dat_w_q;
    reg[DATA_WIDTH-1:0]     dat_r_q;
    reg[DATA_WIDTH/8-1:0]   stb_q;
    reg                     we_q;
    reg                     req_q;
    reg                     ack_q;
    reg                     err_q;

    reg                     in_reset;
    reg                     have_reset;

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            state <= {2{1'b0}};
            dat_w_r <= {DATA_WIDTH{1'b0}};
            req_q = 0;
            ack_q = 0;
            in_reset <= 1'b1;
            have_reset <= 1'b0;
            cyc <= 1'b0;
            sel <= 1'b0;
            we <= 1'b0;
            state <= 2'b00;
        end else begin
            if (in_reset) begin
                have_reset <= 1'b1;
                in_reset <= 1'b0;
            end
            case (state) 
                2'b00: begin
                    if (req_q) begin
                        adr <= adr_q;
                        dat_w <= dat_w_q;
                        cyc <= 1'b1;
                        sel <= 1'b1;
                        stb <= stb_q;
                        we <= we_q;
                        req_q = 0;
                        state <= 2'b01;
                    end
                end
                2'b01: begin
                    if (ack) begin
                        state <= 2'b00;
                        ack_q = 1;
                        err_q = err;
                        dat_r_q = dat_r;
                        cyc <= 1'b0;
                        sel <= 1'b0;
                    end
                end
                2'b10: begin
                end
                2'b11: begin
                end
            endcase
        end
    end

    task wait_reset();
        $display("%0t: --> wait_reset", $time);
        while (have_reset !== 1'b1) begin
            $display("%0t: -- wait_reset %0d", $time, have_reset);
            @(posedge clock);
        end
        $display("%0t: <-- wait_reset", $time);
    endtask

    task queue_req(
        input [ADDR_WIDTH-1:0]      adr,
        input [DATA_WIDTH-1:0]      dat,
        input [DATA_WIDTH/8-1:0]    stb,
        input                       we);
        while (req_q == 1'b1) begin
            @(posedge clock);
        end
        adr_q = adr;
        dat_w_q = dat;
        stb_q = stb;
        we_q = we;
        req_q = 1'b1;
        $display("queue_req");
    endtask

    task wait_ack(
        output [DATA_WIDTH-1:0]     dat_r,
        output                      err);
        while (ack_q !== 1'b1) begin
            @(posedge clock);
        end
        ack_q = 0;
        dat_r = dat_r_q;
        err = err_q;
    endtask

    `fwvip_path_decl

`fwvip_bfm_t_end
