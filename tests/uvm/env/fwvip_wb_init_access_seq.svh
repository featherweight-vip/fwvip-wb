
// ----------------------------------------------------------------------------
// Initiator single-access sequence.
//
// Issues exactly one Wishbone access (read or write) on the initiator
// sequencer. For reads, the read data is available in `dat` after the sequence
// completes (the driver updates the same transaction object in-place).
// ----------------------------------------------------------------------------
class fwvip_wb_init_access_seq extends uvm_sequence #(fwvip_wb_transaction);
    `uvm_object_utils(fwvip_wb_init_access_seq)

    rand bit [ADDR_WIDTH_MAX-1:0]       adr;
    rand bit [DATA_WIDTH_MAX-1:0]       dat;
    rand bit [(DATA_WIDTH_MAX/8)-1:0]   sel;
    rand bit                            we;
    bit                                 err;   // result: error termination

    constraint c_sel_default { soft sel == '1; }

    function new(string name="fwvip_wb_init_access_seq");
        super.new(name);
    endfunction

    task body();
        fwvip_wb_transaction t = fwvip_wb_transaction::type_id::create("t");
        start_item(t);
        t.adr = adr;
        t.dat = dat;
        t.sel = sel;
        t.we  = we;
        finish_item(t);
        // Driver updates t in-place: capture read data and error result
        dat = t.dat;
        err = t.err;
    endtask

endclass
