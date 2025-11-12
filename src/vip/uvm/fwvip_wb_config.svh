
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
//    typedef virtual fwvip_wb_initiator_if #(ADDR_WIDTH, DATA_WIDTH) vif_t;
    typedef fwvip_wb_initiator_config_p #(vif_t, ADDR_WIDTH,DATA_WIDTH) this_t;
//    virtual fwvip_wb_initiator_if #(ADDR_WIDTH, DATA_WIDTH) vif;
    vif_t       vif;

//    function new(virtual fwvip_wb_initiator_if #(ADDR_WIDTH,DATA_WIDTH) vif);
//        super.new("abc");
//        this.vif = vif;
//    endfunction

    static function void set(
        uvm_component ctxt, 
        string inst, 
        string field, 
        vif_t vif);
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

    virtual task wait_reset();
        vif.wait_reset();
    endtask

endclass


