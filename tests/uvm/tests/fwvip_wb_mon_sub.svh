
class fwvip_wb_mon_sub extends uvm_subscriber #(fwvip_wb_transaction);
    `uvm_component_utils(fwvip_wb_mon_sub)

    int unsigned txn_count;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        txn_count = 0;
    endfunction

    function void write(fwvip_wb_transaction t);
        txn_count++;
        `uvm_info(get_name(), $sformatf("MON txn %0d adr=%0h we=%0b sel=%0h dat=%0h err=%0b",
                 txn_count, t.adr, t.we, t.sel, t.dat, t.err), UVM_LOW)
    endfunction
endclass
