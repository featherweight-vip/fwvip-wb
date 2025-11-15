
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

    virtual task wait_req(fwvip_wb_transaction t);
    endtask

    virtual task send_rsp(fwvip_wb_transaction t);
    endtask

    virtual task wait_reset();
    endtask

endclass

class fwvip_wb_target_config_p #(type vif_t=int, int ADDR_WIDTH=32, int DATA_WIDTH=32) 
    extends fwvip_wb_target_config;
    typedef fwvip_wb_target_config_p #(vif_t, ADDR_WIDTH,DATA_WIDTH) this_t;
    vif_t       vif;

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

    virtual task wait_req(fwvip_wb_transaction t);
        vif.wait_req(t.adr, t.dat, t.sel, t.we);
    endtask

    virtual task send_rsp(fwvip_wb_transaction t);
        vif.send_rsp(t.dat, t.err);
    endtask

    virtual task wait_reset();
        vif.wait_reset();
    endtask

endclass


