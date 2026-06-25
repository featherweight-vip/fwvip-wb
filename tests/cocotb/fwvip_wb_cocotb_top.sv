`timescale 1ns/1ps
// ----------------------------------------------------------------------------
// Cocotb top-level: initiator-core <-> target-core back-to-back, with a
// passive monitor-core observing the shared Wishbone bus.
//
// clock/reset are driven by cocotb at the top level. The ready/valid ("FIFO")
// ports of each core are driven/sampled by the cocotb VIP backends *through the
// core instance handles* (e.g. dut.u_initiator.req_dat), so they are left as
// plain wires here -- every FIFO net has exactly one driver (a core output or
// cocotb). The shared Wishbone bus is wired core-to-core.
// ----------------------------------------------------------------------------
module fwvip_wb_cocotb_top;

  localparam int ADDR_WIDTH = 32;
  localparam int DATA_WIDTH = 32;
  localparam int REQ_WIDTH  = (ADDR_WIDTH + DATA_WIDTH + (DATA_WIDTH/8) + 1); // 69
  localparam int RSP_WIDTH  = (DATA_WIDTH + 1);                              // 33
  localparam int MON_WIDTH  = (ADDR_WIDTH + DATA_WIDTH + (DATA_WIDTH/8) + 1 + 1); // 70

  // Clock / reset (driven by cocotb)
  reg clock = 1'b0;
  reg reset = 1'b1;

  // Shared Wishbone bus (initiator master <-> target slave); cores drive these
  wire [ADDR_WIDTH-1:0]    wb_adr;
  wire [DATA_WIDTH-1:0]    wb_dat_w;
  wire [DATA_WIDTH-1:0]    wb_dat_r;
  wire                     wb_cyc;
  wire                     wb_err;
  wire [DATA_WIDTH/8-1:0]  wb_sel;
  wire                     wb_stb;
  wire                     wb_ack;
  wire                     wb_we;

  // FIFO-side nets (driven/sampled by cocotb via the core handles)
  wire [REQ_WIDTH-1:0]     init_req_dat;
  wire                     init_req_valid;
  wire                     init_req_ready;
  wire [RSP_WIDTH-1:0]     init_rsp_dat;
  wire                     init_rsp_valid;
  wire                     init_rsp_ready;

  wire [REQ_WIDTH-1:0]     tgt_req_dat;
  wire                     tgt_req_valid;
  wire                     tgt_req_ready;
  wire [RSP_WIDTH-1:0]     tgt_rsp_dat;
  wire                     tgt_rsp_valid;
  wire                     tgt_rsp_ready;

  wire [MON_WIDTH-1:0]     mon_dat;
  wire                     mon_valid;
  wire                     mon_ready;

  // --------------------------------------------------------------------------
  // Initiator core
  // --------------------------------------------------------------------------
  fwvip_wb_initiator_xtor_core #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
  ) u_initiator (
    .clock     (clock),
    .reset     (reset),
    .adr       (wb_adr),
    .dat_w     (wb_dat_w),
    .dat_r     (wb_dat_r),
    .cyc       (wb_cyc),
    .err       (wb_err),
    .sel       (wb_sel),
    .stb       (wb_stb),
    .ack       (wb_ack),
    .we        (wb_we),
    .req_dat   (init_req_dat),
    .req_valid (init_req_valid),
    .req_ready (init_req_ready),
    .rsp_dat   (init_rsp_dat),
    .rsp_valid (init_rsp_valid),
    .rsp_ready (init_rsp_ready)
  );

  // --------------------------------------------------------------------------
  // Target core
  // --------------------------------------------------------------------------
  fwvip_wb_target_xtor_core #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
  ) u_target (
    .clock     (clock),
    .reset     (reset),
    .adr       (wb_adr),
    .dat_w     (wb_dat_w),
    .dat_r     (wb_dat_r),
    .cyc       (wb_cyc),
    .err       (wb_err),
    .sel       (wb_sel),
    .stb       (wb_stb),
    .ack       (wb_ack),
    .we        (wb_we),
    .req_dat   (tgt_req_dat),
    .req_valid (tgt_req_valid),
    .req_ready (tgt_req_ready),
    .rsp_dat   (tgt_rsp_dat),
    .rsp_valid (tgt_rsp_valid),
    .rsp_ready (tgt_rsp_ready)
  );

  // --------------------------------------------------------------------------
  // Monitor core (passive)
  // --------------------------------------------------------------------------
  fwvip_wb_monitor_xtor_core #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
  ) u_monitor (
    .clock     (clock),
    .reset     (reset),
    .adr       (wb_adr),
    .dat_w     (wb_dat_w),
    .dat_r     (wb_dat_r),
    .cyc       (wb_cyc),
    .err       (wb_err),
    .sel       (wb_sel),
    .stb       (wb_stb),
    .ack       (wb_ack),
    .we        (wb_we),
    .mon_dat   (mon_dat),
    .mon_valid (mon_valid),
    .mon_ready (mon_ready)
  );

`ifdef TRACE_EN
  initial begin
    $dumpfile("sim.vcd");
    $dumpvars(0, fwvip_wb_cocotb_top);
  end
`endif

endmodule
