# Code Generation Issues After Adding @zdc.dataclass

## Status: Significant Improvement! ✅

Adding the `@zdc.dataclass` decorator to `InitiatorXtor` fixed the major "unknown expr" issues!

## What Now Works ✅

1. **Field references resolved** - `self._adr`, `self.clock`, `self.reset` now generate correctly
2. **Module ports generated** - `clock` and `reset` ports present
3. **Parameters generated** - `DATA_WIDTH` and `ADDR_WIDTH` parameters work
4. **Sensitivity list** - `always @(posedge clock or posedge reset)` is correct
5. **Signal assignments** - Connections between module and interface attempted

## Remaining Code Generation Issues ❌

### Issue 1: Missing Interface Signal Declarations

**Current:**
```systemverilog
interface InitiatorXtor_xtor_if;
  // Local signals
  task access(...);
    _adr = adr;  // _adr not declared!
    _dat_w = dat_w;  // _dat_w not declared!
    // ...
```

**Expected:**
```systemverilog
interface InitiatorXtor_xtor_if;
  // Local signals
  logic clock;
  logic reset;
  logic [31:0] _adr;
  logic [31:0] _dat_w;
  logic [31:0] _dat_r;
  logic [3:0] _sel;
  logic _we;
  logic _err;
  logic _req;
  logic _ack;
  
  task access(...);
    _adr = adr;
    // ...
```

### Issue 2: Missing Module Internal Signal Declarations

**Current:**
```systemverilog
module InitiatorXtor(...);
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      _req_state <= 0;  // _req_state not declared!
      init_cyc <= 0;  // init_cyc not declared!
```

**Expected:**
```systemverilog
module InitiatorXtor(...);
  logic [7:0] _req_state;
  logic _req;
  logic _ack;
  logic [31:0] _adr;
  logic [31:0] _dat_w;
  logic [31:0] _dat_r;
  logic [3:0] _sel;
  logic _we;
  logic _err;
  
  // Bundle signals
  logic [31:0] init_adr;
  logic [31:0] init_dat_w;
  logic [31:0] init_dat_r;
  logic init_cyc;
  logic init_ack;
  logic init_err;
  logic [3:0] init_sel;
  logic init_we;
  
  always @(posedge clock or posedge reset) begin
    // ...
```

### Issue 3: Incomplete FSM Generation (Both Modules)

**InitiatorXtor - only reset block generated:**
```systemverilog
always @(posedge clock or posedge reset) begin
  if (reset) begin
    _req_state <= 0;
    init_cyc <= 0;
  end
  // Missing else block with match/case FSM!
end
```

**Expected:**
```systemverilog
always @(posedge clock or posedge reset) begin
  if (reset) begin
    _req_state <= 0;
    init_cyc <= 0;
  end else begin
    case (_req_state)
      0: begin
        _ack <= 0;
        if (_req) begin
          init_cyc <= 1;
          init_adr <= _adr;
          init_dat_w <= _dat_w;
          init_we <= _we;
          init_sel <= _sel;
          _req_state <= 1;
        end
      end
      1: begin
        if (init_ack) begin
          _ack <= 1;
          _req_state <= 0;
          _dat_r <= init_dat_r;
          _err <= init_err;
          init_cyc <= 0;
        end
      end
    endcase
  end
end
```

**WishboneTarget - same issue, only reset block:**
```systemverilog
always @(posedge clock or posedge reset) begin
  if (reset) begin
    _state <= 0;
    ack <= 0;
    err <= 0;
    dat_r <= 0;
  end
  // Missing else block with FSM!
end
```

### Issue 4: Tuple Return Type Not Handled

**Current:**
```systemverilog
task access(
  output  __ret,
  input logic [31:0] adr, ...);
  // ...
  __ret = <Tuple>;  // SYNTAX ERROR!
endtask
```

**Expected:**
```systemverilog
task access(
  output logic __ret_0,  // err
  output logic [63:0] __ret_1,  // dat_r
  input logic [63:0] adr, ...);
  // ...
  __ret_0 = _err;
  __ret_1 = _dat_r;
endtask
```

### Issue 5: Bundle Signals Not Expanded as Ports

The `init` bundle should create individual port signals but they're only referenced internally.

### Issue 6: Width Calculation Bug in WishboneTarget

```systemverilog
input logic [(WIDTH-1):0] sel,  // WIDTH undefined! Should be (DATA_WIDTH/8-1)
```

## Summary

The `@zdc.dataclass` decorator was CRITICAL and fixed most issues. The remaining problems are:

1. **Signal declarations missing** in both interface and module
2. **FSM code generation incomplete** - Python `match/case` not translating to SystemVerilog `case`
3. **Tuple returns not unpacked** properly
4. **Bundle expansion incomplete** - needs to generate individual signals

These appear to be bugs/limitations in the zuspec-be-sv SystemVerilog generator that need fixes upstream.

## Test Status

- `test_initiator_codegen.py` - ✅ **PASSES** (structure validation only)
- `test_initiator_sim.py` - ❌ **Verilator syntax error on `__ret = <Tuple>`**
