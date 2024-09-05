
package fwvip_wb_pkg;
    import fwvip_pkg::*;

    class fwvip_wb_initiator_api implements fwvip_mem_api;
        string          path;

        function new(string path);
            this.path = path;
        endfunction

        virtual function int addr_width();
            return -1;
        endfunction

        virtual function int data_width();
            return -1;
        endfunction

        virtual task read8(
            output bit[7:0]     data,
            input bit[63:0]     addr);
        endtask

        virtual task read16(
            output bit[15:0]    data,
            input bit[63:0]     addr);
        endtask

        virtual task read32(
            output bit[31:0]    data,
            input bit[63:0]     addr);
        endtask

        virtual task read64(
            output bit[63:0]    data,
            input bit[63:0]     addr);
        endtask

        virtual task write8(
            input bit[7:0]      data,
            input bit[63:0]     addr);
        endtask

        virtual task write16(
            input bit[15:0]     data,
            input bit[63:0]     addr);
        endtask

        virtual task write32(
            input bit[31:0]     data,
            input bit[63:0]     addr);
        endtask

        virtual task write64(
            input bit[63:0]    data,
            input bit[63:0]     addr);
        endtask

    endclass

    class fwvip_wb_initiator_api_p #(type vif_t=int, int ADDR_WIDTH=32, int DATA_WIDTH=32) extends fwvip_wb_initiator_api;
//        typedef fwvip_wb_initiator_api_p #(vif_t, ADDR_WIDTH, DATA_WIDTH) this_t;
        vif_t vif;

        function new(vif_t vif, string path);
            super.new(path);
            this.vif = vif;
        endfunction

        virtual function int addr_width();
            return ADDR_WIDTH;
        endfunction

        virtual function int data_width();
            return DATA_WIDTH;
        endfunction

        virtual task read8(
            output bit[7:0]     data,
            input bit[63:0]     addr);
            vif.queue_req(0, 0);
        endtask

        virtual task read16(
            output bit[15:0]    data,
            input bit[63:0]     addr);
        endtask

        virtual task read32(
            output bit[31:0]    data,
            input bit[63:0]     addr);
        endtask

        virtual task read64(
            output bit[63:0]    data,
            input bit[63:0]     addr);
        endtask

        virtual task write8(
            input bit[7:0]      data,
            input bit[63:0]     addr);
            bit err;
            bit [DATA_WIDTH-1:0] dat_r;
            vif.queue_req(0, 0);
            vif.wait_ack(dat_r, err);
        endtask

        virtual task write16(
            input bit[15:0]     data,
            input bit[63:0]     addr);
        endtask

        virtual task write32(
            input bit[31:0]     data,
            input bit[63:0]     addr);
        endtask

        virtual task write64(
            input bit[63:0]    data,
            input bit[63:0]     addr);
        endtask

//        static function void register(vif_t vif);
//            this_t api = new(vif);
//        endfunction

    endclass

    class fwvip_wb_initiator_bundle;
        fwvip_wb_initiator_api              insts[];

        function void fwvip_wb_initiator_resize(int size);
            insts = new[size](insts);
        endfunction

        function void fwvip_wb_initiator_set_inst(
            int                     inst_id,
            fwvip_wb_initiator_api  inst);
            insts[inst_id] = inst;
        endfunction

        virtual function int fwvip_wb_initiator_addr_width(int inst_id);
            return insts[inst_id].addr_width();
        endfunction

        virtual function int fwvip_wb_initiator_data_width(int inst_id);
            return insts[inst_id].data_width();
        endfunction

        virtual task fwvip_wb_initiator_read8(
            input int           inst_id,
            output bit[7:0]     data,
            input bit[63:0]     addr);
            insts[inst_id].read8(data, addr);
        endtask

        virtual task fwvip_wb_initiator_read16(
            input int           inst_id,
            output bit[15:0]    data,
            input bit[63:0]     addr);
            insts[inst_id].read16(data, addr);
        endtask

        virtual task fwvip_wb_initiator_read32(
            input int           inst_id,
            output bit[31:0]    data,
            input bit[63:0]     addr);
            insts[inst_id].read32(data, addr);
        endtask

        virtual task fwvip_wb_initiator_read64(
            input int           inst_id,
            output bit[63:0]    data,
            input bit[63:0]     addr);
            insts[inst_id].read64(data, addr);
        endtask

        virtual task fwvip_wb_initiator_write8(
            input int           inst_id,
            input bit[7:0]      data,
            input bit[63:0]     addr);
            insts[inst_id].write8(data, addr);
        endtask

        virtual task fwvip_wb_initiator_write16(
            input int           inst_id,
            input bit[15:0]     data,
            input bit[63:0]     addr);
            insts[inst_id].write16(data, addr);
        endtask

        virtual task fwvip_wb_initiator_write32(
            input int           inst_id,
            input bit[31:0]     data,
            input bit[63:0]     addr);
            insts[inst_id].write32(data, addr);
        endtask

        virtual task fwvip_wb_initiator_write64(
            input int           inst_id,
            input bit[63:0]     data,
            input bit[63:0]     addr);
            insts[inst_id].write64(data, addr);
        endtask

    endclass

    fwvip_wb_initiator_api      prv_initiator_rgy[string];
    fwvip_wb_initiator_api      prv_initiator_bfms[$];

    function void register_initiator(fwvip_wb_initiator_api api);
        prv_initiator_rgy[api.path] = api;
        prv_initiator_bfms.push_back(api);
    endfunction

    function automatic fwvip_wb_initiator_api get_initiator(
        string          path,
        bit             suffix);
        fwvip_wb_initiator_api ret;;
        if (suffix) begin
            foreach (prv_initiator_bfms[i]) begin
                string bfm_path = prv_initiator_bfms[i].path;
                if (path.len() <= bfm_path.len()) begin
                    int x;
                    for (x=0; x<path.len(); x++) begin
                        if (path[path.len()-x-1] != bfm_path[bfm_path.len()-x-1]) begin
                            break;
                        end
                    end
                    if (x == path.len()) begin
                        ret = prv_initiator_bfms[i];
                        break;
                    end
                end
            end
        end else if (prv_initiator_rgy.exists(path)) begin
            ret = prv_initiator_rgy[path];
        end
        return ret;
    endfunction


endpackage

