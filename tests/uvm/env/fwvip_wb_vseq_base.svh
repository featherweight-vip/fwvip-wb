
// ----------------------------------------------------------------------------
// Base virtual sequence for the Wishbone VIP.
//
// Runs on fwvip_wb_vseqr. Provides:
//   - plusarg configuration (+NUM_TXNS, +BASE_ADDR)
//   - automatic reset synchronization
//   - automatic start of a target responder (overridable)
//   - do_write()/do_read() helpers that issue single accesses on the initiator
//
// Concrete scenarios override stimulus(). The responder runs in the background
// for the whole sequence and is left to the target driver's final_phase to stop.
// ----------------------------------------------------------------------------
class fwvip_wb_vseq_base extends uvm_sequence;
    `uvm_object_utils(fwvip_wb_vseq_base)
    `uvm_declare_p_sequencer(fwvip_wb_vseqr)

    // Plusarg-configurable knobs
    int unsigned                num_txns = 16;
    bit [ADDR_WIDTH_MAX-1:0]    base_addr = 'h0000_0000;

    function new(string name="fwvip_wb_vseq_base");
        super.new(name);
    endfunction

    // Read plusargs into the knobs. Called at the top of body().
    virtual function void get_cfg();
        int unsigned    v;
        bit [63:0]      a;
        if ($value$plusargs("NUM_TXNS=%d", v))   num_txns  = v;
        if ($value$plusargs("BASE_ADDR=%h", a))  base_addr = a[ADDR_WIDTH_MAX-1:0];
        `uvm_info("VSEQ", $sformatf("%s cfg: num_txns=%0d base_addr=0x%0h",
                  get_type_name(), num_txns, base_addr), UVM_LOW)
    endfunction

    // Factory hook: scenarios may override to provide a configured responder.
    virtual function fwvip_wb_target_seq create_responder();
        fwvip_wb_mem_target_seq s = fwvip_wb_mem_target_seq::type_id::create("responder");
        return s;
    endfunction

    // Override point: the actual stimulus.
    virtual task stimulus();
    endtask

    // ---- access helpers ----------------------------------------------------
    virtual task do_write(bit [ADDR_WIDTH_MAX-1:0] adr,
                          bit [DATA_WIDTH_MAX-1:0] dat,
                          bit [(DATA_WIDTH_MAX/8)-1:0] sel = '1);
        fwvip_wb_init_access_seq a = fwvip_wb_init_access_seq::type_id::create("wr");
        a.adr = adr; a.dat = dat; a.sel = sel; a.we = 1'b1;
        a.start(p_sequencer.init_seqr);
    endtask

    virtual task do_read(bit [ADDR_WIDTH_MAX-1:0] adr,
                         output bit [DATA_WIDTH_MAX-1:0] dat,
                         output bit err,
                         input bit [(DATA_WIDTH_MAX/8)-1:0] sel = '1);
        fwvip_wb_init_access_seq a = fwvip_wb_init_access_seq::type_id::create("rd");
        a.adr = adr; a.dat = '0; a.sel = sel; a.we = 1'b0;
        a.start(p_sequencer.init_seqr);
        dat = a.dat;
        err = a.err;
    endtask

    task body();
        fwvip_wb_target_seq resp;
        get_cfg();

        // Synchronize to reset before driving, via the core reset provider.
        if (p_sequencer.reset_provider != null) begin
            p_sequencer.reset_provider.wait_reset();
        end

        // Launch the background responder on the target
        resp = create_responder();
        fork
            resp.start(p_sequencer.targ_seqr);
        join_none

        stimulus();
    endtask

endclass
