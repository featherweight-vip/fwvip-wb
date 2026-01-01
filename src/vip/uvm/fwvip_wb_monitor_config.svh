typedef class fwvip_wb_monitor;

class fwvip_wb_monitor_config extends uvm_object;
    `uvm_object_utils(fwvip_wb_monitor_config)

    function new(string name="fwvip_wb_monitor_config");
        super.new(name);
    endfunction

    virtual task wait_reset(); endtask
    virtual task wait_txn(
        output bit[ADDR_WIDTH_MAX-1:0]     adr,
        output bit[DATA_WIDTH_MAX-1:0]     dat,
        output bit[(DATA_WIDTH_MAX/8)-1:0] sel,
        output bit                         we,
        output bit                         err);
    endtask
endclass

class fwvip_wb_monitor_config_p #(type vif_t=int) extends fwvip_wb_monitor_config;
    typedef fwvip_wb_monitor_config_p #(vif_t) this_t;
    vif_t vif;

    static function void set(uvm_component ctxt, string inst, string field, vif_t vif);
        this_t cfg = new();
        cfg.vif = vif;
        uvm_config_db #(fwvip_wb_monitor_config)::set(ctxt, inst, field, cfg);
    endfunction

    virtual task wait_reset();
        vif.wait_reset();
    endtask

    virtual task wait_txn(
        output bit[ADDR_WIDTH_MAX-1:0]     adr,
        output bit[DATA_WIDTH_MAX-1:0]     dat,
        output bit[(DATA_WIDTH_MAX/8)-1:0] sel,
        output bit                         we,
        output bit                         err);
        vif.wait_txn(adr, dat, sel, we, err);
    endtask
endclass
