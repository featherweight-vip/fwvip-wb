`include "wishbone_macros.svh"

module fwvip_wb_transactor_b2b;

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

`ifdef TRACE_EN
  initial begin
    $dumpfile("sim.vcd");
    $dumpvars;
  end
`endif

  localparam int ADDR_WIDTH = 32;
  localparam int DATA_WIDTH = 32;

  // Wishbone wires between initiator and target
  wire [ADDR_WIDTH-1:0]     adr;
  wire [DATA_WIDTH-1:0]     dat_w;
  wire [DATA_WIDTH-1:0]     dat_r;
  wire                      cyc;
  wire                      err;
  wire [DATA_WIDTH/8-1:0]   stb;
  wire                      ack;
  wire                      we;
  wire                      sel; // initiator strobe bit

  // Instantiate Initiator transactor BFM
  fwvip_wb_initiator #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
  ) u_init (
    .clock(clock),
    .reset(reset),
    .adr(adr),
    .dat_w(dat_w),
    .dat_r(dat_r),
    .we(we),
    .sel(sel),
    .stb(stb),
    .ack(ack),
    .err(err),
    .cyc(cyc)
  );

  // Instantiate Target transactor BFM
  fwvip_wb_target #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
  ) u_targ (
    .clock(clock),
    .reset(reset),
    .tadr(adr),
    .tdat_w(dat_w),
    .tdat_r(dat_r),
    .tcyc(cyc),
    .terr(err),
    .tsel(stb),   // initiator's byte-enables to target SEL
    .tstb(sel),   // initiator's strobe to target STB
    .tack(ack),
    .twe(we)
  );

  // Pack/Unpack helper functions
  function automatic [ADDR_WIDTH+DATA_WIDTH+(DATA_WIDTH/8)+1-1:0] pack_req(
      input [ADDR_WIDTH-1:0]     f_adr,
      input [DATA_WIDTH-1:0]     f_dat,
      input [DATA_WIDTH/8-1:0]   f_stb,
      input                      f_we
  );
    pack_req = {f_adr, f_dat, f_stb, f_we};
  endfunction

  function automatic [DATA_WIDTH+1-1:0] pack_rsp(
      input [DATA_WIDTH-1:0]     f_dat,
      input                      f_err
  );
    pack_rsp = {f_dat, f_err};
  endfunction

  task automatic unpack_req(
      input [ADDR_WIDTH+DATA_WIDTH+(DATA_WIDTH/8)+1-1:0] v,
      output [ADDR_WIDTH-1:0]     f_adr,
      output [DATA_WIDTH-1:0]     f_dat,
      output [DATA_WIDTH/8-1:0]   f_stb,
      output                      f_we
  );
    {f_adr, f_dat, f_stb, f_we} = v;
  endtask

  task automatic unpack_rsp(
      input [DATA_WIDTH+1-1:0] v,
      output [DATA_WIDTH-1:0] f_dat,
      output                  f_err
  );
    {f_dat, f_err} = v;
  endtask

  // Safety timeout
  initial begin : timeout
    #100000ns;
    $display("[TB] TIMEOUT -- ending simulation");
    $finish;
  end

  // Test sequence using FIFO put/get tasks inside transactors
  // Extended to perform multiple transactions to ensure ACK activity
  integer ack_cnt;
  always @(posedge clock) begin
    if (ack) ack_cnt++;
  end
  initial begin : test_seq
    reg [ADDR_WIDTH+DATA_WIDTH+(DATA_WIDTH/8)+1-1:0] req_v;
    reg [ADDR_WIDTH+DATA_WIDTH+(DATA_WIDTH/8)+1-1:0] targ_req_v;
    reg [DATA_WIDTH+1-1:0]                           rsp_v;
    reg [DATA_WIDTH+1-1:0]                           init_rsp_v;
    reg [ADDR_WIDTH-1:0]                              adr_f;
    reg [DATA_WIDTH-1:0]                              dat_f;
    reg [DATA_WIDTH/8-1:0]                            stb_f;
    reg                                               we_f;
    reg                                               err_f;
    reg [DATA_WIDTH-1:0]                              exp_mem [0:5];
    int i;
    ack_cnt = 0;

    // Wait for reset to deassert
    @(negedge reset);
    @(posedge clock);

    // 3 write transactions
    for (i=0;i<3;i++) begin
      req_v = pack_req(32'h1000_0000 + (i*4), 32'hA5A5_0000 + i, {DATA_WIDTH/8{1'b1}}, 1'b1);
      u_init.req_fifo.put(req_v);
      u_targ.req_fifo.get(targ_req_v);
      unpack_req(targ_req_v, adr_f, dat_f, stb_f, we_f);
      $display("[TB] Target observed WRITE %0d: adr=%h dat=%h", i, adr_f, dat_f);
      exp_mem[i] = dat_f;
      rsp_v = pack_rsp(32'hDEAD_BEEF, 1'b0);
      u_targ.rsp_fifo.put(rsp_v);
      u_init.rsp_fifo.get(init_rsp_v);
      unpack_rsp(init_rsp_v, dat_f, err_f);
      if (err_f !== 1'b0) begin
        $error("[TB] Write response err expected 0, got %0d", err_f);
        $finish; 
      end
    end

    // 3 read transactions
    for (i=0;i<3;i++) begin
      req_v = pack_req(32'h1000_0000 + (i*4), '0, {DATA_WIDTH/8{1'b1}}, 1'b0);
      u_init.req_fifo.put(req_v);
      u_targ.req_fifo.get(targ_req_v);
      unpack_req(targ_req_v, adr_f, dat_f, stb_f, we_f);
      $display("[TB] Target observed READ %0d: adr=%h", i, adr_f);
      if (we_f !== 1'b0) begin
        $error("[TB] Expected read (we=0)");
        $finish;
      end
      rsp_v = pack_rsp(exp_mem[i], 1'b0);
      u_targ.rsp_fifo.put(rsp_v);
      u_init.rsp_fifo.get(init_rsp_v);
      unpack_rsp(init_rsp_v, dat_f, err_f);
      if (err_f !== 1'b0) begin
        $error("[TB] Read response err expected 0");
        $finish; 
      end
      if (dat_f !== exp_mem[i]) begin
        $error("[TB] Read data mismatch exp=%h got=%h", exp_mem[i], dat_f);
        $finish;
      end
    end

    if (ack_cnt < 6) begin
      $error("[TB] Expected >=6 ACK pulses, got %0d", ack_cnt);
    end else begin
      $display("[TB] Observed %0d ACK pulses", ack_cnt);
    end

    $display("[TB] Test PASSED");
    $finish;
  end

endmodule
