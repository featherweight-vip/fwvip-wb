
`include "svt_macros.svh"
package initiator_test_pkg;
    import svt_pkg::*;
    import fwvip_wb_pkg::*;

    `include "test_basic_rw.svh"

    class my_test extends svt_test;
        `svt_test_decl(my_test)

        function new(string name);
            super.new(name);
        endfunction

        virtual function void build();
//            $display("%0d BFMs", prv_initiator_bfms.size());
        endfunction

        virtual task run(svt_barrier barrier);
            fwvip_wb_initiator_api api;
            bit[7:0] data;
            barrier.raise_objection();
            $display("run");
//            $display("%0d BFMs", prv_initiator_bfms.size());
            api = fwvip_wb_initiator_rgy.get("initiator_tb.initiator", 1);
            api.wait_reset();
            api.write8(8, 25);
            api.read8(data, 25);
            $display("data: %08h", data);
            api.write8(16, 50);
            #1ms;
            barrier.drop_objection();
        endtask
    endclass


endpackage
