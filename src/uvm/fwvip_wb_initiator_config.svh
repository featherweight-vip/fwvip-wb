
typedef class fwvip_wb_initiator_driver;

class fwvip_wb_initiator_config extends uvm_object;
    `uvm_object_utils(fwvip_wb_initiator_config)

    function new(string name="fwvip_wb_initiator_config");
        super.new(name);
    endfunction

    virtual function int getADDR_WIDTH();
        return -1;
    endfunction

    virtual function int getDATA_WIDTH();
        return -1;
    endfunction

    virtual task access(fwvip_wb_transaction t);
    endtask

    virtual task wait_reset();
    endtask

endclass

class fwvip_wb_initiator_config_p #(type vif_t=int, int ADDR_WIDTH=32, int DATA_WIDTH=32) 
    extends fwvip_wb_initiator_config;
    typedef fwvip_wb_initiator_config_p #(vif_t, ADDR_WIDTH,DATA_WIDTH) this_t;
    vif_t       vif;

    static function void set(uvm_component ctxt, string inst, string field, vif_t vif);
        this_t cfg = new();
        cfg.vif = vif;
        uvm_config_db #(fwvip_wb_initiator_config)::set(ctxt, inst, field, cfg);
    endfunction

    virtual task access(fwvip_wb_transaction t);
        bit[DATA_WIDTH_MAX-1:0] dat_t;
        vif.request(t.adr, t.dat, t.sel, t.we);
        vif.response(dat_t, t.err);

        if (!t.we) begin
            t.dat = dat_t;
        end
    endtask

    // NOTE: reset synchronization is no longer the initiator config's job. The
    // env sources an independent fwvip-core reset provider (fwvip_wait_reset_if)
    // from the UVM config DB and the base virtual sequence waits on that. The
    // old fixed-delay wait_reset workaround has been removed; the inherited
    // base wait_reset() is a harmless no-op kept only for API compatibility.

endclass


// Access-based specialization: instead of driving a signal-level xtor interface
// via request()/response() (config_p above), it HOLDS a wb_proto_if #(AW,DW)
// handle and drives each transaction through the kit's canonical access() seam --
// the same interface-class the target config consumes. Because any wb_proto_if
// implementer satisfies it, one env binds either a signal-level path (a
// wb_initiator_xtor_bridge wrapping the host xtor's u_if) or a pure class model
// (a wb_mem_target wrapping the design's fw_mem_if) with no code change -- the
// duck-typed seam is the method call access().
class fwvip_wb_initiator_config_ap #(int ADDR_WIDTH=32, int DATA_WIDTH=32)
    extends fwvip_wb_initiator_config;
    typedef fwvip_wb_initiator_config_ap #(ADDR_WIDTH, DATA_WIDTH) this_t;
    wb_proto_if #(ADDR_WIDTH, DATA_WIDTH) vif;

    static function void set(uvm_component ctxt, string inst, string field,
                             wb_proto_if #(ADDR_WIDTH, DATA_WIDTH) vif);
        this_t cfg = new();
        cfg.vif = vif;
        uvm_config_db #(fwvip_wb_initiator_config)::set(ctxt, inst, field, cfg);
    endfunction

    virtual function int getADDR_WIDTH(); return ADDR_WIDTH; endfunction
    virtual function int getDATA_WIDTH(); return DATA_WIDTH; endfunction

    virtual task access(fwvip_wb_transaction t);
        bit [DATA_WIDTH-1:0] dat_r;
        bit                  err;
        vif.access(t.adr[ADDR_WIDTH-1:0], t.dat[DATA_WIDTH-1:0],
                   t.sel[(DATA_WIDTH/8)-1:0], t.we, dat_r, err);
        t.err = err;
        if (!t.we) t.dat = dat_r;
    endtask

endclass


