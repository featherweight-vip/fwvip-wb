
typedef class fwvip_wb_target_config;
typedef class fwvip_wb_target_driver;
typedef class fwvip_wb_transaction;

class fwvip_wb_target extends uvm_agent;
    `uvm_component_utils(fwvip_wb_target)

    fwvip_wb_target_config               m_cfg;
    // The sequencer item is the responder wrapper (it implements
    // fwvip_wb_target_if), so the driver's get_next_item yields a callable handler.
    uvm_sequencer #(fwvip_wb_target_item)   m_seqr;
    fwvip_wb_target_driver               m_driver;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(fwvip_wb_target_config)::get(this, "", "cfg", m_cfg))
            `uvm_fatal(get_type_name(), "no fwvip_wb_target_config in config DB")
        m_seqr = uvm_sequencer #(fwvip_wb_target_item)::type_id::create("m_seqr", this);
        m_driver = fwvip_wb_target_driver::type_id::create("m_driver", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        m_driver.seq_item_port.connect(m_seqr.seq_item_export);
    endfunction

endclass