`include "wishbone_macros.svh"
`include "rv_macros.svh"
`include "fwvip_macros.svh"

module fwvip_wb_monitor_core_tb;
  localparam int ADDR_WIDTH = 32;
  localparam int DATA_WIDTH = 32;
  localparam int MON_WIDTH  = (ADDR_WIDTH + DATA_WIDTH + (DATA_WIDTH/8) + 1 + 1);

  // Clock / Reset
  logic clock = 1'b0;
  logic reset = 1'b1;
  always #5 clock = ~clock;
  initial begin
    repeat (4) @(posedge clock);
    reset = 1'b0;
  end

  // WB wires
  `WB_WIRES(wb_, ADDR_WIDTH, DATA_WIDTH)

  // RV wires
  logic [MON_WIDTH-1:0]  mon_dat;
  logic                  mon_valid;
  logic                  mon_ready;

  // DUT
  fwvip_wb_monitor_core #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .MON_WIDTH(MON_WIDTH)
  ) dut (
    .clock(clock),
    .reset(reset),
    `WB_CONNECT(i, wb_),
    `RV_CONNECT(mon_, mon_)
  );

  // Simple source/sink
  assign wb_cyc = wb_stb; // simple single-beat
  initial begin
    mon_ready = 1'b1;
    wb_stb = 0; wb_we = 0; wb_sel = '0; wb_adr = '0; wb_dat_w = '0; wb_err = 0; wb_ack = 0;
    @(negedge reset);
    repeat (3) begin
      @(posedge clock);
      wb_adr   <= 32'h1000_0000;
      wb_dat_w <= 32'h1234_5678;
      wb_we    <= 1'b1;
      wb_sel   <= 4'hF;
      wb_stb   <= 1'b1;
      @(posedge clock);
      wb_ack   <= 1'b1;
      @(posedge clock);
      wb_ack   <= 1'b0;
      wb_stb   <= 1'b0;
      wb_we    <= 1'b0;
    end
    #100ns;
    $finish;
  end

  // Monitor prints
  always @(posedge clock) begin
    if (mon_valid && mon_ready) begin
      $display("[CORE-MON] adr=%08x we=%0b dat=%08x sel=%0h err=%0b", mon_dat[MON_WIDTH-1 -: ADDR_WIDTH], mon_dat[DATA_WIDTH+(DATA_WIDTH/8)] , mon_dat[(DATA_WIDTH/8)+1 +: DATA_WIDTH], mon_dat[1 +: (DATA_WIDTH/8)], mon_dat[0]);
    end
  end

endmodule
