
// ----------------------------------------------------------------------------
// Reusable Wishbone scoreboard.
//
// Subscribes to the monitor analysis port and self-checks read data against a
// reference memory built from observed writes. Because the monitor reports every
// completed access (adr/dat/we/sel/err), the scoreboard needs no other hookup.
//
//   - WRITE (err==0): reference memory[adr] updated (full word; SEL transport
//     only per the VIP scope -- no byte-lane modeling).
//   - READ  (err==0): if the address was previously written, observed read data
//     MUST match the reference; otherwise the read is recorded as "uninit"
//     (informational, not an error).
//   - any access with err==1 is counted but not checked.
// ----------------------------------------------------------------------------
class fwvip_wb_scoreboard extends uvm_subscriber #(fwvip_wb_transaction);
    `uvm_component_utils(fwvip_wb_scoreboard)

    // Reference memory, keyed by (word) address
    bit [DATA_WIDTH_MAX-1:0]    m_ref [bit [ADDR_WIDTH_MAX-1:0]];

    int unsigned    n_writes;
    int unsigned    n_reads;
    int unsigned    n_err;
    int unsigned    n_checked;
    int unsigned    n_uninit;
    int unsigned    n_mismatch;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void write(fwvip_wb_transaction t);
        if (t.err) begin
            n_err++;
            return;
        end
        if (t.we) begin
            n_writes++;
            m_ref[t.adr] = t.dat;
        end else begin
            n_reads++;
            if (m_ref.exists(t.adr)) begin
                n_checked++;
                if (t.dat !== m_ref[t.adr]) begin
                    n_mismatch++;
                    `uvm_error("SCBD", $sformatf(
                        "READ mismatch @adr=0x%0h : observed=0x%0h expected=0x%0h",
                        t.adr, t.dat, m_ref[t.adr]))
                end
            end else begin
                n_uninit++;
                `uvm_info("SCBD", $sformatf(
                    "READ of uninitialized adr=0x%0h (dat=0x%0h) -- not checked",
                    t.adr, t.dat), UVM_HIGH)
            end
        end
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("SCBD", $sformatf(
            "summary: writes=%0d reads=%0d (checked=%0d uninit=%0d) err=%0d mismatch=%0d",
            n_writes, n_reads, n_checked, n_uninit, n_err, n_mismatch), UVM_LOW)
        if (n_mismatch != 0) begin
            `uvm_error("SCBD", $sformatf("%0d read mismatch(es) detected", n_mismatch))
        end
    endfunction

endclass
