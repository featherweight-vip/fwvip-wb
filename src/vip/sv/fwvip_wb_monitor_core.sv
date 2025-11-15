`include "wishbone_macros.svh"
`include "rv_macros.svh"
`include "fwvip_macros.svh"

// Wishbone bus monitor core
// Observes Wishbone handshakes and emits a transaction per completed access
// Egress RV port payload: { adr, dat, we, sel, err }
`fwvip_bfm_t fwvip_wb_monitor_core #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int MON_WIDTH  = (ADDR_WIDTH + DATA_WIDTH + (DATA_WIDTH/8) + 1 + 1)
) (
    input  logic                     clock,
    input  logic                     reset,
    // Passive observation of Wishbone initiator-side signals
    `WB_MONITOR_PORT(i, ADDR_WIDTH, DATA_WIDTH),
    // Egress channel with observed transactions
    `RV_INITIATOR_PORT(mon_, MON_WIDTH)
);

    typedef struct packed {
        bit [ADDR_WIDTH-1:0]      adr;
        bit [DATA_WIDTH-1:0]      dat;   // write data on WE=1, read data on WE=0
        bit                        we;
        bit [(DATA_WIDTH/8)-1:0]  sel;
        bit                        err;
    } mon_s;

    // Handshake
    reg        mon_valid_r;
    assign mon_valid = mon_valid_r;

    // Capture registers for payload
    mon_s      mon_q;

    // Pack payload
    assign mon_dat = mon_q;

    // Termination of a bus cycle
    wire term = (iack || ierr) && icyc && istb;
    // Backpressure resolution: fire when accepted by downstream
    wire mon_fire = mon_valid && mon_ready;

    // Simple single-entry buffer
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            mon_valid_r <= 1'b0;
            mon_q       <= '0;
        end else begin
            // Consume when downstream ready
            if (mon_fire) begin
                mon_valid_r <= 1'b0;
            end

            // Produce on termination if buffer empty (or consumed same cycle)
            if (term && (!mon_valid_r || mon_fire)) begin
                mon_q.adr <= iadr;
                mon_q.dat <= iwe ? idat_w : idat_r;
                mon_q.we  <= iwe;
                mon_q.sel <= isel;
                mon_q.err <= ierr;
                mon_valid_r <= 1'b1;
                $display("[MON][%0t] txn adr=0x%08x we=%0b sel=0x%0h dat=0x%08x err=%0b", $time, iadr, iwe, isel, (iwe?idat_w:idat_r), ierr);
            end
        end
    end

`fwvip_bfm_t_end
