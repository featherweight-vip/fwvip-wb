
typedef class fwvip_wb_target_driver;

typedef struct {
    int ADDR_WIDTH;
    int DATA_WIDTH;
} fwvip_wb_target_params_s;

class fwvip_wb_target_config extends uvm_object;
    `uvm_object_utils(fwvip_wb_target_config)

    function new(string name="fwvip_wb_target_config");
        super.new(name);
    endfunction

    virtual function fwvip_wb_target_params_s get_params();
    endfunction

    virtual function int getADDR_WIDTH();
        return -1;
    endfunction

    virtual function int getDATA_WIDTH();
        return -1;
    endfunction

    // Kick off the target bridge that polls the transactor FIFOs and drives the
    // access() callback. Called from the driver's run_phase (the driver supplies
    // itself so the bridge->access path can rendezvous with the sequencer).
    virtual task start(fwvip_wb_target_driver drv);
    endtask

    virtual task wait_reset();
    endtask

endclass

// The width-aware specialization. It IS the wb_proto_if#(AW,DW) handler the
// kit's wb_target_xtor_bridge calls, and it bridges the exact-width kit API to
// the MAX-width, transaction-carried responder API consumed via the driver.
class fwvip_wb_target_config_p #(type vif_t=int, int ADDR_WIDTH=32, int DATA_WIDTH=32)
    extends fwvip_wb_target_config
    implements wb_proto_if #(ADDR_WIDTH, DATA_WIDTH);
    typedef fwvip_wb_target_config_p #(vif_t, ADDR_WIDTH,DATA_WIDTH) this_t;
    vif_t                                            vif;
    wb_target_xtor_bridge #(ADDR_WIDTH, DATA_WIDTH)  m_bridge;
    fwvip_wb_target_driver                           m_drv;

    static function void set(uvm_component ctxt, string inst, string field, vif_t vif);
        this_t cfg = new();
        cfg.vif = vif;
        uvm_config_db #(fwvip_wb_target_config)::set(ctxt, inst, field, cfg);
    endfunction

    virtual function fwvip_wb_target_params_s get_params();
        fwvip_wb_target_params_s params;
        params.ADDR_WIDTH = ADDR_WIDTH;
        params.DATA_WIDTH = DATA_WIDTH;
        return params;
    endfunction

    virtual function int getADDR_WIDTH();
        return ADDR_WIDTH;
    endfunction

    virtual function int getDATA_WIDTH();
        return DATA_WIDTH;
    endfunction

    virtual task start(fwvip_wb_target_driver drv);
        m_drv    = drv;
        m_bridge = new(vif, this);   // bridge holds the vif + this as target_if
        m_bridge.start();            // forks: wait_req -> access() -> send_rsp
    endtask

    // wb_proto_if#(AW,DW) -- the bridge "calls us" here for each request, in
    // exact widths. Adapt to/from the MAX-width transaction and hand it to the
    // responder via the driver's sequencer handshake.
    virtual task access(
            input  [ADDR_WIDTH-1:0]      adr,
            input  [DATA_WIDTH-1:0]      dat_w,
            input  [(DATA_WIDTH/8)-1:0]  sel,
            input                        we,
            output [DATA_WIDTH-1:0]      dat_r,
            output                       err);
        fwvip_wb_transaction t = fwvip_wb_transaction::type_id::create("t");
        t.adr = adr;
        t.dat = dat_w;
        t.sel = sel;
        t.we  = we;
        m_drv.service(t);            // get_next_item -> responder.access -> item_done
        dat_r = t.dat[DATA_WIDTH-1:0];
        err   = t.err;
    endtask

    virtual task wait_reset();
        vif.wait_reset();
    endtask

endclass


// Client-registered specialization: instead of routing each captured request
// through the driver/sequencer (config_p above), it holds a REGISTERED wb_proto_if
// client (the responder -- a sequence or model that implements access()) and, on
// start(), wires the kit converter (wb_target_xtor_bridge) straight to it: the
// converter polls the transactor FIFOs and drives an active access() call into the
// client. So a sequence becomes a WB target simply by implementing wb_proto_if.
// The SAME client can be reached directly (no converter) on the TLM path via an
// fw_export connector -- one responder, per-flavour connectors.
class fwvip_wb_target_config_ap #(int ADDR_WIDTH=32, int DATA_WIDTH=32)
    extends fwvip_wb_target_config;
    typedef fwvip_wb_target_config_ap #(ADDR_WIDTH, DATA_WIDTH) this_t;
    virtual wb_target_xtor_if #(ADDR_WIDTH, DATA_WIDTH) vif;
    wb_proto_if #(ADDR_WIDTH, DATA_WIDTH)               client;   // registered responder
    wb_target_xtor_bridge #(ADDR_WIDTH, DATA_WIDTH)     m_conv;   // the converter

    static function void set(uvm_component ctxt, string inst, string field,
                             virtual wb_target_xtor_if #(ADDR_WIDTH, DATA_WIDTH) vif,
                             wb_proto_if #(ADDR_WIDTH, DATA_WIDTH) client);
        this_t cfg = new();
        cfg.vif    = vif;
        cfg.client = client;
        uvm_config_db #(fwvip_wb_target_config)::set(ctxt, inst, field, cfg);
    endfunction

    virtual function fwvip_wb_target_params_s get_params();
        fwvip_wb_target_params_s params;
        params.ADDR_WIDTH = ADDR_WIDTH;
        params.DATA_WIDTH = DATA_WIDTH;
        return params;
    endfunction

    virtual function int getADDR_WIDTH(); return ADDR_WIDTH; endfunction
    virtual function int getDATA_WIDTH(); return DATA_WIDTH; endfunction

    // Converter: wait_req -> client.access() -> send_rsp. No driver/sequencer.
    virtual task start(fwvip_wb_target_driver drv);
        m_conv = new(vif, client);
        m_conv.start();
    endtask

    virtual task wait_reset();
        vif.wait_reset();
    endtask

endclass
