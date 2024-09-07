import os
import pytest
import pytest_fv as pfv
from pytest_fv.fixtures import *

@pytest.fixture
def initiator_tb_cfg(dirconfig : pfv.DirConfig):
    print("initiator_tb_cfg")
    testdir = os.path.dirname(os.path.abspath(__file__))
    flow = pfv.FlowSim(dirconfig)

    flow.addFileset("sim", pfv.FSVlnv("featherweight-vip::wb", ("systemVerilogSource",)))
    flow.addFileset("sim",
            pfv.FSPaths(
                dirconfig.test_srcdir(), [
                "sv/initiator_test_pkg.sv",
                "sv/initiator_tb.sv",
            ], 
            stype="systemVerilogSource",
            incs=["sv"]))
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
