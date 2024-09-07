
class test_basic_rw extends svt_test;
    `svt_test_decl(test_basic_rw)

    function new(string name);
        super.new(name);
    endfunction
    
    virtual task run(svt_barrier barrier);
        fwvip_wb_initiator_api api;
        bit[63:0] data;
        barrier.raise_objection();

        api = fwvip_wb_initiator_rgy.get("initiator_tb.initiator", 1);
        api.wait_reset();

        api.write32(32'h01020304, 0);
        api.read32(data, 0);
        $display("data: 32'h%08h", data);
        `svt_assert_eq(32'h01020304, data);

        api.write8(32'h01, 0);
        api.read32(data, 0);
        $display("data: 32'h%08h", data);
        `svt_assert_eq(32'h01020301, data);

        data = 0;
        api.read8(data, 1);
        $display("data: 8'h%01h", data);
        `svt_assert_eq(8'h03, data);

        barrier.drop_objection();
        $display("%0s PASSED", name);
    endtask
endclass
