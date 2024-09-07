
module initiator_tb;
    import svt_pkg::*;
    import initiator_test_pkg::*;
    import fwvip_wb_pkg::*;

typedef virtual fwvip_wb_initiator #(32,32) vif_t;
reg clk = 0;
reg rst = 1;

initial begin
    forever begin
        #10ns;
        clk <= ~clk;
    end
end

initial begin
    #100ns;
    rst <= 0;
end
    wire[31:0]      adr;
    wire[31:0]      dat_w;
    reg[31:0]       dat_r;
    wire            we;
    wire            sel;
    wire[3:0]       stb;
    reg             ack;
    wire            cyc;
    reg             state;
    reg[31:0]       data;

    fwvip_wb_initiator initiator(
        .clock(clk),
        .reset(rst),
        .adr(adr),
        .dat_w(dat_w),
        .dat_r(dat_r),
        .we(we),
        .sel(sel),
        .stb(stb),
        .ack(ack),
        .cyc(cyc)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= 1'b0;
            ack <= 1'b0;
        end else begin
            case (state) 
                1'b0: begin
                    if (cyc && sel) begin
                        state <= 1'b1;
                        ack <= 1'b1;
                        if (we) begin
                            for (int i=0; i<4; i++) begin
                                if (stb[i]) begin
                                    data[8*i+:8] <= dat_w[8*i+:8];
                                end
                            end
                        end
                    end
                end
                1'b1: begin
                    ack <= 1'b0;
                    state <= 1'b0;
                    dat_r <= data;
                end
            endcase
        end
    end

initial begin
    $display("Hello World");
    $display("Path: %0s", initiator.path());
    if ($test$plusargs("debug")) begin
        $dumpfile("dump.vcd");
        $dumpvars(0);
    end
//    fwvip_wb_initiator_api_p #(vif_t, 32,32)::register(null);
    svt_runtest();
    $finish;
end

initial begin
    automatic fwvip_wb_initiator_api_p #(vif_t, 32,32) api;
    api = new(initiator, initiator.path());
    fwvip_wb_initiator_rgy.register(api);
end


endmodule



