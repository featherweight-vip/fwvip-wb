
interface fwvip_wb_initiator #(
        parameter ADDR_WIDTH = 32,
        parameter DATA_WIDTH = 32
    ) (
        input                       clock,
        input                       reset,
        output [ADDR_WIDTH-1:0]     adr,
        output                      w,
        output [DATA_WIDTH-1:0]     dat_w,
        input [DATA_WIDTH-1:0]      dat_r
    );

    always @(posedge clock or posedge reset) begin
        if (reset) begin
        end else begin
        end
    end

    task queue_req(
        input [ADDR_WIDTH-1:0]      adr,
        input [DATA_WIDTH-1:0]      dat
    );
        $display("queue_req");
    endtask

    task wait_ack(
        output [DATA_WIDTH-1:0]     dat_r,
        output                      err
    );
    endtask

    function automatic string path();
        string ret = $sformatf("%m");
        for (int i=ret.len()-1; i>=0; i--) begin
            if (ret[i] == ".") begin
                ret = ret.substr(0, i-1);
                break;
            end
        end
        return ret;
    endfunction

endinterface
