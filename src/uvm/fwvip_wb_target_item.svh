
typedef class fwvip_wb_transaction;

// The item that actually flows through the target sequencer. UVM forbids passing
// a sequence to start_item() (SEQNOTITM), so the responder sequence cannot send
// itself; instead it sends one of these lightweight items carrying a handle to
// the responder. The driver fetches it via get_next_item and calls access(),
// which forwards to the responder -- so the responder is still *called* per
// request (it never polls the bus).
class fwvip_wb_target_item extends uvm_sequence_item implements fwvip_wb_target_if;
    `uvm_object_utils(fwvip_wb_target_item)

    fwvip_wb_target_if  handler;

    function new(string name="fwvip_wb_target_item");
        super.new(name);
    endfunction

    virtual task access(fwvip_wb_transaction t);
        if (handler != null) begin
            handler.access(t);
        end
    endtask

endclass
