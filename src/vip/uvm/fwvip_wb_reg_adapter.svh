
class fwvip_wb_reg_adapter extends uvm_reg_adapter;
  `uvm_object_utils(fwvip_wb_reg_adapter)

  function new(string name="fwvip_wb_reg_adapter");
    super.new(name);
  endfunction

  virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
    fwvip_wb_transaction t = fwvip_wb_transaction::type_id::create("t");
    t.adr = rw.addr[ADDR_WIDTH_MAX-1:0];
    t.dat = rw.data[DATA_WIDTH_MAX-1:0];
    t.we  = (rw.kind == UVM_WRITE);
    t.sel = '1; // full-byte enable
    return t;
  endfunction

  virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
    fwvip_wb_transaction t;
    if (!$cast(t, bus_item)) begin
      `uvm_fatal("ADAPT", "bus_item is not fwvip_wb_transaction")
    end
    rw.addr   = t.adr;
    rw.data   = t.dat;
    rw.kind   = (t.we) ? UVM_WRITE : UVM_READ;
    rw.status = (t.err) ? UVM_NOT_OK : UVM_IS_OK;
    rw.n_bits = DATA_WIDTH_MAX;
  endfunction
endclass

