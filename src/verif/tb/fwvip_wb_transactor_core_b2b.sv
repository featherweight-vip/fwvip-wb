`include "wishbone_macros.svh"
`include "rv_macros.svh"
`include "fwvip_macros.svh"

module fwvip_wb_transactor_core_b2b;

  // ------------------------------------------------------------------------
  // Clock / Reset
  // ------------------------------------------------------------------------
  logic clock = 1'b0;
  logic reset = 1'b1;

  // 100MHz clock (10ns period)
  always #5 clock = ~clock;

  initial begin
    reset = 1'b1;
    repeat (5) @(posedge clock);
    reset = 1'b0;
  end

`ifdef TRACE_EN
  initial begin
    $dumpfile("sim.vcd");
    $dumpvars;
  end
`endif

  // ------------------------------------------------------------------------
  // Parameters
  // ------------------------------------------------------------------------
  localparam int ADDR_WIDTH = 32;
  localparam int DATA_WIDTH = 32;
  localparam int REQ_WIDTH  = (DATA_WIDTH + ADDR_WIDTH + (DATA_WIDTH/8) + 1);
  localparam int RSP_WIDTH  = (DATA_WIDTH + 1);

  // ------------------------------------------------------------------------
  // Wishbone Bus Wires (point-to-point between initiator/target cores)
  // ------------------------------------------------------------------------
  `WB_WIRES(wb_, ADDR_WIDTH, DATA_WIDTH);

  // ------------------------------------------------------------------------
  // RV Channel Signals
  // ------------------------------------------------------------------------
  // Initiator driver/request channel
  logic [REQ_WIDTH-1:0]  init_req_dat;
  logic                  init_req_valid;
  wire                   init_req_ready;
  // Initiator response channel
  wire  [RSP_WIDTH-1:0]  init_rsp_dat;
  wire                   init_rsp_valid;
  logic                  init_rsp_ready;

  // Target produced request channel (observe)
  wire [REQ_WIDTH-1:0]   tgt_req_dat;
  wire                   tgt_req_valid;
  logic                  tgt_req_ready;
  // Target response channel (we drive)
  logic [RSP_WIDTH-1:0]  tgt_rsp_dat;
  logic                  tgt_rsp_valid;
  wire                   tgt_rsp_ready;

  // ------------------------------------------------------------------------
  // Instantiate Initiator Core
  // ------------------------------------------------------------------------
  fwvip_wb_initiator_core #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
  ) u_initiator (
    .clock(clock),
    .reset(reset),
    `WB_CONNECT(i, wb_),
    `RV_CONNECT(req_, init_req_),
    `RV_CONNECT(rsp_, init_rsp_)
  );

  // ------------------------------------------------------------------------
  // Instantiate Target Core
  // ------------------------------------------------------------------------
  fwvip_wb_target_core #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
  ) u_target (
    .clock(clock),
    .reset(reset),
    `WB_CONNECT(t, wb_),
    `RV_CONNECT(req_, tgt_req_),
    `RV_CONNECT(rsp_, tgt_rsp_)
  );

  // ------------------------------------------------------------------------
  // RV Request/Response Structs (match core implementations)
  // REQ layout: { adr, dat, stb(byte-enables), we }
  // RSP layout: { dat, err }
  // ------------------------------------------------------------------------
  typedef struct packed {
    bit [ADDR_WIDTH-1:0]      adr;
    bit [DATA_WIDTH-1:0]      dat;
    bit                       we;
    bit [(DATA_WIDTH/8)-1:0]  stb;
  } req_s;

  typedef struct packed {
    bit [DATA_WIDTH-1:0]      dat;
    bit                       err;
  } rsp_s;

  // Temps for struct views (used by driver/responder)
  rsp_s           init_rsp_tmp;
  req_s           tgt_req_tmp;
  rsp_s           tgt_rsp_tmp;
  int unsigned    tgt_idx;

  // ------------------------------------------------------------------------
  // Initiator-Side RV Driver (drives init_req_* ; consumes init_rsp_*)
  // Directions:
  //   init_req_dat/valid -> core, init_req_ready <- core
  //   init_rsp_dat/valid <- core, init_rsp_ready -> core
  // ------------------------------------------------------------------------
  // Always ready to accept responses
  assign init_rsp_ready = 1'b1;

  // Stimulus sequence
  localparam int N_REQ = 6;
  req_s req_vec   [N_REQ];
  int   req_idx;
  int   rsp_cnt;

  // Create test sequence (3 writes then 3 reads)
  initial begin
    // Writes
    req_vec[0].adr = 32'h0000_0000; req_vec[0].dat = 32'hA5A5_0000; req_vec[0].we = 1'b1; req_vec[0].stb = {(DATA_WIDTH/8){1'b1}};
    req_vec[1].adr = 32'h0000_0004; req_vec[1].dat = 32'h5A5A_1111; req_vec[1].we = 1'b1; req_vec[1].stb = {(DATA_WIDTH/8){1'b1}};
    req_vec[2].adr = 32'h0000_0008; req_vec[2].dat = 32'hDEAD_BEEF; req_vec[2].we = 1'b1; req_vec[2].stb = {(DATA_WIDTH/8){1'b1}};
    // Reads
    req_vec[3].adr = 32'h0000_0000; req_vec[3].dat = '0; req_vec[3].we = 1'b0; req_vec[3].stb = {(DATA_WIDTH/8){1'b1}};
    req_vec[4].adr = 32'h0000_0004; req_vec[4].dat = '0; req_vec[4].we = 1'b0; req_vec[4].stb = {(DATA_WIDTH/8){1'b1}};
    req_vec[5].adr = 32'h0000_0008; req_vec[5].dat = '0; req_vec[5].we = 1'b0; req_vec[5].stb = {(DATA_WIDTH/8){1'b1}};
  end

  // Pack/unpack helpers
  function automatic [REQ_WIDTH-1:0] pack_req(req_s r);
    return r;
  endfunction

  function automatic rsp_s unpack_rsp(input [RSP_WIDTH-1:0] v);
    return rsp_s'(v);
  endfunction

  // Driver FSM
  typedef enum logic [1:0] { D_IDLE, D_WAIT_RSP, D_DONE } dstate_e;
  dstate_e dstate;

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      dstate         <= D_IDLE;
      init_req_valid <= 1'b0;
      init_req_dat   <= '0;
      req_idx        <= 0;
      rsp_cnt        <= 0;
    end else begin
      case (dstate)
        D_IDLE: begin
          if (!init_req_valid && req_idx < N_REQ) begin
            init_req_dat   <= pack_req(req_vec[req_idx]);
            init_req_valid <= 1'b1;
          end
          if (init_req_valid && init_req_ready) begin
            init_req_valid <= 1'b0;
            dstate         <= D_WAIT_RSP;
          end
        end
        D_WAIT_RSP: begin
          if (init_rsp_valid) begin
            init_rsp_tmp = init_rsp_dat;
            $display("[%0t] RSP %0d: err=%0b dat=0x%08x", $time, rsp_cnt, init_rsp_tmp.err, init_rsp_tmp.dat);
            rsp_cnt <= rsp_cnt + 1;
            if (rsp_cnt + 1 == N_REQ) begin
              dstate <= D_DONE;
            end else begin
              req_idx <= req_idx + 1;
              dstate  <= D_IDLE;
            end
          end
        end
        D_DONE: begin
          if ($time > 1000) begin
            $display("[%0t] Test Completed (%0d responses)", $time, rsp_cnt);
            $finish;
          end
        end
        default: dstate <= D_IDLE;
      endcase
    end
  end

  // ------------------------------------------------------------------------
  // Target-Side RV Responder
  // tgt_req_dat/valid from core (we observe), tgt_req_ready from TB
  // tgt_rsp_dat/valid from TB, tgt_rsp_ready from core
  // ------------------------------------------------------------------------
  // Always ready to accept target's produced request
  assign tgt_req_ready = 1'b1;

  // Simple memory
  reg [DATA_WIDTH-1:0] mem [0:255];

  // Unpack request / pack response
  function automatic req_s unpack_req(input [REQ_WIDTH-1:0] v);
    return req_s'(v);
  endfunction

  function automatic [RSP_WIDTH-1:0] pack_rsp(rsp_s r);
    return r;
  endfunction

  typedef enum logic [1:0] { R_IDLE, R_WAIT_CONS } rstate_e;
  rstate_e rstate;

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      rstate        <= R_IDLE;
      tgt_rsp_valid <= 1'b0;
      tgt_rsp_dat   <= '0;
    end else begin
      case (rstate)
        R_IDLE: begin
          tgt_rsp_valid <= 1'b0;
          if (tgt_req_valid && tgt_req_ready) begin
            tgt_req_tmp    = tgt_req_dat;
            tgt_rsp_tmp.err= 1'b0;
            tgt_idx        = tgt_req_tmp.adr[9:2]; // word index
            if (tgt_req_tmp.we) begin
              mem[tgt_idx]    = tgt_req_tmp.dat;
              tgt_rsp_tmp.dat = tgt_req_tmp.dat;
            end else begin
              tgt_rsp_tmp.dat = mem[tgt_idx];
            end
            tgt_rsp_dat   <= tgt_rsp_tmp;
            tgt_rsp_valid <= 1'b1;
            rstate        <= R_WAIT_CONS;
          end
        end
        R_WAIT_CONS: begin
          if (tgt_rsp_valid && tgt_rsp_ready) begin
            tgt_rsp_valid <= 1'b0;
            rstate        <= R_IDLE;
          end
        end
        default: rstate <= R_IDLE;
      endcase
    end
  end

endmodule
