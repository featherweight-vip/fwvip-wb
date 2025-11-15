import os
import pytest
import pytest_fv as pfv
from pytest_fv.fixtures import *

@pytest.fixture
def initiator_tb_cfg(dirconfig : pfv.DirConfig):
    print("initiator_tb_cfg")
    testdir = os.path.dirname(os.path.abspath(__file__))
    flow = pfv.FlowSim(dirconfig)

    # Use local VIP sources instead of external vlnv
    flow.addFileset("sim",
            pfv.FSPaths(
                os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(__file__)))), "src/vip/sv"),
                [
                    "fwvip_wb_bfm_pkg.sv",
                    "fwvip_wb_initiator_core.sv",
                    "fwvip_wb_initiator_if.sv",
                    "fwvip_wb_target_core.sv",
                    "fwvip_wb_target_if.sv",
                    "fwvip_wb_monitor_core.sv",
                    "fwvip_wb_monitor_if.sv",
                    "../uvm/fwvip_wb_pkg.sv"
                ],
                stype="systemVerilogSource",
                incs=[
                    os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(__file__)))), "packages/uvm/src"),
                    os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(__file__)))), "src/vip/sv"),
                    os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(__file__)))), "src/vip/uvm"),
                    os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(__file__)))), "packages/fwprotocol-defs/verilog/rtl"),
                    os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(__file__)))), "packages/fwvip-common/src/vip")
                ]
            )
    )
    flow.addFileset("sim",
            pfv.FSPaths(
                dirconfig.test_srcdir(), [
                "sv/initiator_test_pkg.sv",
                "sv/initiator_tb.sv",
            ], 
            stype="systemVerilogSource",
            incs=[
                "sv",
                os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(__file__)))), "packages/svt/src")
            ]))
    flow.sim.top.add("initiator_tb")

    flow.sim.debug = True

    return flow

def run_test(flow, dirconfig, testname):
    run_args = flow.sim.mkRunArgs(dirconfig.rundir())
    run_args.plusargs.append("SVT_TESTNAME=%s" % testname)
    flow.addTaskToPhase(
        "run.main", 
        flow.sim.mkRunTask(run_args))

    flow.run_all()


def test_smoke(initiator_tb_cfg, dirconfig):
    run_test(initiator_tb_cfg, dirconfig, "my_test")

def test_basic_rw(initiator_tb_cfg, dirconfig):
    run_test(initiator_tb_cfg, dirconfig, "test_basic_rw")

def test_smoke2(initiator_tb_cfg, dirconfig):
    run_test(initiator_tb_cfg, dirconfig, "my_test")
