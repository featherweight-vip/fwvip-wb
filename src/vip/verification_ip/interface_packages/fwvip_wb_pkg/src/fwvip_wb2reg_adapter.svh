//----------------------------------------------------------------------
// Created with uvmf_gen version 2023.4
//----------------------------------------------------------------------
// pragma uvmf custom header begin
// pragma uvmf custom header end
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//     
// DESCRIPTION: 
// This file contains the UVM register adapter for the fwvip_wb interface.
//
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//
class fwvip_wb2reg_adapter  extends uvm_reg_adapter;

  `uvm_object_utils( fwvip_wb2reg_adapter )
  
  // pragma uvmf custom class_item_additional begin
  // pragma uvmf custom class_item_additional end

  //--------------------------------------------------------------------
  // new
  //--------------------------------------------------------------------
  function new (string name = "fwvip_wb2reg_adapter" );
    super.new(name);
    // pragma uvmf custom new begin
    // UVMF_CHANGE_ME : Configure the adapter regarding byte enables and provides response.

    // Does the protocol the Agent is modeling support byte enables?
    // 0 = NO
    // 1 = YES
    supports_byte_enable = 1;

    // Does the Agent's Driver provide separate response sequence items?
    // i.e. Does the driver call seq_item_port.put() 
    // and do the sequences call get_response()?
    // 0 = NO
    // 1 = YES
    provides_responses = 0;
    // pragma uvmf custom new end

  endfunction: new

  //--------------------------------------------------------------------
  // reg2bus
  //--------------------------------------------------------------------
  virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);

    fwvip_wb_transaction  trans_h = fwvip_wb_transaction ::type_id::create("trans_h");
    
    // pragma uvmf custom reg2bus begin
    // UVMF_CHANGE_ME : Fill in the reg2bus adapter mapping registe fields to protocol fields.

    //Adapt the following for your sequence item type
    trans_h.we = (rw.kind == UVM_WRITE)?1:0;
    //Copy over address
    trans_h.adr = rw.addr;
    //Copy over write data
    trans_h.dat = rw.data;

    if (rw.n_bits >= 32) begin
        trans_h.sel = 4'hf;
    end else if (rw.n_bits > 8) begin
        trans_h.sel = (4'h3 << 2*rw.addr[1]);
    end else begin
        trans_h.sel = (4'h1 << rw.addr[1:0]);
    end

    // pragma uvmf custom reg2bus end
    
    // Return the adapted transaction
    return trans_h;

  endfunction: reg2bus

  //--------------------------------------------------------------------
  // bus2reg
  //--------------------------------------------------------------------
  virtual function void bus2reg(uvm_sequence_item bus_item,
                                ref uvm_reg_bus_op rw);
    fwvip_wb_transaction  trans_h;
    if (!$cast(trans_h, bus_item)) begin
      `uvm_fatal("ADAPT","Provided bus_item is not of the correct type")
      return;
    end
    // pragma uvmf custom bus2reg begin
    // UVMF_CHANGE_ME : Fill in the bus2reg adapter mapping protocol fields to register fields.
    //Adapt the following for your sequence item type
    //Copy over instruction type 
    rw.kind = (trans_h.we) ? UVM_WRITE : UVM_READ;
    //Copy over address
    rw.addr = trans_h.adr;
    //Copy over read data
    rw.data = trans_h.dat;
    //Check for errors on the bus and return UVM_NOT_OK if there is an error
    rw.status = UVM_IS_OK;
    // pragma uvmf custom bus2reg end

  endfunction: bus2reg

endclass : fwvip_wb2reg_adapter

// pragma uvmf custom external begin
// pragma uvmf custom external end

