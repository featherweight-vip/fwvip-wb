import pytest
import os
import shutil
import asyncio
import zuspec.dataclasses as zdc
from typing import Tuple
from pathlib import Path
from dv_flow.mgr import TaskListenerLog, TaskSetRunner, PackageLoader
from dv_flow.mgr.task_graph_builder import TaskGraphBuilder

# Import the Wishbone initiator classes
import sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../../../src/vip/org/featherweight_vip'))
from fwvip_wb.initiator import IInitiator, WishboneInitiator, InitiatorXtor

# Import the simple target for testing
from wishbone_target import WishboneTarget


def get_available_sims():
    """Get list of available simulators."""
    sims = []
    for sim_exe, sim in {
        "verilator": "vlt",
        "vsim": "mti",
        "xsim": "xsm",
    }.items():
        if shutil.which(sim_exe) is not None:
            sims.append(sim)
    return sims


@pytest.mark.parametrize("sim", get_available_sims())
def test_initiator_xtor_sim(tmpdir, sim):
    """Test Wishbone Initiator transactor with simulation - calls xtor_if.access() task."""
    
    # Simple Wishbone target for testing
    @zdc.dataclass
    class WishboneTarget(zdc.Component):
        DATA_WIDTH : zdc.u32 = zdc.const(default=32)
        ADDR_WIDTH : zdc.u32 = zdc.const(default=32)
        clock : zdc.bit = zdc.input()
        reset : zdc.bit = zdc.input()
        adr : zdc.bitv = zdc.input(width=lambda s:s.ADDR_WIDTH)
        dat_w : zdc.bitv = zdc.input(width=lambda s:s.DATA_WIDTH)
        dat_r : zdc.bitv = zdc.output(width=lambda s:s.DATA_WIDTH)
        cyc : zdc.bit = zdc.input()
        ack : zdc.bit = zdc.output()
        err : zdc.bit = zdc.output()
        sel : zdc.bitv = zdc.input(width=lambda s:int(s.DATA_WIDTH/8))
        we : zdc.bit = zdc.input()
        
        _state : zdc.u8 = zdc.field()
        _mem : zdc.u64 = zdc.field()
        
        @zdc.sync(clock=lambda s:s.clock, reset=lambda s:s.reset)
        def _target_fsm(self):
            if self.reset:
                self._state = 0
                self.ack = 0
                self.err = 0
                self.dat_r = 0
            else:
                match self._state:
                    case 0:
                        if self.cyc:
                            self._state = 1
                            self.ack = 1
                            if self.we:
                                # Write: store dat_w in memory
                                self._mem = self.dat_w
                            else:
                                # Read: provide data from memory
                                self.dat_r = self._mem
                    case 1:
                        self.ack = 0
                        self._state = 0

    # Generate Verilog
    factory = zdc.DataModelFactory()
    ctxt = factory.build([InitiatorXtor, WishboneInitiator, WishboneTarget])
    
    from zuspec.be.sv import SVGenerator
    output_dir = Path(tmpdir) / "sv"
    output_dir.mkdir(exist_ok=True)
    generator = SVGenerator(output_dir, debug_annotations=True)
    sv_files = generator.generate(ctxt)
    
    # Find generated InitiatorXtor module name
    xtor_module = None
    for f in sv_files:
        content = f.read_text()
        if "InitiatorXtor" in f.name and "interface" in content and "xtor_if" in content:
            import re
            match = re.search(r'module\s+(\S+)\s*[#(]', content)
            if match:
                xtor_module = match.group(1)
                print(f"Found transactor module: {xtor_module}")
                break
    
    assert xtor_module is not None, "Could not find InitiatorXtor module name"
    
    # Find target module name
    target_module = None
    for f in sv_files:
        content = f.read_text()
        if "WishboneTarget" in f.name and "module" in content:
            import re
            match = re.search(r'module\s+(\S+)\s*[#(]', content)
            if match:
                target_module = match.group(1)
                print(f"Found target module: {target_module}")
                break
    
    assert target_module is not None, "Could not find WishboneTarget module name"
    
    # Create testbench
    tb_content = f"""
module tb;
    logic clk = 0;
    logic rst = 1;
    
    // Clock generation
    initial begin
        forever begin
            #5ns;
            clk <= ~clk;
        end
    end
    
    // Reset generation
    initial begin
        #100ns;
        rst <= 0;
    end
    
    // Initiator-Target interconnect wires
    logic [31:0] adr;
    logic [31:0] dat_w;
    logic [31:0] dat_r;
    logic cyc;
    logic ack;
    logic err;
    logic [3:0] sel;
    logic we;
    
    // Instantiate InitiatorXtor
    {xtor_module} initiator (
        .clock(clk),
        .reset(rst),
        .init_adr(adr),
        .init_dat_w(dat_w),
        .init_dat_r(dat_r),
        .init_cyc(cyc),
        .init_err(err),
        .init_sel(sel),
        .init_ack(ack),
        .init_we(we)
    );
    
    // Instantiate WishboneTarget
    {target_module} target (
        .clock(clk),
        .reset(rst),
        .adr(adr),
        .dat_w(dat_w),
        .dat_r(dat_r),
        .cyc(cyc),
        .ack(ack),
        .err(err),
        .sel(sel),
        .we(we)
    );
    
    // Test stimulus
    initial begin
        logic [31:0] ret_dat;  // Changed from 64-bit to 32-bit to match task output
        logic ret_err;
        
        if ($test$plusargs("debug")) begin
            $dumpfile("dump.vcd");
            $dumpvars(0, tb);
        end
        
        $display("[TB] Starting test...");
        
        // Wait for reset
        @(negedge rst);
        repeat(5) @(posedge clk);
        
        // Test 1: Write operation
        $display("[TB] Test 1: Write 0xDEADBEEF to address 0x100");
        initiator.xtor_if.access(32'h100, 32'hDEADBEEF, 32'hF, 32'h1, ret_err, ret_dat);
        $display("[TB]   Write completed - err=%0b", ret_err);
        
        repeat(2) @(posedge clk);
        
        // Test 2: Read operation
        $display("[TB] Test 2: Read from address 0x100");
        initiator.xtor_if.access(32'h100, 32'h0, 32'hF, 32'h0, ret_err, ret_dat);
        $display("[TB]   Read completed - data=0x%08x, err=%0b", ret_dat, ret_err);
        
        if (ret_dat === 32'hDEADBEEF) begin
            $display("[TB] TEST PASSED: Read data matches written data");
        end else begin
            $display("[TB] TEST FAILED: Expected 0xDEADBEEF, got 0x%08x", ret_dat);
            $finish(1);
        end
        
        repeat(5) @(posedge clk);
        $display("[TB] All tests completed successfully");
        $finish(0);
    end
    
    // Timeout watchdog
    initial begin
        #10ms;
        $display("[TB] TIMEOUT: Test exceeded time limit");
        $finish(1);
    end
    
endmodule
"""
    
    # Write testbench
    tb_file = output_dir / "tb.sv"
    tb_file.write_text(tb_content)
    
    # Setup DFM and run simulation
    runner = TaskSetRunner(str(Path(tmpdir) / 'rundir'))
    
    def marker_listener(marker):
        from dv_flow.mgr.task_data import SeverityE
        if marker.severity == SeverityE.Error:
            print(f"ERROR: {marker.msg}")
            if marker.loc:
                print(f"  at {marker.loc.filename}:{marker.loc.line}")
            raise Exception(f"Marker error: {marker.msg}")
    
    builder = TaskGraphBuilder(
        PackageLoader(marker_listeners=[marker_listener]).load_rgy(['std', f'hdlsim.{sim}']),
        str(Path(tmpdir) / 'rundir'))
    
    sv_fileset = builder.mkTaskNode(
        'std.FileSet',
        name="sv_files",
        type="systemVerilogSource",
        base=str(output_dir),
        include="*.sv",
        needs=[])
    
    sim_img = builder.mkTaskNode(
        f"hdlsim.{sim}.SimImage",
        name="sim_img",
        top=['tb'],
        needs=[sv_fileset])
    
    sim_run = builder.mkTaskNode(
        f"hdlsim.{sim}.SimRun",
        name="sim_run",
        needs=[sim_img])
    
    runner.add_listener(TaskListenerLog().event)
    out = asyncio.run(runner.run(sim_run))
    
    assert runner.status == 0, f"Simulation failed with status {runner.status}"
    
    # Find simulation run directory
    rundir_fs = None
    for fs in out.output:
        if fs.type == 'std.FileSet' and fs.filetype == "simRunDir":
            rundir_fs = fs
    
    assert rundir_fs is not None, "Could not find simulation run directory"
    
    # Check simulation log
    sim_log_path = os.path.join(rundir_fs.basedir, "sim.log")
    assert os.path.isfile(sim_log_path), f"Simulation log not found at {sim_log_path}"
    
    with open(sim_log_path, "r") as f:
        sim_log = f.read()
    
    print(f"\n=== Simulation Log ({sim}) ===\n{sim_log}\n======================\n")
    
    # Verify test passed
    assert "TEST PASSED" in sim_log, f"Test did not pass for simulator {sim}"
