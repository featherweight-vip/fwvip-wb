# Wishbone Initiator Unit Tests

## Overview
This directory contains unit tests for the Wishbone Initiator Zuspec transactor component.

## Test Files

### test_initiator_codegen.py
Basic code generation test that validates SystemVerilog code is properly generated from the Zuspec `InitiatorXtor` class.

**What it tests:**
- Interface generation with `xtor_if` 
- Task `access` with proper parameters
- Module structure with proper always blocks
- FSM state variable declarations
- Task sequencing (posedge, while loops, request/ack handshaking)

**Run with:**
```bash
pytest tests/unit/initiator/test_initiator_codegen.py -v
```

### test_initiator_sim.py
Full simulation test that generates a transactor from the Zuspec class, instantiates it alongside a simple Wishbone target module, and runs a simulation with read/write transactions.

**What it tests:**
- Full end-to-end code generation
- Transactor instantiation with clock and reset
- Calling the `access()` method on the `xtor_if` interface
- Write transaction to target
- Read transaction from target  
- Data integrity (read-back verification)

**Requires:**
- Available simulator (verilator, vsim, or xsim)
- DV flow infrastructure

**Run with:**
```bash
pytest tests/unit/initiator/test_initiator_sim.py -v -s
```

## Issues Fixed in initiator.py

The following issues were identified and corrected:

1. **Line 21**: `sel` signal was incorrectly defined as `input()` instead of `output()` 
   - Fixed: Initiator drives the byte-select signals, so they must be outputs

2. **Line 69**: Redundant assignment of `_req = 1` after waiting for `_ack`
   - Fixed: Changed to `_req = 0` to properly deassert the request after transaction completes

3. **Missing field**: `_req_state` was used by the FSM but not declared
   - Fixed: Added `_req_state : zdc.u8 = zdc.field()` declaration

## Test Architecture

The tests follow the Zuspec XtorComponent pattern:
- `IInitiator` Protocol defines the transaction-level interface
- `WishboneInitiator` Bundle defines the signal-level Wishbone interface
- `InitiatorXtor` XtorComponent implements the transactor that bridges them
- The transactor exports `xtor_if` with the `access()` task
- The FSM `_req_fsm()` handles the Wishbone protocol timing

## Next Steps

To run a simulation test with an actual Verilog DUT:
1. Ensure a simulator is in PATH
2. Run the simulation test with debug output: `pytest tests/unit/initiator/test_initiator_sim.py -v -s --tb=short`
3. Check generated files in `/tmp/pytest-*/test_initiator_xtor_sim*/sv/`
