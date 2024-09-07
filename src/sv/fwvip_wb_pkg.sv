
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

        virtual task wait_reset();
        endtask

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

        virtual task wait_reset();
            vif.wait_reset();
        endtask

        function bit[DATA_WIDTH/8-1:0] stb(
            input bit[ADDR_WIDTH-1:0]   addr,
            input bit[3:0]              size);
            case (size) 
                1: stb = (DATA_WIDTH>8)?(1'b1 << addr[DATA_WIDTH/16-1:0]):1'b1;
                2: stb = (DATA_WIDTH>16)?(2'b11 << {addr[DATA_WIDTH/16-1:1], 1'b0}):2'b11;
                4: stb = (DATA_WIDTH>32)?(4'b1111 << {addr[DATA_WIDTH/16-1:2], 2'b00}):4'b1111;
                8: stb = (DATA_WIDTH>64)?(8'b11111111 << {addr[DATA_WIDTH/16-1:3], 3'b000}):8'b11111111;
            endcase
        endfunction

        function bit[63:0] extract_data(
            input bit[DATA_WIDTH-1:0]   data,
            input bit[ADDR_WIDTH-1:0]   addr,
            input bit[3:0]              size);
            if (size < DATA_WIDTH/8) begin
                case (size) 
                    1: extract_data = data[8*addr[1:0]+:8];
                    2: extract_data = data[16*addr[1:1]+:16];
                    4: extract_data = data[32*addr[2:1]+:32];
                endcase
            end else begin
                return data;
            end
        endfunction

        function bit[DATA_WIDTH-1:0] format_data(
            input bit[63:0]             data,
            input bit[ADDR_WIDTH-1:0]   addr,
            input bit[3:0]              size);
            if (size < DATA_WIDTH/8) begin
                case (size) 
                    1: format_data = {DATA_WIDTH/8{data[8*addr[1:0]+:8]}};
                    2: format_data = {DATA_WIDTH/16{data[16*addr[1:1]+:16]}};
                    4: format_data = {DATA_WIDTH/32{data[32*addr[2:1]+:32]}};
                endcase
            end else begin
                return data;
            end
        endfunction

        virtual task read8(
            output bit[7:0]     data,
            input bit[63:0]     addr);
            bit[DATA_WIDTH-1:0] data_tmp;
            bit err;
            vif.queue_req(addr, 0, {DATA_WIDTH/8{1'b1}}, 0);
            vif.wait_ack(data_tmp, err);
            data = extract_data(data_tmp, addr, 1);
        endtask

        virtual task read16(
            output bit[15:0]    data,
            input bit[63:0]     addr);
            bit[DATA_WIDTH-1:0] data_tmp;
            bit err;
            vif.queue_req(addr, 0, {DATA_WIDTH/8{1'b1}}, 0);
            vif.wait_ack(data_tmp, err);
            data = extract_data(data_tmp, addr, 2);
        endtask

        virtual task read32(
            output bit[31:0]    data,
            input bit[63:0]     addr);
            bit[DATA_WIDTH-1:0] data_tmp;
            bit err;
            vif.queue_req(addr, 0, {DATA_WIDTH/8{1'b1}}, 0);
            vif.wait_ack(data_tmp, err);
            data = extract_data(data_tmp, addr, 4);
        endtask

        virtual task read64(
            output bit[63:0]    data,
            input bit[63:0]     addr);
            bit[DATA_WIDTH-1:0] data_tmp;
            bit err;
            vif.queue_req(addr, 0, {DATA_WIDTH/8{1'b1}}, 0);
            vif.wait_ack(data_tmp, err);
            data = extract_data(data_tmp, addr, 8);
        endtask

        virtual task write8(
            input bit[7:0]      data,
            input bit[63:0]     addr);
            bit [DATA_WIDTH-1:0] data_r;
            bit err;
            vif.queue_req(addr, format_data(data, addr, 1), stb(addr, 1), 1);
            vif.wait_ack(data_r, err);
        endtask

        virtual task write16(
            input bit[15:0]     data,
            input bit[63:0]     addr);
            bit [DATA_WIDTH-1:0] data_r;
            bit err;
            vif.queue_req(addr, format_data(data, addr, 2), stb(addr, 2), 1);
            vif.wait_ack(data_r, err);
        endtask

        virtual task write32(
            input bit[31:0]     data,
            input bit[63:0]     addr);
            bit [DATA_WIDTH-1:0] data_r;
            bit err;
            vif.queue_req(addr, format_data(data, addr, 4), stb(addr, 4), 1);
            vif.wait_ack(data_r, err);
        endtask

        virtual task write64(
            input bit[63:0]    data,
            input bit[63:0]     addr);
            bit [DATA_WIDTH-1:0] data_r;
            bit err;
            vif.queue_req(addr, format_data(data, addr, 8), stb(addr, 8), 1);
            vif.wait_ack(data_r, err);
        endtask

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

    `fwvip_bfm_rgy_decl(fwvip_wb, initiator, fwvip_wb_initiator_api);


endpackage

