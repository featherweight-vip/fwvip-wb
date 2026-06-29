
typedef class fwvip_wb_transaction;
typedef class fwvip_wb_initiator_config_p;

class fwvip_wb_initiator_driver extends uvm_driver #(fwvip_wb_transaction);
    `uvm_component_utils(fwvip_wb_initiator_driver)

    fwvip_wb_initiator_config                   m_cfg;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(fwvip_wb_initiator_config)::get(this, "", "cfg", m_cfg)) begin
            $display("Failed to get config");
        end else begin
            $display("Got config");
        end
    endfunction

    task run_phase(uvm_phase phase);
        fwvip_wb_transaction t;
        forever begin
            $display("--> driver.get");
            seq_item_port.get_next_item(t);
            $display("<-- driver.get");
            $display("--> access");
            m_cfg.access(t);
            $display("<-- access");
            seq_item_port.item_done();
        end
    endtask


endclass