//----------------------------------------------------------------------
// Created with uvmf_gen version 2023.4
//----------------------------------------------------------------------
// pragma uvmf custom header begin
// pragma uvmf custom header end
//----------------------------------------------------------------------
//----------------------------------------------------------------------                     
//               
// Description: This top level module instantiates all synthesizable
//    static content.  This and tb_top.sv are the two top level modules
//    of the simulation.  
//
//    This module instantiates the following:
//        DUT: The Design Under Test
//        Interfaces:  Signal bundles that contain signals connected to DUT
//        Driver BFM's: BFM's that actively drive interface signals
//        Monitor BFM's: BFM's that passively monitor interface signals
//
//----------------------------------------------------------------------

//----------------------------------------------------------------------
//

module hdl_top;

import fwvip_wb_b2b_tb_parameters_pkg::*;
import uvmf_base_pkg_hdl::*;

  // pragma attribute hdl_top partition_module_xrtl                                            
// pragma uvmf custom clock_generator begin
  bit clk;
  // Instantiate a clk driver 
  // tbx clkgen
  initial begin
    clk = 0;
    #9ns;
    forever begin
      clk = ~clk;
      #5ns;
    end
  end
// pragma uvmf custom clock_generator end

// pragma uvmf custom reset_generator begin
  bit rst;
  // Instantiate a rst driver
  // tbx clkgen
  initial begin
    rst = 0; 
    #200ns;
    rst =  1; 
  end
// pragma uvmf custom reset_generator end

  // pragma uvmf custom module_item_additional begin
  // pragma uvmf custom module_item_additional end

  // Instantiate the signal bundle, monitor bfm and driver bfm for each interface.
  // The signal bundle, _if, contains signals to be connected to the DUT.
  // The monitor, monitor_bfm, observes the bus, _if, and captures transactions.
  // The driver, driver_bfm, drives transactions onto the bus, _if.
  fwvip_wb_if  wb_init_bus(
     // pragma uvmf custom wb_init_bus_connections begin
     .clock(clk), .reset(rst)
     // pragma uvmf custom wb_init_bus_connections end
     );
  fwvip_wb_if  wb_targ_bus(
     // pragma uvmf custom wb_targ_bus_connections begin
     .clock(clk), .reset(rst)
     // pragma uvmf custom wb_targ_bus_connections end
     );
  fwvip_wb_monitor_bfm  wb_init_mon_bfm(wb_init_bus);
  fwvip_wb_monitor_bfm  wb_targ_mon_bfm(wb_targ_bus);
  fwvip_wb_driver_bfm  wb_init_drv_bfm(wb_init_bus);
  fwvip_wb_driver_bfm  wb_targ_drv_bfm(wb_targ_bus);

  // pragma uvmf custom dut_instantiation begin
  // UVMF_CHANGE_ME : Add DUT and connect to signals in _bus interfaces listed above
  // Instantiate your DUT here
  assign wb_targ_bus.adr = wb_init_bus.adr;
  assign wb_targ_bus.cyc = wb_init_bus.cyc;
  assign wb_targ_bus.stb = wb_init_bus.stb;
  assign wb_targ_bus.sel = wb_init_bus.sel;
  assign wb_targ_bus.dat_w = wb_init_bus.dat_w;
  assign wb_init_bus.dat_r = wb_targ_bus.dat_r;
  assign wb_init_bus.ack = wb_targ_bus.ack;
  assign wb_init_bus.err = wb_targ_bus.err;
  // ...
  // pragma uvmf custom dut_instantiation end

  initial begin      // tbx vif_binding_block 
    import uvm_pkg::uvm_config_db;
    // The monitor_bfm and driver_bfm for each interface is placed into the uvm_config_db.
    // They are placed into the uvm_config_db using the string names defined in the parameters package.
    // The string names are passed to the agent configurations by test_top through the top level configuration.
    // They are retrieved by the agents configuration class for use by the agent.
    uvm_config_db #( virtual fwvip_wb_monitor_bfm  )::set( null , UVMF_VIRTUAL_INTERFACES , wb_init_BFM , wb_init_mon_bfm ); 
    uvm_config_db #( virtual fwvip_wb_monitor_bfm  )::set( null , UVMF_VIRTUAL_INTERFACES , wb_targ_BFM , wb_targ_mon_bfm ); 
    uvm_config_db #( virtual fwvip_wb_driver_bfm  )::set( null , UVMF_VIRTUAL_INTERFACES , wb_init_BFM , wb_init_drv_bfm  );
    uvm_config_db #( virtual fwvip_wb_driver_bfm  )::set( null , UVMF_VIRTUAL_INTERFACES , wb_targ_BFM , wb_targ_drv_bfm  );
  end

endmodule

// pragma uvmf custom external begin
// pragma uvmf custom external end

