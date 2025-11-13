
typedef class fwvip_wb_transaction;
typedef class fwvip_wb_target_config_p;

class fwvip_wb_target_driver extends uvm_driver #(fwvip_wb_transaction);
    `uvm_component_utils(fwvip_wb_target_driver)

    fwvip_wb_target_config                   m_cfg;
    bit                                      m_active = 1;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(fwvip_wb_target_config)::get(this, "", "cfg", m_cfg)) begin
            $display("Failed to get config");
            `uvm_fatal(get_name(), "Failed to get config");
        end else begin
            $display("Got config");
        end
    endfunction

    task run_phase(uvm_phase phase);
        fwvip_wb_transaction t;

        // Prime the pump by getting the first request
        $display("--> target.driver.get");
        seq_item_port.get_next_item(t);
        $display("<-- target.driver.get");
        if (!m_active) begin
            $display("end run_phase");
            return;
        end
        #10ns; // UVM really doesn't like 0-time
        m_cfg.wait_req(t);
        $display("--> target.driver.item_done");
        seq_item_port.item_done();
        $display("<-- target.driver.item_done");

        while (m_active) begin
            $display("--> target.driver.get");
            seq_item_port.get_next_item(t);
            $display("<-- target.driver.get");

            if (!m_active) begin
                $display("end run_phase");
                break;
            end

            // Send the response
            m_cfg.send_rsp(t);
            // And, get the next request
            m_cfg.wait_req(t);

            $display("--> target.driver.item_done");
            seq_item_port.item_done();
            $display("<-- target.driver.item_done");
        end
    endtask

    function void final_phase(uvm_phase phase);
        $display("-- %0t: final_phase", $time);
        m_active = 0;
    endfunction


endclass