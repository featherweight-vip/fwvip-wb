
// ----------------------------------------------------------------------------
// Generic Wishbone VIP virtual sequences (reusable scenario library).
//
//   fwvip_wb_vseq_write  - num_txns word writes to incrementing addresses
//   fwvip_wb_vseq_read   - write a block, then read it back (self-checking
//                          via the scoreboard on the monitor stream)
//   fwvip_wb_vseq_smoke  - writes then reads (the default scenario)
//   fwvip_wb_vseq_rand   - randomized mixed read/write traffic
//   fwvip_wb_vseq_sel    - writes cycling through partial SEL patterns
//   fwvip_wb_vseq_err    - exercises ERR termination via the responder policy
// ----------------------------------------------------------------------------

// ---- write-only -----------------------------------------------------------
class fwvip_wb_vseq_write extends fwvip_wb_vseq_base;
    `uvm_object_utils(fwvip_wb_vseq_write)
    function new(string name="fwvip_wb_vseq_write"); super.new(name); endfunction

    virtual task stimulus();
        for (int unsigned i = 0; i < num_txns; i++) begin
            do_write(base_addr + (i*4), 32'hA5A5_0000 + i);
        end
    endtask
endclass

// ---- write-then-read (self-checking via scoreboard) -----------------------
class fwvip_wb_vseq_read extends fwvip_wb_vseq_base;
    `uvm_object_utils(fwvip_wb_vseq_read)
    function new(string name="fwvip_wb_vseq_read"); super.new(name); endfunction

    virtual task stimulus();
        bit [DATA_WIDTH_MAX-1:0] d;
        bit                      e;
        for (int unsigned i = 0; i < num_txns; i++) begin
            do_write(base_addr + (i*4), 32'hD000_0000 + i);
        end
        for (int unsigned i = 0; i < num_txns; i++) begin
            do_read(base_addr + (i*4), d, e);
            if (e) `uvm_error("VSEQ", $sformatf("unexpected ERR on read @0x%0h", base_addr + (i*4)))
            if (d !== (32'hD000_0000 + i))
                `uvm_error("VSEQ", $sformatf("readback mismatch @0x%0h: got 0x%0h exp 0x%0h",
                           base_addr + (i*4), d, 32'hD000_0000 + i))
        end
    endtask
endclass

// ---- smoke (default): writes then reads -----------------------------------
class fwvip_wb_vseq_smoke extends fwvip_wb_vseq_read;
    `uvm_object_utils(fwvip_wb_vseq_smoke)
    function new(string name="fwvip_wb_vseq_smoke"); super.new(name); endfunction
endclass

// ---- randomized mixed traffic ---------------------------------------------
class fwvip_wb_vseq_rand extends fwvip_wb_vseq_base;
    `uvm_object_utils(fwvip_wb_vseq_rand)
    function new(string name="fwvip_wb_vseq_rand"); super.new(name); endfunction

    virtual task stimulus();
        // keep address space small so reads frequently hit prior writes
        localparam int unsigned N_WORDS = 16;
        bit [DATA_WIDTH_MAX-1:0] d;
        bit                      e;
        for (int unsigned i = 0; i < num_txns; i++) begin
            bit                      we   = $urandom_range(1);
            int unsigned             widx = $urandom_range(N_WORDS-1);
            bit [ADDR_WIDTH_MAX-1:0] adr  = base_addr + (widx*4);
            if (we) do_write(adr, $urandom());
            else    do_read(adr, d, e);
        end
    endtask
endclass

// ---- partial SEL patterns -------------------------------------------------
class fwvip_wb_vseq_sel extends fwvip_wb_vseq_base;
    `uvm_object_utils(fwvip_wb_vseq_sel)
    function new(string name="fwvip_wb_vseq_sel"); super.new(name); endfunction

    virtual task stimulus();
        bit [3:0] pat [4] = '{4'h1, 4'h3, 4'hC, 4'hF};
        for (int unsigned i = 0; i < num_txns; i++) begin
            do_write(base_addr + (i*4), 32'h1234_0000 + i, pat[i % 4]);
        end
    endtask
endclass

// ---- ERR termination ------------------------------------------------------
class fwvip_wb_vseq_err extends fwvip_wb_vseq_base;
    `uvm_object_utils(fwvip_wb_vseq_err)
    function new(string name="fwvip_wb_vseq_err"); super.new(name); endfunction

    // Responder returns ERR for any address with bit[8] set
    virtual function fwvip_wb_target_seq create_responder();
        fwvip_wb_mem_target_seq s = fwvip_wb_mem_target_seq::type_id::create("responder");
        s.err_enable = 1'b1;
        s.err_mask   = 'h100;
        s.err_match  = 'h100;
        return s;
    endfunction

    virtual task stimulus();
        bit [DATA_WIDTH_MAX-1:0] d;
        bit                      e;
        int unsigned             n_err = 0;
        for (int unsigned i = 0; i < num_txns; i++) begin
            // alternate ERR address (bit[8]=1) and OK address
            bit [ADDR_WIDTH_MAX-1:0] adr = (i[0]) ? (base_addr | 'h100) : (base_addr & ~('h100));
            do_read(adr, d, e);
            if (e) n_err++;
            if ((adr & 'h100) == 'h100) begin
                if (!e) `uvm_error("VSEQ", $sformatf("expected ERR @0x%0h but got OK", adr))
            end else begin
                if (e)  `uvm_error("VSEQ", $sformatf("unexpected ERR @0x%0h", adr))
            end
        end
        `uvm_info("VSEQ", $sformatf("observed %0d ERR terminations", n_err), UVM_LOW)
        if (n_err == 0) `uvm_error("VSEQ", "no ERR terminations observed")
    endtask
endclass
