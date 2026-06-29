
typedef class fwvip_wb_transaction;

// Target responder sequence. It implements the responder API (access()) and
// keeps offering a wrapper item to the driver; the driver calls access() on that
// wrapper for each observed request, which forwards back here. (UVM forbids
// passing a sequence itself to start_item(), hence the wrapper item.)
// finish_item() blocks until the driver finishes one access (single outstanding,
// matching classic Wishbone).
class fwvip_wb_target_seq extends uvm_sequence #(fwvip_wb_target_item)
        implements fwvip_wb_target_if;
    `uvm_object_utils(fwvip_wb_target_seq)

    function new(string name="fwvip_wb_target_seq");
        super.new(name);
    endfunction

    // Override point for concrete responders (e.g. a memory model).
    virtual task handle_request(fwvip_wb_transaction t);
    endtask

    // fwvip_wb_target_if: the driver calls this for each request.
    virtual task access(fwvip_wb_transaction t);
        handle_request(t);
    endtask

    task body();
        fwvip_wb_target_item it = fwvip_wb_target_item::type_id::create("it");
        it.handler = this;
        forever begin
            start_item(it);
            finish_item(it);
        end
    endtask

endclass

