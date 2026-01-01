
`include "wishbone_macros.svh"
`include "rv_macros.svh"
`include "fwvip_macros.svh"
`include "fwvip_wb_bfm_macros.svh"

`fwvip_bfm_t fwvip_wb_initiator_core #(
        parameter ADDR_WIDTH = 32,
        parameter DATA_WIDTH = 32,
        parameter REQ_WIDTH = (DATA_WIDTH+ADDR_WIDTH+(DATA_WIDTH/8)+1),
        parameter RSP_WIDTH = (DATA_WIDTH+1)
    ) (
        input clock,
        input reset,
        `WB_INITIATOR_PORT(i, ADDR_WIDTH, DATA_WIDTH),
        `RV_TARGET_PORT(req_, REQ_WIDTH),
        `RV_INITIATOR_PORT(rsp_, RSP_WIDTH)
    );

    typedef `FWVIP_WB_INITIATOR_REQ_S(ADDR_WIDTH, DATA_WIDTH) req_s;
    typedef `FWVIP_WB_INITIATOR_RSP_S(ADDR_WIDTH, DATA_WIDTH) rsp_s;

    // --------------------------------------------------------------------
    // Wishbone Initiator Transactor
    // Single-outstanding request:
    // Accept via req_* (RV target port), drive Wishbone, return response
    // via rsp_* (RV initiator port). New request only accepted after
    // previous response consumed.
    // --------------------------------------------------------------------

    // Unpack request vector into struct
    req_s req_u;
    always_comb begin
        req_u = req_s'(req_dat);
    end

    // Internal registers driving Wishbone outputs (ports are plain outputs)
    reg [ADDR_WIDTH-1:0]     iadr_r;
    reg [DATA_WIDTH-1:0]     idat_w_r;
    reg [DATA_WIDTH/8-1:0]   isel_r;      // Byte enables (from req_u.stb)
    reg                      istb_r;      // Strobe
    reg                      icyc_r;      // Cycle indicator
    reg                      iwe_r;       // Write enable

    assign iadr   = iadr_r;
    assign idat_w = idat_w_r;
    assign isel   = isel_r;
    assign istb   = istb_r;
    assign icyc   = icyc_r;
    assign iwe    = iwe_r;

    // Response registers
    reg [DATA_WIDTH-1:0]     dat_r_q;
    reg                      err_q;
    reg                      rsp_valid_r;

    // Pack response
//    assign rsp_dat   = rsp_s'{dat: dat_r_q, err: err_q};
    assign rsp_valid = rsp_valid_r;

    // Request ready when idle
    // (req_ready is an output from RV_TARGET_PORT)
    // Accept condition (fire)
    wire req_fire = req_valid && req_ready;
    wire rsp_fire = rsp_valid && rsp_ready;

    // Termination when ACK or ERR asserted
    wire term = iack || ierr;

    // State machine
    typedef enum logic [1:0] {
        IDLE = 2'b00,
        BUS  = 2'b01,
        RESP = 2'b10
    } state_e;

    state_e state;

    assign req_ready = (state == IDLE);

    // Sequential logic
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            state        <= IDLE;
            iadr_r       <= '0;
            idat_w_r     <= '0;
            isel_r       <= '0;
            istb_r       <= 1'b0;
            icyc_r       <= 1'b0;
            iwe_r        <= 1'b0;
            dat_r_q      <= '0;
            err_q        <= 1'b0;
            rsp_valid_r  <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    // Accept a new request
                    if (req_fire) begin
                        iadr_r      <= req_u.adr;
                        idat_w_r    <= req_u.dat;
                        isel_r      <= req_u.stb;
                        iwe_r       <= req_u.we;
                        istb_r      <= 1'b1;
                        icyc_r      <= 1'b1;
                        state       <= BUS;
`ifdef DEBUG
                        $display("[INIT][%0t] IDLE->BUS adr=0x%08x dat=0x%08x we=%0b stb=%0h", $time, req_u.adr, req_u.dat, req_u.we, req_u.stb);
`endif
                    end
                end
                BUS: begin
                    // Wait for ACK or ERR termination (CYC/STB held active until term)
                    if (term) begin
                        dat_r_q     <= idat_r;
                        err_q       <= ierr;
                        istb_r      <= 1'b0;
                        icyc_r      <= 1'b0;
                        rsp_valid_r <= 1'b1;
                        state       <= RESP;
`ifdef DEBUG
                        $display("[INIT][%0t] BUS->RESP term ack=%0b err=%0b dat_r=0x%08x", $time, iack, ierr, idat_r);
`endif
                    end
                end
                RESP: begin
                    // Hold response until consumed
                    if (rsp_fire) begin
                        rsp_valid_r <= 1'b0;
                        state       <= IDLE;
`ifdef DEBUG
                        $display("[INIT][%0t] RESP->IDLE rsp consumed", $time);
`endif
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end

`fwvip_bfm_t_end
