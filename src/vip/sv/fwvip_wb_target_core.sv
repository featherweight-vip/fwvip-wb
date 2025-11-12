`include "wishbone_macros.svh"
`include "rv_macros.svh"
`include "fwvip_macros.svh"

// Wishbone Target (Slave) Core Transactor
// - Observes Wishbone target signals (t*)
// - Converts each classic single-cycle access to an RV request (req_)
// - Waits for RV response (rsp_), then returns ACK (tack) or ERR (terr)
// - Single outstanding transaction (no pipelining)

// REQ vector layout: { adr, dat_w, stb(byte-enables), we }
// RSP vector layout: { dat_r, err }

interface fwvip_wb_target_core #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter REQ_WIDTH  = (ADDR_WIDTH + DATA_WIDTH + (DATA_WIDTH/8) + 1),
    parameter RSP_WIDTH  = (DATA_WIDTH + 1)
) (
    input  clock,
    input  reset,
    // Wishbone target (slave) port
    input [ADDR_WIDTH-1:0]     tadr,
    input [DATA_WIDTH-1:0]     tdat_w,
    output [DATA_WIDTH-1:0]    tdat_r,
    input                      tcyc,
    output                     terr,
    input [DATA_WIDTH/8-1:0]   tsel,
    input                      tstb,
    output                     tack,
    input                      twe,
    // RV request (produced by this target)
    output [REQ_WIDTH-1:0]     req_dat,
    output                     req_valid,
    input                      req_ready,
    // RV response (consumed by this target)
    input [RSP_WIDTH-1:0]      rsp_dat,
    input                      rsp_valid,
    output                     rsp_ready
);

    // --------------------------------------------------------------------
    // Packed request/response structures (match initiator core semantics)
    // --------------------------------------------------------------------
    typedef struct packed {
        bit [ADDR_WIDTH-1:0]      adr;
        bit [DATA_WIDTH-1:0]      dat;
        bit                       we;
        bit [(DATA_WIDTH/8)-1:0]  stb;   // byte enables
    } req_s;

    typedef struct packed {
        bit [DATA_WIDTH-1:0]      dat;
        bit                       err;
    } rsp_s;

    // --------------------------------------------------------------------
    // Internal Registers
    // --------------------------------------------------------------------
    // Latched Wishbone request fields
    reg [ADDR_WIDTH-1:0]     adr_q;
    reg [DATA_WIDTH-1:0]     dat_w_q;
    reg [(DATA_WIDTH/8)-1:0] stb_q;
    reg                      we_q;

    // Response latches
    reg [DATA_WIDTH-1:0]     dat_r_q;
    reg                      err_q;

    // Wishbone termination outputs (registered)
    reg tack_r;
    reg terr_r;

    // RV request handshake
    reg req_valid_r;
    wire req_fire    = req_valid && req_ready;

    // RV response handshake
    wire rsp_fire;
    reg  rsp_ready_r;

    // Pack request vector from latched fields
    req_s req_u;
    always_comb begin
        req_u = '{adr: adr_q, dat: dat_w_q, we: we_q, stb: stb_q};
    end
    assign req_dat   = req_u;
    assign req_valid = req_valid_r;

    // Unpack response vector
    rsp_s rsp_u;
    always_comb begin
        rsp_u = rsp_s'(rsp_dat);
    end
    assign rsp_ready = 1'b1;

    // Fast termination on response: drive ack/data combinationally when response arrives
    // Registered ack path (restore spec behavior): ack asserted for one cycle after response captured
    assign tdat_r = dat_r_q;
    assign tack   = tack_r;
    assign terr   = terr_r;

    // Wishbone cycle termination detection (spec: termination only when CYC & STB asserted)
    wire active_cycle = tcyc & tstb;

    // FSM
    typedef enum logic [1:0] {
        IDLE     = 2'b00,
        REQ      = 2'b01,
        WAIT_RSP = 2'b10,
        RESP     = 2'b11
    } state_e;

    state_e state, state_n;

    // Response handshake qualification (only care in WAIT_RSP)
    assign rsp_fire = (state == WAIT_RSP) && rsp_valid && rsp_ready;

    // Next-state / control
    always_comb begin
        // Defaults
        state_n      = state;
        //rsp_ready_r  = (state == WAIT_RSP); // only assert when expecting
        // tack/terr pulses controlled in sequential block (one-cycle assertion)
        case (state)
            IDLE: begin
                // Detect new Wishbone request: CYC & STB high, and we are idle
                // Capture and start RV request (performed in sequential on state change)
                if (active_cycle) begin
                    state_n = REQ;
                end
            end
            REQ: begin
                // Wait for RV request acceptance
                if (!active_cycle) begin
                    // Master aborted early; cancel
                    state_n = IDLE;
                end else if (req_fire) begin
                    state_n = WAIT_RSP;
                end
            end
            WAIT_RSP: begin
                if (!active_cycle) begin
                    // Master aborted cycle; discard response when it arrives
                    state_n = IDLE;
                end else if (rsp_fire) begin
                    state_n = RESP;
                end
            end
            RESP: begin
                // After one cycle pulse of ack/err go back idle (master should drop STB/CYC)
                state_n = IDLE;
            end
            default: state_n = IDLE;
        endcase
    end

    // Sequential logic
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            state       <= IDLE;
            // Clear latches
            adr_q       <= '0;
            dat_w_q     <= '0;
            stb_q       <= '0;
            we_q        <= 1'b0;
            dat_r_q     <= '0;
            err_q       <= 1'b0;
            // Outputs / handshakes
            req_valid_r <= 1'b0;
            tack_r      <= 1'b0;
            terr_r      <= 1'b0;
        end else begin
            if (state != state_n) begin
                $display("[TGT][%0t] state %0d -> %0d (active=%0b cyc=%0b stb=%0b we=%0b)", $time, state, state_n, active_cycle, tcyc, tstb, twe);
            end
            state <= state_n;

            // Default deassert; assert for one-cycle while in RESP state
            tack_r <= 1'b0;
            terr_r <= 1'b0;
            if (state == RESP) begin
                tack_r <= ~err_q;
                terr_r <= err_q;
                $display("[TGT][%0t] RESP: tack=%0b terr=%0b dat_r=0x%08x", $time, ~err_q, err_q, dat_r_q);
            end

            case (state)
                IDLE: begin
                    req_valid_r <= 1'b0;
                    if (active_cycle) begin
                        // Latch incoming bus request
                        adr_q       <= tadr;
                        dat_w_q     <= tdat_w;
                        stb_q       <= tsel;    // treat Wishbone SEL as byte-enable vector
                        we_q        <= twe;
                        // Initiate RV request
                        req_valid_r <= 1'b1;
                        $display("[TGT][%0t] IDLE: latch adr=0x%08x dat=0x%08x we=%0b stb=%0h -> assert req_valid", $time, tadr, tdat_w, twe, tsel);
                    end
                end
                REQ: begin
                    // Await req_ready; maintain req_valid_r until fire or abort
                    $display("[TGT][%0t] REQ: req_valid=%0b req_ready=%0b fire=%0b", $time, req_valid, req_ready, req_fire);
                    if (!active_cycle) begin
                        // Abort
                        req_valid_r <= 1'b0;
                        $display("[TGT][%0t] REQ: abort (active dropped)", $time);
                    end else if (req_fire) begin
                        req_valid_r <= 1'b0;
                        $display("[TGT][%0t] REQ: req_fire (ready=%0b) -> WAIT_RSP", $time, req_ready);
                    end
                end
                WAIT_RSP: begin
                    $display("[TGT][%0t] WAIT_RSP: rsp_valid=%0b rsp_ready=%0b fire=%0b", $time, rsp_valid, rsp_ready, rsp_fire);
                    if (!active_cycle) begin
                        $display("[TGT][%0t] WAIT_RSP: abort (active dropped)", $time);
                    end else if (rsp_fire) begin
                        // Latch response for potential debug; ack generated combinationally
                        dat_r_q <= rsp_u.dat;
                        err_q   <= rsp_u.err;
                        $display("[TGT][%0t] WAIT_RSP: rsp_fire dat=0x%08x err=%0b -> IDLE (fast ack)", $time, rsp_u.dat, rsp_u.err);
                    end
                end

            endcase
        end
    end

endinterface
