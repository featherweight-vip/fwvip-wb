
typedef class fwvip_wb_target_config;
typedef class fwvip_wb_target_driver;
typedef class fwvip_wb_transaction;

class fwvip_wb_target extends uvm_agent;
    `uvm_component_utils(fwvip_wb_target)

    fwvip_wb_target_config               m_cfg;
    uvm_sequencer #(fwvip_wb_transaction)   m_seqr;
    fwvip_wb_target_driver               m_driver;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        $display("get_full_name: %0s", get_full_name());
        if (!uvm_config_db #(fwvip_wb_target_config)::get(this, "", "cfg", m_cfg)) begin
            $display("Failed to get config");
        end else begin
            $display("Got config");
        end
        m_seqr = uvm_sequencer #(fwvip_wb_transaction)::type_id::create("m_seqr", this);
        m_driver = fwvip_wb_target_driver::type_id::create("m_driver", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        m_driver.seq_item_port.connect(m_seqr.seq_item_export);
    endfunction

endclass