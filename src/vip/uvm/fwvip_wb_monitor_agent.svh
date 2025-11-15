typedef class fwvip_wb_monitor;

class fwvip_wb_monitor_agent extends uvm_agent;
    `uvm_component_utils(fwvip_wb_monitor_agent)

    uvm_analysis_port #(fwvip_wb_transaction) ap;
    fwvip_wb_monitor_config                  m_cfg;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(fwvip_wb_monitor_config)::get(this, "", "cfg", m_cfg)) begin
            `uvm_fatal(get_name(), "fwvip_wb_monitor_agent: missing cfg")
        end
    endfunction

    // Continuously read from transactor and write to analysis port
    task run_phase(uvm_phase phase);
        bit[ADDR_WIDTH_MAX-1:0]     adr;
        bit[DATA_WIDTH_MAX-1:0]     dat;
        bit[(DATA_WIDTH_MAX/8)-1:0] sel;
        bit                          we;
        bit                          err;
        m_cfg.wait_reset();
        forever begin
            fwvip_wb_transaction t;
            m_cfg.wait_txn(adr, dat, sel, we, err);
            t = fwvip_wb_transaction::type_id::create("t", this);
            t.adr = adr;
            t.dat = dat;
            t.sel = sel;
            t.we  = we;
            t.err = err;
            ap.write(t);
        end
    endtask
endclass
