//----------------------------------------------------------------------
// Created with uvmf_gen version 2023.4
//----------------------------------------------------------------------
// pragma uvmf custom header begin
// pragma uvmf custom header end
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//     
// DESCRIPTION: 
//    This interface performs the fwvip_wb signal driving.  It is
//     accessed by the uvm fwvip_wb driver through a virtual interface
//     handle in the fwvip_wb configuration.  It drives the singals passed
//     in through the port connection named bus of type fwvip_wb_if.
//
//     Input signals from the fwvip_wb_if are assigned to an internal input
//     signal with a _i suffix.  The _i signal should be used for sampling.
//
//     The input signal connections are as follows:
//       bus.signal -> signal_i 
//
//     This bfm drives signals with a _o suffix.  These signals
//     are driven onto signals within fwvip_wb_if based on INITIATOR/RESPONDER and/or
//     ARBITRATION/GRANT status.  
//
//     The output signal connections are as follows:
//        signal_o -> bus.signal
//
//                                                                                           
//      Interface functions and tasks used by UVM components:
//
//             configure:
//                   This function gets configuration attributes from the
//                   UVM driver to set any required BFM configuration
//                   variables such as 'initiator_responder'.                                       
//                                                                                           
//             initiate_and_get_response:
//                   This task is used to perform signaling activity for initiating
//                   a protocol transfer.  The task initiates the transfer, using
//                   input data from the initiator struct.  Then the task captures
//                   response data, placing the data into the response struct.
//                   The response struct is returned to the driver class.
//
//             respond_and_wait_for_next_transfer:
//                   This task is used to complete a current transfer as a responder
//                   and then wait for the initiator to start the next transfer.
//                   The task uses data in the responder struct to drive protocol
//                   signals to complete the transfer.  The task then waits for 
//                   the next transfer.  Once the next transfer begins, data from
//                   the initiator is placed into the initiator struct and sent
//                   to the responder sequence for processing to determine 
//                   what data to respond with.
//
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//
import uvmf_base_pkg_hdl::*;
import fwvip_wb_pkg_hdl::*;
`include "src/fwvip_wb_macros.svh"

interface fwvip_wb_driver_bfm 
  (fwvip_wb_if bus);
  // The following pragma and additional ones in-lined further below are for running this BFM on Veloce
  // pragma attribute fwvip_wb_driver_bfm partition_interface_xif

`ifndef XRTL
// This code is to aid in debugging parameter mismatches between the BFM and its corresponding agent.
// Enable this debug by setting UVM_VERBOSITY to UVM_DEBUG
// Setting UVM_VERBOSITY to UVM_DEBUG causes all BFM's and all agents to display their parameter settings.
// All of the messages from this feature have a UVM messaging id value of "CFG"
// The transcript or run.log can be parsed to ensure BFM parameter settings match its corresponding agents parameter settings.
import uvm_pkg::*;
`include "uvm_macros.svh"
initial begin : bfm_vs_agent_parameter_debug
  `uvm_info("CFG", 
      $sformatf("The BFM at '%m' has the following parameters: ", ),
      UVM_DEBUG)
end
`endif

  // Config value to determine if this is an initiator or a responder 
  uvmf_initiator_responder_t initiator_responder;
  // Custom configuration variables.  
  // These are set using the configure function which is called during the UVM connect_phase

  tri clock_i;
  tri reset_i;

  // Signal list (all signals are capable of being inputs and outputs for the sake
  // of supporting both INITIATOR and RESPONDER mode operation. Expectation is that 
  // directionality in the config file was from the point-of-view of the INITIATOR

  // INITIATOR mode input signals
  tri  ack_i;
  reg  ack_o = 'b0;
  tri  err_i;
  reg  err_o = 'b0;
  tri [31:0] dat_r_i;
  reg [31:0] dat_r_o = 'b0;

  // INITIATOR mode output signals
  tri [31:0] adr_i;
  reg [31:0] adr_o = 'b0;
  tri  cyc_i;
  reg  cyc_o = 'b0;
  tri [3:0] sel_i;
  reg [3:0] sel_o = 'b0;
  tri  stb_i;
  reg  stb_o = 'b0;
  tri  we_i;
  reg  we_o = 'b0;
  tri [31:0] dat_w_i;
  reg [31:0] dat_w_o = 'b0;

  // Bi-directional signals
  

  assign clock_i = bus.clock;
  assign reset_i = bus.reset;

  // These are signals marked as 'input' by the config file, but the signals will be
  // driven by this BFM if put into RESPONDER mode (flipping all signal directions around)
  assign ack_i = bus.ack;
  assign bus.ack = (initiator_responder == RESPONDER) ? ack_o : 'bz;
  assign err_i = bus.err;
  assign bus.err = (initiator_responder == RESPONDER) ? err_o : 'bz;
  assign dat_r_i = bus.dat_r;
  assign bus.dat_r = (initiator_responder == RESPONDER) ? dat_r_o : 'bz;


  // These are signals marked as 'output' by the config file, but the outputs will
  // not be driven by this BFM unless placed in INITIATOR mode.
  assign bus.adr = (initiator_responder == INITIATOR) ? adr_o : 'bz;
  assign adr_i = bus.adr;
  assign bus.cyc = (initiator_responder == INITIATOR) ? cyc_o : 'bz;
  assign cyc_i = bus.cyc;
  assign bus.sel = (initiator_responder == INITIATOR) ? sel_o : 'bz;
  assign sel_i = bus.sel;
  assign bus.stb = (initiator_responder == INITIATOR) ? stb_o : 'bz;
  assign stb_i = bus.stb;
  assign bus.we = (initiator_responder == INITIATOR) ? we_o : 'bz;
  assign we_i = bus.we;
  assign bus.dat_w = (initiator_responder == INITIATOR) ? dat_w_o : 'bz;
  assign dat_w_i = bus.dat_w;

  // Proxy handle to UVM driver
  fwvip_wb_pkg::fwvip_wb_driver   proxy;
  // pragma tbx oneway proxy.my_function_name_in_uvm_driver                 

  // ****************************************************************************
  // **************************************************************************** 
  // Macros that define structs located in fwvip_wb_macros.svh
  // ****************************************************************************
  // Struct for passing configuration data from fwvip_wb_driver to this BFM
  // ****************************************************************************
  `fwvip_wb_CONFIGURATION_STRUCT
  // ****************************************************************************
  // Structs for INITIATOR and RESPONDER data flow
  //*******************************************************************
  // Initiator macro used by fwvip_wb_driver and fwvip_wb_driver_bfm
  // to communicate initiator driven data to fwvip_wb_driver_bfm.           
  `fwvip_wb_INITIATOR_STRUCT
    fwvip_wb_initiator_s initiator_struct;
  // Responder macro used by fwvip_wb_driver and fwvip_wb_driver_bfm
  // to communicate Responder driven data to fwvip_wb_driver_bfm.
  `fwvip_wb_RESPONDER_STRUCT
    fwvip_wb_responder_s responder_struct;

  // ****************************************************************************
// pragma uvmf custom reset_condition_and_response begin
  // Always block used to return signals to reset value upon assertion of reset
  always @( negedge reset_i )
     begin
       // RESPONDER mode output signals
       ack_o <= 'b0;
       err_o <= 'b0;
       dat_r_o <= 'b0;
       // INITIATOR mode output signals
       adr_o <= 'b0;
       cyc_o <= 'b0;
       sel_o <= 'b0;
       stb_o <= 'b0;
       we_o <= 'b0;
       dat_w_o <= 'b0;
       // Bi-directional signals
 
     end    
// pragma uvmf custom reset_condition_and_response end

  // pragma uvmf custom interface_item_additional begin
  // pragma uvmf custom interface_item_additional end

  //******************************************************************
  // The configure() function is used to pass agent configuration
  // variables to the driver BFM.  It is called by the driver within
  // the agent at the beginning of the simulation.  It may be called 
  // during the simulation if agent configuration variables are updated
  // and the driver BFM needs to be aware of the new configuration 
  // variables.
  //

  function void configure(fwvip_wb_configuration_s fwvip_wb_configuration_arg); // pragma tbx xtf  
    initiator_responder = fwvip_wb_configuration_arg.initiator_responder;
  // pragma uvmf custom configure begin
  // pragma uvmf custom configure end
  endfunction                                                                             

// pragma uvmf custom initiate_and_get_response begin
// ****************************************************************************
// UVMF_CHANGE_ME
// This task is used by an initator.  The task first initiates a transfer then
// waits for the responder to complete the transfer.
    task initiate_and_get_response( 
       // This argument passes transaction variables used by an initiator
       // to perform the initial part of a protocol transfer.  The values
       // come from a sequence item created in a sequence.
       input fwvip_wb_initiator_s fwvip_wb_initiator_struct, 
       // This argument is used to send data received from the responder
       // back to the sequence item.  The sequence item is returned to the sequence.
       output fwvip_wb_responder_s fwvip_wb_responder_struct 
       );// pragma tbx xtf  
       // 
       // Members within the fwvip_wb_initiator_struct:
       //   bit[31:0] adr ;
       //   bit[31:0] dat ;
       //   bit[3:0] sel ;
       //   bit we ;
       // Members within the fwvip_wb_responder_struct:
       //   bit[31:0] adr ;
       //   bit[31:0] dat ;
       //   bit[3:0] sel ;
       //   bit we ;
       initiator_struct = fwvip_wb_initiator_struct;
       //
       // Reference code;
       //    How to wait for signal value
       //      while (control_signal == 1'b1) @(posedge clock_i);
       //    
       //    How to assign a responder struct member, named xyz, from a signal.   
       //    All available initiator input and inout signals listed.
       //    Initiator input signals
       //      fwvip_wb_responder_struct.xyz = ack_i;  //     
       //      fwvip_wb_responder_struct.xyz = err_i;  //     
       //      fwvip_wb_responder_struct.xyz = dat_r_i;  //    [31:0] 
       //    Initiator inout signals
       //    How to assign a signal from an initiator struct member named xyz.   
       //    All available initiator output and inout signals listed.
       //    Notice the _o.  Those are storage variables that allow for procedural assignment.
       //    Initiator output signals
       //      adr_o <= fwvip_wb_initiator_struct.xyz;  //    [31:0] 
       //      cyc_o <= fwvip_wb_initiator_struct.xyz;  //     
       //      sel_o <= fwvip_wb_initiator_struct.xyz;  //    [3:0] 
       //      stb_o <= fwvip_wb_initiator_struct.xyz;  //     
       //      we_o <= fwvip_wb_initiator_struct.xyz;  //     
       //      dat_w_o <= fwvip_wb_initiator_struct.xyz;  //    [31:0] 
       //    Initiator inout signals
    // Initiate a transfer using the data received.
    adr_o <= fwvip_wb_initiator_struct.adr;
    dat_w_o <= fwvip_wb_initiator_struct.dat;
    sel_o <= fwvip_wb_initiator_struct.sel;
    we_o <= fwvip_wb_initiator_struct.we;
    cyc_o <= 1'b1;
    stb_o <= 1'b1;
    
    do begin
        @(posedge clock_i);
    end while (ack_i != 1'b1);

    cyc_o <= 1'b0;
    stb_o <= 1'b0;
    fwvip_wb_responder_struct.dat = dat_r_i;

    responder_struct = fwvip_wb_responder_struct;
  endtask        
// pragma uvmf custom initiate_and_get_response end

// pragma uvmf custom respond_and_wait_for_next_transfer begin
// ****************************************************************************
// The first_transfer variable is used to prevent completing a transfer in the 
// first call to this task.  For the first call to this task, there is not
// current transfer to complete.
bit first_transfer=1;

// UVMF_CHANGE_ME
// This task is used by a responder.  The task first completes the current 
// transfer in progress then waits for the initiator to start the next transfer.
  task respond_and_wait_for_next_transfer( 
       // This argument is used to send data received from the initiator
       // back to the sequence item.  The sequence determines how to respond.
       output fwvip_wb_initiator_s fwvip_wb_initiator_struct, 
       // This argument passes transaction variables used by a responder
       // to complete a protocol transfer.  The values come from a sequence item.       
       input fwvip_wb_responder_s fwvip_wb_responder_struct 
       );// pragma tbx xtf   
  // Variables within the fwvip_wb_initiator_struct:
  //   bit[31:0] adr ;
  //   bit[31:0] dat ;
  //   bit[3:0] sel ;
  //   bit we ;
  // Variables within the fwvip_wb_responder_struct:
  //   bit[31:0] adr ;
  //   bit[31:0] dat ;
  //   bit[3:0] sel ;
  //   bit we ;
       // Reference code;
       //    How to wait for signal value
       //      while (control_signal == 1'b1) @(posedge clock_i);
       //    
       //    How to assign a initiator struct member, named xyz, from a signal.   
       //    All available responder input and inout signals listed.
       //    Responder input signals
       //      fwvip_wb_initiator_struct.xyz = adr_i;  //    [31:0] 
       //      fwvip_wb_initiator_struct.xyz = cyc_i;  //     
       //      fwvip_wb_initiator_struct.xyz = sel_i;  //    [3:0] 
       //      fwvip_wb_initiator_struct.xyz = stb_i;  //     
       //      fwvip_wb_initiator_struct.xyz = we_i;  //     
       //      fwvip_wb_initiator_struct.xyz = dat_w_i;  //    [31:0] 
       //    Responder inout signals
       //    How to assign a signal, named xyz, from an responder struct member.   
       //    All available responder output and inout signals listed.
       //    Notice the _o.  Those are storage variables that allow for procedural assignment.
       //    Responder output signals
       //      ack_o <= fwvip_wb_responder_struct.xyz;  //     
       //      err_o <= fwvip_wb_responder_struct.xyz;  //     
       //      dat_r_o <= fwvip_wb_responder_struct.xyz;  //    [31:0] 
       //    Responder inout signals
    
  @(posedge clock_i);
  if (!first_transfer) begin
    dat_r_o <= fwvip_wb_responder_struct.dat;
    ack_o <= 1'b1;

    // Hold for a cycle
    do begin
        @(posedge clock_i);
    end while (cyc_i != 1'b1 || stb_i != 1'b1);
    ack_o <= 1'b0;
    @(posedge clock_i);
  end

    while (cyc_i != 1'b1 || stb_i != 1'b1) begin
        @(posedge clock_i);
    end

    fwvip_wb_initiator_struct.adr = adr_i;
    fwvip_wb_initiator_struct.dat = dat_w_i;
    fwvip_wb_initiator_struct.sel = sel_i;
    fwvip_wb_initiator_struct.we = we_i;

    first_transfer = 0;
  endtask
// pragma uvmf custom respond_and_wait_for_next_transfer end

 
endinterface

// pragma uvmf custom external begin
// pragma uvmf custom external end

