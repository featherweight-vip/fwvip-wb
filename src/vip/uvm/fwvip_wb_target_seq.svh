
typedef class fwvip_wb_transaction;

class fwvip_wb_target_seq extends uvm_sequence #(fwvip_wb_transaction);
    `uvm_object_utils(fwvip_wb_target_seq)

    function new(string name="fwvip_wb_target_seq");
        super.new(name);
    endfunction

    virtual task handle_request(fwvip_wb_transaction t);
    endtask

    task body();
        fwvip_wb_transaction t;

        t = fwvip_wb_transaction::type_id::create();

        start_item(t);
        finish_item(t);

        forever begin
            handle_request(t);
            // Send response and get next request
            start_item(t);
            finish_item(t);
        end
    endtask

endclass
