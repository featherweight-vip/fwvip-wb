`timescale 1ns/1ps
`default_nettype none
// ----------------------------------------------------------------------------
// Cocotb top-level: initiator-core <-> target-core back-to-back, with a passive
// monitor-core observing the shared Wishbone bus.
//
// The cocotb-DRIVEN ready/valid inputs of each core are exposed as TOP-LEVEL
// signals (init_*/tgt_*/mon_*) so the cocotb backends can drive them on both
// simulators. (Icarus honours cocotb writes to a sub-instance's input ports;
// vlt does not -- it recomputes them each eval.) Core OUTPUTS stay wires the
// backends sample. The backends bind to these via a per-role prefix:
// CocotbInitiatorBackend(dut, "init_"), ...(dut, "tgt_"), ...(dut, "mon_").
// ----------------------------------------------------------------------------
module fwvip_wb_cocotb_top;

  localparam int ADDR_WIDTH = 32;
  localparam int DATA_WIDTH = 32;
  localparam int REQ_WIDTH  = (ADDR_WIDTH + DATA_WIDTH + (DATA_WIDTH/8) + 1); // 69
  localparam int RSP_WIDTH  = (DATA_WIDTH + 1);                              // 33
  localparam int MON_WIDTH  = (ADDR_WIDTH + DATA_WIDTH + (DATA_WIDTH/8) + 1 + 1); // 70

  // Clock / reset (driven by cocotb)
  logic clock = 1'b0;
  logic reset = 1'b1;

  // Shared Wishbone bus (cores drive these)
  wire [ADDR_WIDTH-1:0]    wb_adr;
  wire [DATA_WIDTH-1:0]    wb_dat_w;
  wire [DATA_WIDTH-1:0]    wb_dat_r;
  wire                     wb_cyc;
  wire                     wb_err;
  wire [DATA_WIDTH/8-1:0]  wb_sel;
  wire                     wb_stb;
  wire                     wb_ack;
  wire                     wb_we;

  // Initiator: cocotb drives req_dat/req_valid + rsp_ready; samples req_ready, rsp_*
  logic [REQ_WIDTH-1:0]    init_req_dat   = '0;
  logic                    init_req_valid = 1'b0;
  wire                     init_req_ready;
  wire  [RSP_WIDTH-1:0]    init_rsp_dat;
  wire                     init_rsp_valid;
  logic                    init_rsp_ready = 1'b1;

  // Target: cocotb drives req_ready + rsp_dat/rsp_valid; samples req_*, rsp_ready
  wire  [REQ_WIDTH-1:0]    tgt_req_dat;
  wire                     tgt_req_valid;
  logic                    tgt_req_ready  = 1'b1;
  logic [RSP_WIDTH-1:0]    tgt_rsp_dat    = '0;
  logic                    tgt_rsp_valid  = 1'b0;
  wire                     tgt_rsp_ready;

  // Monitor: cocotb drives mon_ready; samples mon_dat/mon_valid
  wire  [MON_WIDTH-1:0]    mon_dat;
  wire                     mon_valid;
  logic                    mon_ready      = 1'b1;

  wb_initiator_xtor_core #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH)) u_initiator (
    .clock(clock), .reset(reset),
    .adr(wb_adr), .dat_w(wb_dat_w), .dat_r(wb_dat_r),
    .cyc(wb_cyc), .err(wb_err), .sel(wb_sel), .stb(wb_stb), .ack(wb_ack), .we(wb_we),
    .req_dat(init_req_dat), .req_valid(init_req_valid), .req_ready(init_req_ready),
    .rsp_dat(init_rsp_dat), .rsp_valid(init_rsp_valid), .rsp_ready(init_rsp_ready));

  wb_target_xtor_core #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH)) u_target (
    .clock(clock), .reset(reset),
    .adr(wb_adr), .dat_w(wb_dat_w), .dat_r(wb_dat_r),
    .cyc(wb_cyc), .err(wb_err), .sel(wb_sel), .stb(wb_stb), .ack(wb_ack), .we(wb_we),
    .req_dat(tgt_req_dat), .req_valid(tgt_req_valid), .req_ready(tgt_req_ready),
    .rsp_dat(tgt_rsp_dat), .rsp_valid(tgt_rsp_valid), .rsp_ready(tgt_rsp_ready));

  wb_monitor_xtor_core #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH)) u_monitor (
    .clock(clock), .reset(reset),
    .adr(wb_adr), .dat_w(wb_dat_w), .dat_r(wb_dat_r),
    .cyc(wb_cyc), .err(wb_err), .sel(wb_sel), .stb(wb_stb), .ack(wb_ack), .we(wb_we),
    .mon_dat(mon_dat), .mon_valid(mon_valid), .mon_ready(mon_ready));

`ifdef TRACE_EN
  initial begin
    $dumpfile("sim.vcd");
    $dumpvars(0, fwvip_wb_cocotb_top);
  end
`endif

endmodule
`default_nettype wire
