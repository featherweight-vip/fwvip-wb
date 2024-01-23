//----------------------------------------------------------------------
// Created with uvmf_gen version 2023.4
//----------------------------------------------------------------------
// pragma uvmf custom header begin
// pragma uvmf custom header end
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//
// Description: This file contains the top level and utility sequences
//     used by test_top. It can be extended to create derivative top
//     level sequences.
//
//----------------------------------------------------------------------
//
//----------------------------------------------------------------------
//


typedef fwvip_wb_b2b_env_configuration  fwvip_wb_b2b_env_configuration_t;

class fwvip_wb_b2b_tb_bench_sequence_base extends uvmf_sequence_base #(uvm_sequence_item);

  `uvm_object_utils( fwvip_wb_b2b_tb_bench_sequence_base );

  // pragma uvmf custom sequences begin

// This example shows how to use the environment sequence base
// It can only be used on environments generated with UVMF_2022.3 and later.
// Environment sequences generated with UVMF_2022.1 and earlier do not have the required 
//    environment level virtual sequencer
// typedef fwvip_wb_b2b_env_sequence_base #(
//         .CONFIG_T(fwvip_wb_b2b_env_configuration_t)// 
//         )
//         fwvip_wb_b2b_env_sequence_base_t;
// rand fwvip_wb_b2b_env_sequence_base_t fwvip_wb_b2b_env_seq;



  // UVMF_CHANGE_ME : Instantiate, construct, and start sequences as needed to create stimulus scenarios.
  // Instantiate sequences here
  typedef fwvip_wb_random_sequence  wb_init_random_seq_t;
  wb_init_random_seq_t wb_init_random_seq;
  typedef fwvip_wb_responder_sequence  wb_targ_responder_seq_t;
  wb_targ_responder_seq_t wb_targ_responder_seq;
  // pragma uvmf custom sequences end

  // Sequencer handles for each active interface in the environment
  typedef fwvip_wb_transaction  wb_init_transaction_t;
  uvm_sequencer #(wb_init_transaction_t)  wb_init_sequencer; 
  typedef fwvip_wb_transaction  wb_targ_transaction_t;
  uvm_sequencer #(wb_targ_transaction_t)  wb_targ_sequencer; 


  // Top level environment configuration handle
  fwvip_wb_b2b_env_configuration_t top_configuration;

  // Configuration handles to access interface BFM's
  fwvip_wb_configuration  wb_init_config;
  fwvip_wb_configuration  wb_targ_config;

  // pragma uvmf custom class_item_additional begin
  // pragma uvmf custom class_item_additional end

  // ****************************************************************************
  function new( string name = "" );
    super.new( name );
    // Retrieve the configuration handles from the uvm_config_db

    // Retrieve top level configuration handle
    if ( !uvm_config_db#(fwvip_wb_b2b_env_configuration_t)::get(null,UVMF_CONFIGURATIONS, "TOP_ENV_CONFIG",top_configuration) ) begin
      `uvm_info("CFG", "*** FATAL *** uvm_config_db::get can not find TOP_ENV_CONFIG.  Are you using an older UVMF release than what was used to generate this bench?",UVM_NONE);
      `uvm_fatal("CFG", "uvm_config_db#(fwvip_wb_b2b_env_configuration_t)::get cannot find resource TOP_ENV_CONFIG");
    end

    // Retrieve config handles for all agents
    if( !uvm_config_db #( fwvip_wb_configuration )::get( null , UVMF_CONFIGURATIONS , wb_init_BFM , wb_init_config ) ) 
      `uvm_fatal("CFG" , "uvm_config_db #( fwvip_wb_configuration )::get cannot find resource wb_init_BFM" )
    if( !uvm_config_db #( fwvip_wb_configuration )::get( null , UVMF_CONFIGURATIONS , wb_targ_BFM , wb_targ_config ) ) 
      `uvm_fatal("CFG" , "uvm_config_db #( fwvip_wb_configuration )::get cannot find resource wb_targ_BFM" )

    // Assign the sequencer handles from the handles within agent configurations
    wb_init_sequencer = wb_init_config.get_sequencer();
    wb_targ_sequencer = wb_targ_config.get_sequencer();



    // pragma uvmf custom new begin
    // pragma uvmf custom new end

  endfunction

  // ****************************************************************************
  virtual task body();
    // pragma uvmf custom body begin

    // Construct sequences here

    // fwvip_wb_b2b_env_seq = fwvip_wb_b2b_env_sequence_base_t::type_id::create("fwvip_wb_b2b_env_seq");

    wb_init_random_seq     = wb_init_random_seq_t::type_id::create("wb_init_random_seq");
    wb_targ_responder_seq  = wb_targ_responder_seq_t::type_id::create("wb_targ_responder_seq");
    fork
      wb_init_config.wait_for_reset();
      wb_targ_config.wait_for_reset();
    join
    // Start RESPONDER sequences here
    fork
      wb_targ_responder_seq.start(wb_targ_sequencer);
    join_none
    // Start INITIATOR sequences here
    fork
      repeat (25) wb_init_random_seq.start(wb_init_sequencer);
    join

// fwvip_wb_b2b_env_seq.start(top_configuration.vsqr);

    // UVMF_CHANGE_ME : Extend the simulation XXX number of clocks after 
    // the last sequence to allow for the last sequence item to flow 
    // through the design.
    fork
      wb_init_config.wait_for_num_clocks(400);
      wb_targ_config.wait_for_num_clocks(400);
    join

    // pragma uvmf custom body end
  endtask

endclass

// pragma uvmf custom external begin
// pragma uvmf custom external end

