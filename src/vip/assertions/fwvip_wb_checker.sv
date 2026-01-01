`include "wishbone_macros.svh"

module fwvip_wb_checkers #(
        parameter ADDR_WIDTH=32, 
        parameter DATA_WIDTH=32,
        parameter MAX_CYCLE_LEN=256
    ) (
        input clock,
        input reset,
        `WB_MONITOR_PORT(m, ADDR_WIDTH, DATA_WIDTH)
    );

    // Check that cycles always terminate within 
    // a specified maximum
    // Checker 1: Max cycle length
    reg [$clog2(MAX_CYCLE_LEN):0] max_len_cnt = '0;
    reg                             max_len_active = 1'b0;
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            max_len_cnt    <= '0;
            max_len_active <= 1'b0;
        end else begin
            if (!max_len_active) begin
                if (mcyc && mstb) begin
                    max_len_active <= 1'b1;
                    max_len_cnt    <= '0;
                end
            end else begin
                if (mack) begin
                    max_len_active <= 1'b0;
                end else begin
                    max_len_cnt <= max_len_cnt + 1'b1;
                    assert(max_len_cnt < MAX_CYCLE_LEN);
                end
            end
        end
    end

    // Checker 2: STB only with CYC
    // Simple two-state monitor (idle/monitor)
    reg stb_cyc_monitor = 1'b0;
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            stb_cyc_monitor <= 1'b0;
        end else begin
            // one-hot implicit states: stb_cyc_monitor==0 idle, ==1 monitoring
            if (!stb_cyc_monitor) begin
                if (mstb || mcyc) stb_cyc_monitor <= 1'b1; // start monitoring once activity begins
            end else begin
                if (!(mstb || mcyc)) stb_cyc_monitor <= 1'b0; // return to idle when bus quiet
            end
            if (mstb && !mcyc) begin
//                assert(0); // violation: STB without CYC
            end
        end
    end

    // Checker 3: Hold CYC/STB until ACK
    reg hold_fsm_active = 1'b0;
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            hold_fsm_active <= 1'b0;
        end else begin
            if (!hold_fsm_active) begin
                if (mcyc && mstb) begin
                    hold_fsm_active <= 1'b1;
                end
            end else begin
                if (mack) begin
                    hold_fsm_active <= 1'b0;
                end else begin
//                    assert(mcyc == 1'b1);
//                    assert(mstb == 1'b1);
                end
            end
        end
    end

    // Checker 4: Hold transaction attributes until ACK
    reg hold_fsm_active = 1'b0;
    reg[ADDR_WIDTH-1:0]     hold_adr;
    reg[DATA_WIDTH-1:0]     hold_dat_w;
    reg[(DATA_WIDTH/8)-1:0] hold_sel;
    reg                     hold_we;
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            hold_fsm_active <= 1'b0;
        end else begin
            if (!hold_fsm_active) begin
                if (mcyc && mstb) begin
                    hold_fsm_active <= 1'b1;
                    hold_adr <= madr;
                    hold_dat_w <= mdat_w;
                    hold_sel <= msel;
                    hold_we <= mwe;
                end
            end else begin
                if (mack) begin
                    hold_fsm_active <= 1'b0;
                end else begin
                    assert(madr == hold_adr);
                    assert(mwe == hold_we);
                    if (hold_we) begin
                        assert(hold_sel == msel);
                        assert(hold_dat_w == mdat_w);
                    end
                end
            end
        end
    end

endmodule

