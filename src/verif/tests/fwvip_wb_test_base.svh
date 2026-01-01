
class fwvip_wb_test_base extends uvm_test;
    `uvm_component_utils(fwvip_wb_test_base)
    fwvip_wb_env            m_env;
    fwvip_wb_mon_sub        m_mon_sub;

    function new(string name="fwvip_wb_test_base", uvm_component parent=null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        m_env = fwvip_wb_env::type_id::create("m_env", this);
        m_mon_sub = fwvip_wb_mon_sub::type_id::create("m_mon_sub", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        m_env.m_mon.ap.connect(m_mon_sub.analysis_export);
    endfunction

endclass
