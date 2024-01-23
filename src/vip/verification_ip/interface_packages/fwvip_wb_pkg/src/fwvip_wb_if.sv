//----------------------------------------------------------------------
// Created with uvmf_gen version 2023.4
//----------------------------------------------------------------------
// pragma uvmf custom header begin
// pragma uvmf custom header end
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//     
// DESCRIPTION: This interface contains the fwvip_wb interface signals.
//      It is instantiated once per fwvip_wb bus.  Bus Functional Models, 
//      BFM's named fwvip_wb_driver_bfm, are used to drive signals on the bus.
//      BFM's named fwvip_wb_monitor_bfm are used to monitor signals on the 
//      bus. This interface signal bundle is passed in the port list of
//      the BFM in order to give the BFM access to the signals in this
//      interface.
//
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//
// This template can be used to connect a DUT to these signals
//
// .dut_signal_port(fwvip_wb_bus.adr), // Agent output 
// .dut_signal_port(fwvip_wb_bus.cyc), // Agent output 
// .dut_signal_port(fwvip_wb_bus.ack), // Agent input 
// .dut_signal_port(fwvip_wb_bus.err), // Agent input 
// .dut_signal_port(fwvip_wb_bus.sel), // Agent output 
// .dut_signal_port(fwvip_wb_bus.stb), // Agent output 
// .dut_signal_port(fwvip_wb_bus.we), // Agent output 
// .dut_signal_port(fwvip_wb_bus.dat_w), // Agent output 
// .dut_signal_port(fwvip_wb_bus.dat_r), // Agent input 

import uvmf_base_pkg_hdl::*;
import fwvip_wb_pkg_hdl::*;

interface  fwvip_wb_if 

  (
  input tri clock, 
  input tri reset,
  inout tri [31:0] adr,
  inout tri  cyc,
  inout tri  ack,
  inout tri  err,
  inout tri [3:0] sel,
  inout tri  stb,
  inout tri  we,
  inout tri [31:0] dat_w,
  inout tri [31:0] dat_r
  );

modport monitor_port 
  (
  input clock,
  input reset,
  input adr,
  input cyc,
  input ack,
  input err,
  input sel,
  input stb,
  input we,
  input dat_w,
  input dat_r
  );

modport initiator_port 
  (
  input clock,
  input reset,
  output adr,
  output cyc,
  input ack,
  input err,
  output sel,
  output stb,
  output we,
  output dat_w,
  input dat_r
  );

modport responder_port 
  (
  input clock,
  input reset,  
  input adr,
  input cyc,
  output ack,
  output err,
  input sel,
  input stb,
  input we,
  input dat_w,
  output dat_r
  );
  

// pragma uvmf custom interface_item_additional begin
// pragma uvmf custom interface_item_additional end

endinterface

// pragma uvmf custom external begin
// pragma uvmf custom external end

