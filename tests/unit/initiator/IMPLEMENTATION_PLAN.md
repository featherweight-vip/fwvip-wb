# Implementation Plan for zuspec-be-sv Code Generation Fixes

## Overview
Fix SystemVerilog code generation issues in zuspec-be-sv/src/zuspec/be/sv/generator.py to enable simulation of InitiatorXtor.

## Issue 1: Tuple Return Type Handling ⭐ PRIORITY

**Location:** `_generate_interface_task()` around line 1148-1195

**Current Problem:**
```systemverilog
task access(
  output  __ret,
  input logic [31:0] adr, ...);
  ...
  __ret = <Tuple>;  // SYNTAX ERROR!
endtask
```

**Implementation Plan:**

### Step 1.1: Detect Tuple Returns
In `_generate_interface_task()` line ~1156:
```python
if func.returns and func.returns is not None:
    # NEW: Check if return is a Tuple
    if isinstance(func.returns, ir.DataTypeTuple):
        # Handle tuple - create output param for each element
        for i, elem_type in enumerate(func.returns.elements):
            elem_sv_type = self._get_sv_type(elem_type)
            params.append(f"output {elem_sv_type} __ret_{i}")
    else:
        # Existing single return handling
        return_type = self._get_sv_type(func.returns)
        params.append(f"output {return_type} __ret")
```

### Step 1.2: Update Return Statement Generation
In `_generate_task_stmt()` line ~1272:
```python
elif isinstance(stmt, ir.StmtReturn):
    if stmt.value:
        # NEW: Check if value is a tuple
        if isinstance(stmt.value, ir.ExprTuple):
            # Unpack tuple elements to individual output params
            for i, elem in enumerate(stmt.value.values):
                value_expr = self._generate_expr(elem, comp)
                lines.append(f"{ind}__ret_{i} = {value_expr};")
        else:
            # Existing single return
            value_expr = self._generate_expr(stmt.value, comp)
            lines.append(f"{ind}__ret = {value_expr};")
```

### Step 1.3: Add Explicit Input Directives
After adding output params, remaining params need explicit `input`:
```python
# Input parameters
for arg in func.args.args:
    arg_type = self._get_arg_type(arg)  # Helper to determine type
    params.append(f"input {arg_type} {arg.arg}")  # Already has 'input'
```
**Note:** Current code already adds `input` directive (line 1175), so this is OK.

**Testing:** After this fix, `__ret = <Tuple>` should become:
```systemverilog
task access(
  output logic __ret_0,        // err
  output logic [63:0] __ret_1, // dat_r
  input logic [63:0] adr, ...);
  ...
  __ret_0 = _err;
  __ret_1 = _dat_r;
endtask
```

---

## Issue 2: Missing Interface Signal Declarations ⭐ PRIORITY

**Location:** `_generate_export_interfaces()` around line 910-940

**Current Problem:**
```systemverilog
interface InitiatorXtor_xtor_if;
  // Local signals
  task access(...);
    _adr = adr;  // _adr not declared!
```

**Root Cause:** Signal declarations are skipped when signal type is not found (line 919).

**Implementation Plan:**

### Step 2.1: Improve Signal Type Lookup
Around line 912-920, enhance the lookup:
```python
for signal_name in sorted(needed_signals):
    signal_type = None
    
    # Try to find in regular fields
    for fld in comp.fields:
        if fld.name == signal_name:
            if isinstance(fld.datatype, ir.DataTypeInt):
                signal_type = self._get_sv_type(fld.datatype)
            break
    
    # NEW: If not found, check flattened bundle signals
    if signal_type is None and '_' in signal_name:
        signal_type = self._infer_bundle_signal_type(signal_name, comp)
    
    # NEW: If still not found, default to logic
    if signal_type is None:
        signal_type = "logic"
        print(f"WARNING: Could not determine type for signal '{signal_name}', defaulting to logic")
    
    # Determine initial value for writable signals
    if signal_name in signals_written_by_interface:
        interface_lines.append(f"  {signal_type} {signal_name} = 0;")
    else:
        interface_lines.append(f"  {signal_type} {signal_name};")
```

### Step 2.2: Add Helper Method
Add new method around line 1020:
```python
def _infer_bundle_signal_type(self, signal_name: str, comp: ir.DataTypeComponent) -> str:
    """Infer type for bundle flattened signal like init_cyc, init_adr."""
    if '_' not in signal_name:
        return None
    
    parts = signal_name.split('_', 1)
    bundle_name = parts[0]
    field_name = parts[1]
    
    # Find bundle field
    for fld in comp.fields:
        if fld.name == bundle_name and isinstance(fld.datatype, ir.DataTypeRef):
            # Get bundle struct type
            ref_type = self._ctxt.type_m.get(fld.datatype.ref_name)
            if isinstance(ref_type, ir.DataTypeStruct):
                # Find the field in the bundle
                for bundle_fld in ref_type.fields:
                    if bundle_fld.name == field_name:
                        return self._get_sv_type(bundle_fld.datatype)
    
    return None
```

**Testing:** Interface should now have:
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
  logic _req = 0;
  logic _ack;
```

---

## Issue 3: Missing Module Signal Declarations

**Location:** `_generate_component()` and signal declaration generation

**Current Problem:**
```systemverilog
module InitiatorXtor(...);
  always @(...) begin
    _req_state <= 0;  // _req_state not declared!
    init_cyc <= 0;    // init_cyc not declared!
```

**Implementation Plan:**

### Step 3.1: Collect All Signals Used in Module
In `_generate_component()` after parameters, add:
```python
# Collect all signals used in sync blocks and needed for interface connections
module_signals = set()

# From @sync methods
for func in comp.functions:
    if func.is_sync:
        for stmt in func.body:
            self._collect_signal_refs(stmt, module_signals, comp)

# From bind_map connections to interface
for bind in comp.bind_map:
    self._collect_signal_refs_from_expr(bind.lhs, module_signals, comp)
    self._collect_signal_refs_from_expr(bind.rhs, module_signals, comp)
```

### Step 3.2: Declare Module Internal Signals
After port list, before logic blocks:
```python
# Declare internal signals
lines.append("")
for signal_name in sorted(module_signals):
    # Skip if it's a port (input/output)
    if self._is_port(signal_name, comp):
        continue
    
    signal_type = self._get_signal_type(signal_name, comp)
    lines.append(f"  {signal_type} {signal_name};")
```

### Step 3.3: Expand Bundle Signals
For bundle fields like `init : WishboneInitiator`, generate individual signals:
```python
# Expand bundle fields to individual signals
for field in comp.fields:
    if isinstance(field.datatype, ir.DataTypeRef):
        ref_type = self._ctxt.type_m.get(field.datatype.ref_name)
        if isinstance(ref_type, ir.DataTypeStruct):
            # This is a bundle - expand to individual signals
            for bundle_fld in ref_type.fields:
                flat_name = f"{field.name}_{bundle_fld.name}"
                signal_type = self._get_sv_type(bundle_fld.datatype)
                lines.append(f"  {signal_type} {flat_name};")
```

**Testing:** Module should have:
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
  
  logic [31:0] init_adr;
  logic [31:0] init_dat_w;
  logic [31:0] init_dat_r;
  logic init_cyc;
  logic init_ack;
  logic init_err;
  logic [3:0] init_sel;
  logic init_we;
```

---

## Issue 4: Incomplete FSM Generation (match/case) ⭐ CRITICAL

**Location:** `_generate_stmt()` - needs to handle `ir.StmtMatch`

**Current Problem:**
Only reset block generated, missing:
```python
match self._req_state:
    case 0:
        ...
    case 1:
        ...
```

**Implementation Plan:**

### Step 4.1: Add StmtMatch Handler
In `_generate_stmt()` (around line 600-700), add:
```python
elif isinstance(stmt, ir.StmtMatch):
    # Python match/case → SystemVerilog case
    subject_expr = self._generate_expr(stmt.subject, comp)
    lines.append(f"{ind}case ({subject_expr})")
    
    for case in stmt.cases:
        # case.pattern is the match pattern (could be literal, wildcard, etc.)
        if isinstance(case.pattern, ir.PatternLiteral):
            case_value = self._generate_expr(case.pattern.value, comp)
            lines.append(f"{ind}  {case_value}: begin")
        elif isinstance(case.pattern, ir.PatternWildcard):
            lines.append(f"{ind}  default: begin")
        else:
            # Handle other pattern types
            lines.append(f"{ind}  /* TODO: pattern {type(case.pattern).__name__} */: begin")
        
        # Generate case body
        for s in case.body:
            lines.extend(self._generate_stmt(s, comp, indent + 2))
        
        lines.append(f"{ind}  end")
    
    lines.append(f"{ind}endcase")
```

### Step 4.2: Check IR for Match Statement Type
First, verify `ir.StmtMatch` exists:
```python
from zuspec.dataclasses import ir
print(dir(ir))  # Check for StmtMatch
```

If it doesn't exist, it might be named differently or need to be added to the IR.

**Testing:** Should generate:
```systemverilog
else begin
  case (_req_state)
    0: begin
      _ack <= 0;
      if (_req) begin
        init_cyc <= 1;
        init_adr <= _adr;
        ...
        _req_state <= 1;
      end
    end
    1: begin
      if (init_ack) begin
        _ack <= 1;
        _req_state <= 0;
        ...
      end
    end
  endcase
end
```

---

## Issue 5: Bundle Signal Width Bug

**Location:** Width calculation for bundle fields

**Current Problem:**
```systemverilog
input logic [(WIDTH-1):0] sel,  // WIDTH undefined!
```

**Implementation Plan:**

### Step 5.1: Fix Width Expression Evaluation
In `_get_sv_type()` or width expression handling:
- Ensure lambda expressions like `width=lambda s:int(s.DATA_WIDTH/8)` are evaluated
- Fall back to evaluating with actual parameter values if available

This might require context from the component's const fields.

---

## Implementation Order

1. **Issue 1 (Tuple returns)** - Fixes syntax error, allows compilation
2. **Issue 2 (Interface signals)** - Fixes undeclared signal errors in interface
3. **Issue 3 (Module signals)** - Fixes undeclared signal errors in module
4. **Issue 4 (Match/case)** - Enables FSM logic generation
5. **Issue 5 (Width bug)** - Polish, fix remaining width issues

## Testing Strategy

After each issue is fixed:
1. Run `test_initiator_codegen.py` - should continue passing
2. Run `test_initiator_sim.py` - check compilation errors
3. Examine generated SV files manually
4. Iterate until simulation compiles and runs

## Estimated Effort

- Issue 1: ~30 minutes (detect tuple, unpack on return)
- Issue 2: ~45 minutes (signal type lookup improvement)
- Issue 3: ~60 minutes (collect and declare module signals)
- Issue 4: ~90 minutes (match/case translation, need to check IR)
- Issue 5: ~30 minutes (width expression evaluation)

**Total: ~4 hours of focused development**

## Success Criteria

✅ `test_initiator_sim.py` compiles without errors
✅ Simulation runs and accesses wishbone target
✅ Test reports "TEST PASSED"
