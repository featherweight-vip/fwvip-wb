
class fwvip_wb_test_init extends fwvip_wb_test_base;
    `uvm_component_utils(fwvip_wb_test_init)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        fwvip_wb_initiator_seq seq = new();
        $display("run_phase");
        phase.raise_objection(this, "");
        $display("--> wait_reset");
        m_env.m_init.m_cfg.wait_reset();
        $display("<-- wait_reset %0t", $time);
        seq.start(m_env.m_init.m_seqr);
        #1ms;
        phase.drop_objection(this, "");
        $display("<- run_phase %0t", $time);
    endtask


endclass
