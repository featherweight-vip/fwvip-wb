`include "uvm_macros.svh"

class fwvip_wb_mem_target_seq extends fwvip_wb_target_seq;
  `uvm_object_utils(fwvip_wb_mem_target_seq)
  bit [31:0] mem[int unsigned]; // 32-bit data width
  function new(string name="fwvip_wb_mem_target_seq");
    super.new(name);
  endfunction
  virtual task handle_request(fwvip_wb_transaction t);
    int unsigned wa = t.adr >> 2; // 32-bit word addressing
    if (t.we) begin
      mem[wa] = t.dat;
      t.err = 0;
    end else begin
      t.dat = (mem.exists(wa)) ? mem[wa] : '0;
      t.err = 0;
    end
  endtask
endclass

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

class fwvip_wb_test_reg extends fwvip_wb_test_base;
  `uvm_component_utils(fwvip_wb_test_reg)
  function new(string name="fwvip_wb_test_reg", uvm_component parent=null);
    super.new(name,parent);
  endfunction
  task run_phase(uvm_phase phase);
    wb_block blk;
    fwvip_wb_reg_adapter adapter;
    uvm_status_e status;
    uvm_reg_data_t rdat;
    fwvip_wb_mem_target_seq tseq;

    phase.raise_objection(this);
    m_env.m_init.m_cfg.wait_reset();

    // start target memory responder
    tseq = fwvip_wb_mem_target_seq::type_id::create("tseq");
    fork
      tseq.start(m_env.m_targ.m_seqr);
    join_none

    // build reg model and hook adapter
    blk = wb_block::type_id::create("blk");
    blk.build();
    adapter = fwvip_wb_reg_adapter::type_id::create("adapter");
    blk.default_map.set_sequencer(m_env.m_init.m_seqr, adapter);

    // do a write then read
    blk.r.write(status, 'hA5A5A5A5);
    if (status != UVM_IS_OK) `uvm_error("TEST", "Write failed")
    blk.r.read(status, rdat);
    if (status != UVM_IS_OK) `uvm_error("TEST", "Read failed")
    if (rdat !== 'hA5A5A5A5) `uvm_fatal("TEST", $sformatf("Unexpected read: %0h", rdat))

    phase.drop_objection(this);
  endtask
endclass
