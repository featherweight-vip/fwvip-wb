
class fwvip_wb_test_init extends fwvip_wb_test_base;
    `uvm_component_utils(fwvip_wb_test_init)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        fwvip_wb_initiator_seq seq = new();
        fwvip_wb_target_seq tseq = new();
        $display("run_phase");
        phase.raise_objection(this, "");
        $display("--> wait_reset");
        m_env.m_init.m_cfg.wait_reset();
        $display("<-- wait_reset %0t", $time);
        $display("--> start responder");
        fork
            tseq.start(m_env.m_targ.m_seqr);    
        join_none
        $display("<-- start responder");

        repeat (16) begin
            seq.t.adr += 4;
            seq.t.dat += 1;
            seq.t.we = 1;
            $display("--> start");
            seq.start(m_env.m_init.m_seqr);
            $display("<-- start");
        end
        #1ms;
        phase.drop_objection(this, "");
        $display("<- run_phase %0t", $time);
    endtask


endclass
