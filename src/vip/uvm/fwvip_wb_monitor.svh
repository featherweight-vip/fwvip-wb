typedef class fwvip_wb_transaction;

class fwvip_wb_monitor extends uvm_component;
    `uvm_component_utils(fwvip_wb_monitor)

    // Monitor config to access BFM
    fwvip_wb_monitor_config       m_cfg;
    uvm_analysis_port #(fwvip_wb_transaction) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(fwvip_wb_monitor_config)::get(this, "", "cfg", m_cfg)) begin
            `uvm_fatal(get_name(), "fwvip_wb_monitor: missing cfg")
        end
    endfunction

    task run_phase(uvm_phase phase);
        fwvip_wb_transaction t;
        bit[ADDR_WIDTH_MAX-1:0]     adr;
        bit[DATA_WIDTH_MAX-1:0]     dat;
        bit[(DATA_WIDTH_MAX/8)-1:0] sel;
        bit                          we;
        bit                          err;

        m_cfg.wait_reset();
        forever begin
            m_cfg.wait_txn(adr, dat, sel, we, err);
            t = fwvip_wb_transaction::type_id::create("t");
            t.adr = adr;
            t.dat = dat;
            t.sel = sel;
            t.we  = we;
            t.err = err;
            ap.write(t);
        end
    endtask

endclass
