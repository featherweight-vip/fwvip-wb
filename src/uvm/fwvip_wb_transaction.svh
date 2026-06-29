
class fwvip_wb_transaction extends uvm_sequence_item;
    `uvm_object_utils(fwvip_wb_transaction)
    rand bit[ADDR_WIDTH_MAX-1:0]        adr;
    rand bit[DATA_WIDTH_MAX-1:0]        dat;
    rand bit[(DATA_WIDTH_MAX/8)-1:0]    sel;
    rand bit                            we;
    bit                                 err;

    function new(string name="fwvip_wb_transaction");
        super.new(name);
    endfunction

endclass