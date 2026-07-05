
typedef class fwvip_wb_initiator_config;
typedef class fwvip_wb_initiator_driver;
typedef class fwvip_wb_transaction;

class fwvip_wb_initiator extends uvm_agent;
    `uvm_component_utils(fwvip_wb_initiator)

    fwvip_wb_initiator_config               m_cfg;
    uvm_sequencer #(fwvip_wb_transaction)   m_seqr;
    fwvip_wb_initiator_driver               m_driver;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(fwvip_wb_initiator_config)::get(this, "", "cfg", m_cfg))
            `uvm_fatal(get_type_name(), "no fwvip_wb_initiator_config in config DB")
        m_seqr = uvm_sequencer #(fwvip_wb_transaction)::type_id::create("m_seqr", this);
        m_driver = fwvip_wb_initiator_driver::type_id::create("m_driver", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        m_driver.seq_item_port.connect(m_seqr.seq_item_export);
    endfunction

endclass