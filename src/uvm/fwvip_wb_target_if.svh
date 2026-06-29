
// ----------------------------------------------------------------------------
// Target responder API (VIP-local, MAX-width / transaction-carried).
//
// A target responder sequence IMPLEMENTS this. The target driver fetches the
// responder via the sequencer (get_next_item) and calls access() on it for each
// observed Wishbone request -- i.e. the responder is *called* (the kit's
// wb_target_xtor_bridge polls the FIFOs and drives the access() callback chain),
// rather than the sequence polling the bus.
//
// This is the MAX-width, transaction-carried mirror of the kit's exact-width
// wb_proto_if#(AW,DW): fwvip_wb_target_config_p bridges the two (Decision D4 --
// the *_WIDTH_MAX sizing is a consumer concern).
// ----------------------------------------------------------------------------
interface class fwvip_wb_target_if;
    pure virtual task access(fwvip_wb_transaction t);
endclass
