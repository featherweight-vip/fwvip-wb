# Simulation Test Issues - Summary

## Problems Discovered

When attempting to run the simulation test (`test_initiator_sim.py`), the following issues were identified:

### 1. Code Generation Issues in zuspec-be-sv

The SystemVerilog generator produces incomplete/broken code for `InitiatorXtor`:

**Problem A: "unknown expr" placeholders**
```systemverilog
/* unknown expr */__adr = adr;
/* unknown expr */__dat_w = dat_w;
@(posedge /* unknown expr */_clock);
while (/* unknown expr */_reset) begin
```

The generator cannot resolve field references like `self._adr`, `self.clock`, `self.reset` in the task body.

**Problem B: Missing module ports**
```systemverilog
module InitiatorXtor(
  // Empty - no ports!
);
```

The module has no ports for `clock`, `reset`, or the `init` bundle signals.

**Problem C: Incomplete FSM generation**
```systemverilog
always @() begin  // No sensitivity list!
  if (/* unknown expr */_reset) begin
    /* unknown expr */__req_state <= 0;
    /* unknown expr */_init_cyc <= 0;
  end
  // Missing the else block with FSM states
end
```

The `@sync` method's FSM logic is not fully generated - only the reset block appears, not the match/case state machine.

**Problem D: Incomplete Target module**
The `WishboneTarget` component generates with only reset logic, not the full FSM with state transitions.

### 2. Comparison with Working Example

The working test (`test_xtor_smoke.py` in zuspec-be-sv) generates proper code:
- Interface has local signal declarations
- Task references signals directly (no "unknown expr")
- Module has proper port list
- Signals are connected between module and interface

**Working generated code structure:**
```systemverilog
interface test_xtor_smoke____locals____Xtor_xtor_if;
  logic clock;
  logic [31:0] data_i = 0;
  logic [31:0] data_o;
  logic ready;
  logic reset;
  logic valid = 0;

  task send(output logic [31:0] __ret, input logic [31:0] data);
    @(posedge clock);  // Direct reference, no "unknown expr"
    while (reset) begin
      @(posedge clock);
    end
    data_i = data;  // Direct assignment
    valid = 1;
    // ... etc
  endtask
endinterface

module test_xtor_smoke____locals____Xtor(
  input logic clock,  // Proper ports
  input logic reset
);
  logic ready;
  logic valid;
  logic [31:0] data_i;
  logic [31:0] data_o;
  // ... proper signal declarations
  
  // Instantiate interface
  test_xtor_smoke____locals____Xtor_xtor_if xtor_if();
  
  // Connect signals
  assign xtor_if.clock = clock;
  assign data_i = xtor_if.data_i;
  // ... etc
endmodule
```

### 3. Key Differences Between Working and Broken Code

| Aspect | Working (test_xtor_smoke) | Broken (InitiatorXtor) |
|--------|--------------------------|------------------------|
| Field types | Simple `zdc.field()` | Mix of `field()`, `input()`, `bundle()` |
| Subcomponents | Has `core : XtorCore = zdc.inst()` | None (no core instance) |
| Bundle usage | None | `init : WishboneInitiator = zdc.bundle()` |
| Await calls | `await zdc.posedge()` | `await zdc.posedge()` (fixed) |
| Match/case in FSM | N/A | Uses Python 3.10+ match/case |

### 4. Possible Root Causes

1. **Bundle handling**: The `init : WishboneInitiator = zdc.bundle()` may not be properly supported by the SV generator
2. **No core component**: The working example has a separate `XtorCore` instantiated; InitiatorXtor has no subcomponent
3. **Complex FSM**: The `match/case` statement in `_req_fsm()` may not be fully supported
4. **Field reference resolution**: The generator can't map `self._adr` to the interface signal

### 5. What Works

The code generation test passes because it only validates structure (presence of keywords), not correctness. The actual issues only appear when examining the generated SV content or attempting simulation.

## Next Steps for Resolution

To fix these issues, one would need to:

1. Debug zuspec-be-sv's SV generator to understand why field references aren't resolved
2. Check if Bundle types require special handling in the generator
3. Verify that match/case statements are properly translated to SystemVerilog case statements
4. Consider restructuring InitiatorXtor to separate the protocol FSM into a Component

## Workaround Attempted

We attempted to define the WishboneTarget in a separate module file to avoid Python inspect issues, but this doesn't address the fundamental code generation problems with InitiatorXtor itself.

## Files Created

- `tests/unit/initiator/test_initiator_codegen.py` - ✅ Passes (but only validates structure)
- `tests/unit/initiator/test_initiator_sim.py` - ❌ Cannot run due to broken generated SV
- `tests/unit/initiator/wishbone_target.py` - Helper module (but doesn't solve core issues)
- `tests/unit/initiator/README.md` - Documentation

## Corrections Made to initiator.py

1. Fixed `sel` signal direction from `input()` to `output()` (line 21)
2. Fixed request deassertion from `self._req = 1` to `self._req = 0` (line 70)
3. Added missing `_req_state : zdc.u8 = zdc.field()` declaration (line 43)
4. Changed `await zdc.rtl.posedge()` to `await zdc.posedge()` to match working examples
5. Did NOT add duplicate `xtor_if` declaration (already in XtorComponent base class)
