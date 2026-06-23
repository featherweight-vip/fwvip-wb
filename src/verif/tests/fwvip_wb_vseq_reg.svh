
// ----------------------------------------------------------------------------
// Register-access virtual sequence.
//
// Builds a small uvm_reg model, hooks the fwvip_wb_reg_adapter onto the
// initiator sequencer, and performs front-door write/read checks. The base
// virtual sequence supplies the background memory responder and reset sync.
// ----------------------------------------------------------------------------

class wb_reg extends uvm_reg;
    `uvm_object_utils(wb_reg)
    uvm_reg_field f;
    function new(string name="wb_reg");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction
    virtual function void build();
        f = uvm_reg_field::type_id::create("f");
        f.configure(this, 32, 0, "RW", 0, 0, 1, 1, 0);
    endfunction
endclass

class wb_block extends uvm_reg_block;
    `uvm_object_utils(wb_block)
    wb_reg r;
    function new(string name="wb_block");
        super.new(name, UVM_NO_COVERAGE);
    endfunction
    virtual function void build();
        default_map = create_map("default_map", 'h0, 4, UVM_LITTLE_ENDIAN, 0);
        r = wb_reg::type_id::create("r");
        r.build();
        r.configure(this, null, "");
        default_map.add_reg(r, 'h0, "RW");
        lock_model();
    endfunction
endclass

class fwvip_wb_vseq_reg extends fwvip_wb_vseq_base;
    `uvm_object_utils(fwvip_wb_vseq_reg)

    function new(string name="fwvip_wb_vseq_reg");
        super.new(name);
    endfunction

    virtual task stimulus();
        wb_block               blk;
        fwvip_wb_reg_adapter   adapter;
        uvm_status_e           status;
        uvm_reg_data_t         rdat;

        blk = wb_block::type_id::create("blk");
        blk.build();
        adapter = fwvip_wb_reg_adapter::type_id::create("adapter");
        blk.default_map.set_sequencer(p_sequencer.init_seqr, adapter);

        blk.r.write(status, 'hA5A5A5A5, .parent(this));
        if (status != UVM_IS_OK) `uvm_error("VSEQ_REG", "Write failed")

        blk.r.read(status, rdat, .parent(this));
        if (status != UVM_IS_OK) `uvm_error("VSEQ_REG", "Read failed")
        if (rdat !== 'hA5A5A5A5)
            `uvm_error("VSEQ_REG", $sformatf("Unexpected read: 0x%0h (exp 0xA5A5A5A5)", rdat))
    endtask

endclass
