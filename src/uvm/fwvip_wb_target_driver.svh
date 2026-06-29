
typedef class fwvip_wb_transaction;
typedef class fwvip_wb_target_config;
typedef class fwvip_wb_target_item;

// The target driver no longer polls the bus itself: it starts the kit bridge
// (via the config) which polls the transactor FIFOs and calls config.access()
// for each request. config.access() funnels back here through service(), which
// fetches the responder item from the sequencer and lets it handle the access.
// The sequencer item carries a handle to the responder and implements
// fwvip_wb_target_if, so get_next_item yields something we can call access() on.
class fwvip_wb_target_driver extends uvm_driver #(fwvip_wb_target_item);
    `uvm_component_utils(fwvip_wb_target_driver)

    fwvip_wb_target_config                   m_cfg;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(fwvip_wb_target_config)::get(this, "", "cfg", m_cfg)) begin
            `uvm_fatal(get_name(), "Failed to get config");
        end
    endfunction

    task run_phase(uvm_phase phase);
        // Start the bridge (it forks its own wait_req->access->send_rsp loop) and
        // stay resident so that forked process lives for the whole run phase.
        m_cfg.start(this);
        wait fork;
    endtask

    // Called from config.access() (in the bridge's thread) for each observed
    // request: rendezvous with the responder sequence and let it fill the
    // response into the transaction.
    task service(fwvip_wb_transaction t);
        fwvip_wb_target_item it;
        seq_item_port.get_next_item(it);
        it.access(t);
        seq_item_port.item_done();
    endtask

endclass
