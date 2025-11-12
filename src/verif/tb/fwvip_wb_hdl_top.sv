`include "wishbone_macros.svh"

module fwvip_wb_hdl_top;
  import uvm_pkg::*;
  import fwvip_wb_pkg::*;

  // Clock / Reset
  logic clock = 1'b0;
  logic reset = 1'b1;

  // 100MHz clock (10ns period)
  always #5 clock = ~clock;

  // Deassert reset after a few cycles
  initial begin
    reset = 1'b1;
    repeat (5) @(posedge clock);
    reset = 1'b0;
  end

  localparam int ADDR_WIDTH = 32;
  localparam int DATA_WIDTH = 32;

  // Wishbone bus wires bundle
  `WB_WIRES( wb_, ADDR_WIDTH, DATA_WIDTH);

  // Initiator core interface instance
  fwvip_wb_initiator_if #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
    ) u_initiator (
    .clock(clock),
    .reset(reset),
    `WB_CONNECT( , wb_)
  );

  // Target core interface instance
  fwvip_wb_target_if #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
    ) u_target (
    .clock(clock),
    .reset(reset),
    `WB_CONNECT(t, wb_)
  );

  initial begin
    virtual fwvip_wb_initiator_if #(32,32) vif;
    vif = u_initiator;
//    fwvip_wb_config_p #(32,32)::set(u_initiator);
  end

endmodule
