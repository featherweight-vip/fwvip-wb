//----------------------------------------------------------------------
// Created with uvmf_gen version 2023.4
//----------------------------------------------------------------------
// pragma uvmf custom header begin
// pragma uvmf custom header end
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//     
// PACKAGE: This file defines all of the files contained in the
//    interface package that will run on the host simulator.
//
// CONTAINS:
//    - <fwvip_wb_typedefs_hdl>
//    - <fwvip_wb_typedefs.svh>
//    - <fwvip_wb_transaction.svh>

//    - <fwvip_wb_configuration.svh>
//    - <fwvip_wb_driver.svh>
//    - <fwvip_wb_monitor.svh>

//    - <fwvip_wb_transaction_coverage.svh>
//    - <fwvip_wb_sequence_base.svh>
//    - <fwvip_wb_random_sequence.svh>

//    - <fwvip_wb_responder_sequence.svh>
//    - <fwvip_wb2reg_adapter.svh>
//
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//
package fwvip_wb_pkg;
  
   import uvm_pkg::*;
   import uvmf_base_pkg_hdl::*;
   import uvmf_base_pkg::*;
   import fwvip_wb_pkg_hdl::*;

   `include "uvm_macros.svh"

   // pragma uvmf custom package_imports_additional begin 
   // pragma uvmf custom package_imports_additional end
   `include "src/fwvip_wb_macros.svh"

   export fwvip_wb_pkg_hdl::*;
   
 

   // Parameters defined as HVL parameters

   `include "src/fwvip_wb_typedefs.svh"
   `include "src/fwvip_wb_transaction.svh"

   `include "src/fwvip_wb_configuration.svh"
   `include "src/fwvip_wb_driver.svh"
   `include "src/fwvip_wb_monitor.svh"

   `include "src/fwvip_wb_transaction_coverage.svh"
   `include "src/fwvip_wb_sequence_base.svh"
   `include "src/fwvip_wb_random_sequence.svh"

   `include "src/fwvip_wb_responder_sequence.svh"
   `include "src/fwvip_wb2reg_adapter.svh"

   `include "src/fwvip_wb_agent.svh"

   // pragma uvmf custom package_item_additional begin
   // UVMF_CHANGE_ME : When adding new interface sequences to the src directory
   //    be sure to add the sequence file here so that it will be
   //    compiled as part of the interface package.  Be sure to place
   //    the new sequence after any base sequences of the new sequence.
   // pragma uvmf custom package_item_additional end

endpackage

// pragma uvmf custom external begin
// pragma uvmf custom external end

