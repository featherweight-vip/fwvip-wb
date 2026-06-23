
// ----------------------------------------------------------------------------
// Reusable target memory responder sequence.
//
// Runs forever on the target sequencer, servicing each observed Wishbone access
// against an associative-array memory. An optional error policy lets scenarios
// force ERR termination for a configurable address range/mask.
// ----------------------------------------------------------------------------
class fwvip_wb_mem_target_seq extends fwvip_wb_target_seq;
    `uvm_object_utils(fwvip_wb_mem_target_seq)

    bit [DATA_WIDTH_MAX-1:0]    mem [bit [ADDR_WIDTH_MAX-1:0]];

    // Error policy: when enabled, any access whose address ANDed with err_mask
    // equals err_match terminates with ERR (and is not read/written).
    bit                         err_enable = 1'b0;
    bit [ADDR_WIDTH_MAX-1:0]    err_mask   = '0;
    bit [ADDR_WIDTH_MAX-1:0]    err_match  = '0;

    function new(string name="fwvip_wb_mem_target_seq");
        super.new(name);
    endfunction

    // word address: data-width granular (32-bit word => >>2)
    virtual function bit [ADDR_WIDTH_MAX-1:0] word_addr(bit [ADDR_WIDTH_MAX-1:0] adr);
        return adr >> 2;
    endfunction

    virtual task handle_request(fwvip_wb_transaction t);
        bit [ADDR_WIDTH_MAX-1:0] wa = word_addr(t.adr);

        if (err_enable && ((t.adr & err_mask) == err_match)) begin
            t.err = 1'b1;
            return;
        end

        t.err = 1'b0;
        if (t.we) begin
            mem[wa] = t.dat;
        end else begin
            t.dat = (mem.exists(wa)) ? mem[wa] : '0;
        end
    endtask

endclass
