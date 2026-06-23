
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
    uvm_sequencer #(fwvip_wb_transaction)   targ_seqr;

    // Initiator config, used for clock/reset synchronization helpers
    fwvip_wb_initiator_config               init_cfg;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

endclass
