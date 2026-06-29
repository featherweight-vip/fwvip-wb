
// ----------------------------------------------------------------------------
// Virtual sequencer for the Wishbone VIP environment.
//
// Holds handles to the initiator and target sub-sequencers and to the
// initiator config (for reset synchronization). Virtual sequences run on this
// sequencer and coordinate stimulus on the initiator while a responder runs on
// the target.
// ----------------------------------------------------------------------------
class fwvip_wb_vseqr extends uvm_sequencer;
    `uvm_component_utils(fwvip_wb_vseqr)

    // Sub-sequencers coordinated by virtual sequences
    uvm_sequencer #(fwvip_wb_transaction)   init_seqr;
    // Target sub-sequencer item type is the responder wrapper (see fwvip_wb_target).
    uvm_sequencer #(fwvip_wb_target_item)   targ_seqr;

    // Initiator config (legacy handle; reset sync now goes through the core
    // reset provider below).
    fwvip_wb_initiator_config               init_cfg;

    // Core clock/reset providers, sourced from the config DB by the env. The
    // base virtual sequence waits on reset_provider before driving; sequences
    // may also pace themselves on clock_provider.tick().
    fwvip_wait_reset_if                     reset_provider;
    fwvip_clock_if                          clock_provider;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

endclass
