
module initiator_tb;
    import svt_pkg::*;
    import initiator_test_pkg::*;
    import fwvip_wb_pkg::*;

typedef virtual fwvip_wb_initiator #(32,32) vif_t;
reg clk = 0;
reg rst = 1;

// Simple wires to tap for monitor
wire            mon_we;
wire            mon_cyc;
wire            mon_ack;
wire            mon_err;
wire [31:0]     mon_adr;
wire [31:0]     mon_dat_w;
wire [31:0]     mon_dat_r;
wire [3:0]      mon_stb;
wire            mon_sel;

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

    // Tap DUT signals to monitor wires
    assign mon_we    = we;
    assign mon_cyc   = cyc;
    assign mon_ack   = ack;
    assign mon_err   = 1'b0; // no error in this simple TB
    assign mon_adr   = adr;
    assign mon_dat_w = dat_w;
    assign mon_dat_r = dat_r;
    assign mon_stb   = stb;
    assign mon_sel   = sel;

    // Instantiate the monitor BFM
    fwvip_wb_monitor_if #(32,32) mon (
        .clock(clk),
        .reset(rst),
        .iadr(mon_adr),
        .idat_w(mon_dat_w),
        .idat_r(mon_dat_r),
        .iwe(mon_we),
        .istb(mon_stb),
        .isel(mon_stb), // map byte-enables to sel in monitor payload
        .iack(mon_ack),
        .ierr(mon_err),
        .icyc(mon_cyc)
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

// Simple monitor print thread to demonstrate monitor activity
initial begin
    bit [63:0]  m_dat;
    bit [63:0]  m_adr;
    bit [7:0]   m_sel;
    bit         m_we, m_err;
    mon.wait_reset();
    repeat (4) begin
        mon.wait_txn(m_adr, m_dat, m_sel, m_we, m_err);
        $display("[TB-MON] adr=0x%08x we=%0b dat=0x%08x sel=0x%0h err=%0b", m_adr[31:0], m_we, m_dat[31:0], m_sel[3:0], m_err);
    end
end

initial begin
    automatic fwvip_wb_initiator_api_p #(vif_t, 32,32) api;
    api = new(initiator, initiator.path());
    fwvip_wb_initiator_rgy.register(api);
end


endmodule



