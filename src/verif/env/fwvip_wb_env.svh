
class fwvip_wb_env extends uvm_component;
    `uvm_component_utils(fwvip_wb_env)

    fwvip_wb_initiator          m_init;
    fwvip_wb_target             m_targ;
    fwvip_wb_monitor_agent      m_mon;

    // Virtual sequencer + reusable scoreboard
    fwvip_wb_vseqr              m_vseqr;
    fwvip_wb_scoreboard         m_sb;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        m_init  = fwvip_wb_initiator::type_id::create("m_init", this);
        m_targ  = fwvip_wb_target::type_id::create("m_targ", this);
        m_mon   = fwvip_wb_monitor_agent::type_id::create("m_mon", this);
        m_vseqr = fwvip_wb_vseqr::type_id::create("m_vseqr", this);
        m_sb    = fwvip_wb_scoreboard::type_id::create("m_sb", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        // Wire the virtual sequencer to the sub-sequencers and initiator config
        m_vseqr.init_seqr = m_init.m_seqr;
        m_vseqr.targ_seqr = m_targ.m_seqr;
        m_vseqr.init_cfg  = m_init.m_cfg;
        // Monitor stream feeds the scoreboard
        m_mon.ap.connect(m_sb.analysis_export);
    endfunction

endclass
