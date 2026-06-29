`include "wishbone_macros.svh"

module fwvip_wb_hdl_top;
  import uvm_pkg::*;
  import fwvip_wb_pkg::*;
  import fwvip_wb_xtor_pkg::*;

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

  // Shared Wishbone bus
  `WB_WIRES(wb_, ADDR_WIDTH, DATA_WIDTH);

  // Initiator transactor (drives the bus)
  wb_initiator_xtor #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
  ) u_initiator (
    .clock(clock),
    .reset(reset),
    `WB_CONNECT( , wb_)
  );

  // Target transactor (responds on the bus)
  wb_target_xtor #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
  ) u_target (
    .clock(clock),
    .reset(reset),
    `WB_CONNECT( , wb_)
  );

  // Monitor transactor (passively observes the bus)
  wb_monitor_xtor #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
  ) u_monitor (
    .clock(clock),
    .reset(reset),
    `WB_CONNECT( , wb_)
  );

  // Core clock/reset transactors. These back the fwvip-core clock/reset config
  // providers, which the env uses for reset synchronization (replacing the old
  // fixed-delay wait_reset workaround in the initiator config).
  fwvip_clock_xtor_if u_clk_if (
    .clock (clock),
    .reset (reset)
  );

  fwvip_reset_xtor_if #(.ACTIVE(1)) u_rst_if (
    .clock (clock),
    .reset (reset)
  );

endmodule
