
typedef class fwvip_wb_transaction;

class fwvip_wb_initiator_seq extends uvm_sequence #(fwvip_wb_transaction);
    `uvm_object_utils(fwvip_wb_initiator_seq)
    fwvip_wb_transaction t;

    function new(string name="fwvip_wb_initiator_seq");
        super.new(name);
        t = fwvip_wb_transaction::type_id::create();
    endfunction

    task body();
        start_item(t);
        finish_item(t);
    endtask

endclass
