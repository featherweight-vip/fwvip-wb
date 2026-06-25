
// ----------------------------------------------------------------------------
// Base UVM test for the Wishbone VIP.
//
// All simulation tests use this single test class; the scenario is selected at
// run time by the +SEQ=<vseq-type-name> plusarg (default: fwvip_wb_vseq_smoke).
// The named virtual sequence is created via the factory and run on the env's
// virtual sequencer. Per-scenario knobs are passed as additional plusargs
// (e.g. +NUM_TXNS, +BASE_ADDR) and read by the virtual sequence itself.
//
// Each DFM "test" task is therefore just this image invoked with a different
// +SEQ= (and optional knob) plusargs -- see tests/uvm/tests/flow.yaml.
// ----------------------------------------------------------------------------
class fwvip_wb_test_base extends uvm_test;
    `uvm_component_utils(fwvip_wb_test_base)

    fwvip_wb_env            m_env;
    fwvip_wb_mon_sub        m_mon_sub;

    string                  m_seq_name = "fwvip_wb_vseq_smoke";

    function new(string name="fwvip_wb_test_base", uvm_component parent=null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        m_env     = fwvip_wb_env::type_id::create("m_env", this);
        m_mon_sub = fwvip_wb_mon_sub::type_id::create("m_mon_sub", this);
        void'($value$plusargs("SEQ=%s", m_seq_name));
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        m_env.m_mon.ap.connect(m_mon_sub.analysis_export);
    endfunction

    task run_phase(uvm_phase phase);
        uvm_factory       factory = uvm_factory::get();
        uvm_object        obj;
        fwvip_wb_vseq_base vseq;

        phase.raise_objection(this, m_seq_name);

        obj = factory.create_object_by_name(m_seq_name, get_full_name(), "vseq");
        if (obj == null || !$cast(vseq, obj)) begin
            `uvm_fatal(get_type_name(),
                $sformatf("Could not create virtual sequence '%s' (not a fwvip_wb_vseq_base?)",
                          m_seq_name))
        end

        `uvm_info(get_type_name(), $sformatf("Running virtual sequence '%s'", m_seq_name), UVM_LOW)
        vseq.start(m_env.m_vseqr);

        // Allow in-flight responses/monitor traffic to drain
        #1us;

        phase.drop_objection(this, m_seq_name);
    endtask

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info(get_type_name(),
            $sformatf("Monitor observed %0d transactions", m_mon_sub.txn_count), UVM_LOW)
        if (m_mon_sub.txn_count == 0) begin
            `uvm_error(get_type_name(), "Monitor did not observe any transactions")
        end
    endfunction

endclass
