//----------------------------------------------------------------------
// Created with uvmf_gen version 2023.4
//----------------------------------------------------------------------
// pragma uvmf custom header begin
// pragma uvmf custom header end
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//     
// DESCRIPTION: This file contains macros used with the fwvip_wb package.
//   These macros include packed struct definitions.  These structs are
//   used to pass data between classes, hvl, and BFM's, hdl.  Use of 
//   structs are more efficient and simpler to modify.
//
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//

// ****************************************************************************
// When changing the contents of this struct, be sure to update the to_struct
//      and from_struct methods defined in the macros below that are used in  
//      the fwvip_wb_configuration class.
//
  `define fwvip_wb_CONFIGURATION_STRUCT \
typedef struct packed  { \
     uvmf_active_passive_t active_passive; \
     uvmf_initiator_responder_t initiator_responder; \
     } fwvip_wb_configuration_s;

  `define fwvip_wb_CONFIGURATION_TO_STRUCT_FUNCTION \
  virtual function fwvip_wb_configuration_s to_struct();\
    fwvip_wb_configuration_struct = \
       {\
       this.active_passive,\
       this.initiator_responder\
       };\
    return ( fwvip_wb_configuration_struct );\
  endfunction

  `define fwvip_wb_CONFIGURATION_FROM_STRUCT_FUNCTION \
  virtual function void from_struct(fwvip_wb_configuration_s fwvip_wb_configuration_struct);\
      {\
      this.active_passive,\
      this.initiator_responder  \
      } = fwvip_wb_configuration_struct;\
  endfunction

// ****************************************************************************
// When changing the contents of this struct, be sure to update the to_monitor_struct
//      and from_monitor_struct methods of the fwvip_wb_transaction class.
//
  `define fwvip_wb_MONITOR_STRUCT typedef struct packed  { \
  bit[31:0] adr ; \
  bit[31:0] dat ; \
  bit[3:0] sel ; \
  bit we ; \
     } fwvip_wb_monitor_s;

  `define fwvip_wb_TO_MONITOR_STRUCT_FUNCTION \
  virtual function fwvip_wb_monitor_s to_monitor_struct();\
    fwvip_wb_monitor_struct = \
            { \
            this.adr , \
            this.dat , \
            this.sel , \
            this.we  \
            };\
    return ( fwvip_wb_monitor_struct);\
  endfunction\

  `define fwvip_wb_FROM_MONITOR_STRUCT_FUNCTION \
  virtual function void from_monitor_struct(fwvip_wb_monitor_s fwvip_wb_monitor_struct);\
            {\
            this.adr , \
            this.dat , \
            this.sel , \
            this.we  \
            } = fwvip_wb_monitor_struct;\
  endfunction

// ****************************************************************************
// When changing the contents of this struct, be sure to update the to_initiator_struct
//      and from_initiator_struct methods of the fwvip_wb_transaction class.
//      Also update the comments in the driver BFM.
//
  `define fwvip_wb_INITIATOR_STRUCT typedef struct packed  { \
  bit[31:0] adr ; \
  bit[31:0] dat ; \
  bit[3:0] sel ; \
  bit we ; \
     } fwvip_wb_initiator_s;

  `define fwvip_wb_TO_INITIATOR_STRUCT_FUNCTION \
  virtual function fwvip_wb_initiator_s to_initiator_struct();\
    fwvip_wb_initiator_struct = \
           {\
           this.adr , \
           this.dat , \
           this.sel , \
           this.we  \
           };\
    return ( fwvip_wb_initiator_struct);\
  endfunction

  `define fwvip_wb_FROM_INITIATOR_STRUCT_FUNCTION \
  virtual function void from_initiator_struct(fwvip_wb_initiator_s fwvip_wb_initiator_struct);\
           {\
           this.adr , \
           this.dat , \
           this.sel , \
           this.we  \
           } = fwvip_wb_initiator_struct;\
  endfunction

// ****************************************************************************
// When changing the contents of this struct, be sure to update the to_responder_struct
//      and from_responder_struct methods of the fwvip_wb_transaction class.
//      Also update the comments in the driver BFM.
//
  `define fwvip_wb_RESPONDER_STRUCT typedef struct packed  { \
  bit[31:0] adr ; \
  bit[31:0] dat ; \
  bit[3:0] sel ; \
  bit we ; \
     } fwvip_wb_responder_s;

  `define fwvip_wb_TO_RESPONDER_STRUCT_FUNCTION \
  virtual function fwvip_wb_responder_s to_responder_struct();\
    fwvip_wb_responder_struct = \
           {\
           this.adr , \
           this.dat , \
           this.sel , \
           this.we  \
           };\
    return ( fwvip_wb_responder_struct);\
  endfunction

  `define fwvip_wb_FROM_RESPONDER_STRUCT_FUNCTION \
  virtual function void from_responder_struct(fwvip_wb_responder_s fwvip_wb_responder_struct);\
           {\
           this.adr , \
           this.dat , \
           this.sel , \
           this.we  \
           } = fwvip_wb_responder_struct;\
  endfunction
// pragma uvmf custom additional begin
// pragma uvmf custom additional end
