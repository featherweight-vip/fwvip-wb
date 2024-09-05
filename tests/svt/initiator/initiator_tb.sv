
module initiator_tb;
    import svt_pkg::*;
    import initiator_test_pkg::*;
    import fwvip_wb_pkg::*;

    fwvip_wb_initiator initiator(

    );
typedef virtual fwvip_wb_initiator #(32,32) vif_t;

initial begin
    $display("Hello World");
    $display("Path: %0s", initiator.path());
//    fwvip_wb_initiator_api_p #(vif_t, 32,32)::register(null);
    svt_runtest();
    $finish;
end

initial begin
    automatic fwvip_wb_initiator_api_p #(vif_t, 32,32) api;
    api = new(initiator, initiator.path());
    fwvip_wb_pkg::register_initiator(api);
end


endmodule



