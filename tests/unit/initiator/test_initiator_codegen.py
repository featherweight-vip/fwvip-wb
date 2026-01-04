import pytest
import os
import zuspec.dataclasses as zdc
from typing import Tuple
from pathlib import Path

# Import the Wishbone initiator classes
import sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../../../src/vip/org/featherweight_vip'))
from fwvip_wb.initiator import IInitiator, WishboneInitiator, InitiatorXtor


def test_initiator_xtor_codegen(tmpdir):
    """Test SystemVerilog code generation for Wishbone Initiator transactor."""
    
    # Generate Verilog
    factory = zdc.DataModelFactory()
    ctxt = factory.build([InitiatorXtor, WishboneInitiator])
    
    from zuspec.be.sv import SVGenerator
    output_dir = Path(tmpdir)
    generator = SVGenerator(output_dir)
    sv_files = generator.generate(ctxt)
    
    assert len(sv_files) > 0, "No SV files generated"
    
    # Find the InitiatorXtor SV file
    xtor_sv_file = None
    for f in sv_files:
        content = f.read_text()
        if "interface" in content and "xtor_if" in content:
            xtor_sv_file = f
            break
    
    assert xtor_sv_file is not None, "Could not find InitiatorXtor SV file"
    
    sv_content = xtor_sv_file.read_text()
    print("\n=== Generated SystemVerilog ===")
    print(sv_content)
    print("=== End Generated SystemVerilog ===\n")
    
    # Verify interface was generated
    assert "interface" in sv_content, "No interface generated"
    assert "xtor_if" in sv_content, "xtor_if not found in generated SV"
    assert "task access" in sv_content, "access task not found in generated SV"
    assert "endinterface" in sv_content, "endinterface not found"
    
    # Verify task parameters (using actual generated names)
    assert "input logic" in sv_content and "adr" in sv_content, "adr parameter not found"
    assert "input logic" in sv_content and "dat_w" in sv_content, "dat_w parameter not found"
    assert "input logic" in sv_content and "sel" in sv_content, "sel parameter not found"
    assert "input logic" in sv_content and "we" in sv_content, "we parameter not found"
    assert "output" in sv_content and "__ret" in sv_content, "return parameter not found"
    
    # Verify module structure
    assert "module" in sv_content, "Module declaration not found"
    assert "InitiatorXtor" in sv_content, "InitiatorXtor module not found"
    assert "endmodule" in sv_content, "endmodule not found"
    
    # Verify interface instantiation in module
    assert "InitiatorXtor_xtor_if xtor_if()" in sv_content, "xtor_if interface instantiation not found"
    
    # Verify FSM logic structures present
    assert "always @" in sv_content, "No always block found"
    assert "_req_state" in sv_content, "FSM state variable not found"
    
    # Verify task contains proper sequencing
    assert "@(posedge" in sv_content, "No posedge timing control found in task"
    assert "while" in sv_content, "No while loops found in task"
    assert "_req = 1" in sv_content, "Request signal assertion not found"
    assert "_req = 0" in sv_content, "Request signal deassertion not found"
    
    print("✓ All SystemVerilog structure checks passed!")
