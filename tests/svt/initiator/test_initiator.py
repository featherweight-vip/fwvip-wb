import os
import pytest
import pytest_fv as pfv
from pytest_fv.fixtures import *

@pytest.fixture
def initiator_tb_cfg(dirconfig):
    testdir = os.path.dirname(os.path.abspath(__file__))
    flow = pfv.FlowSim(dirconfig)

    flow.addFileset("sim", pfv.FSVlnv("featherweight-vip::wb", ("systemVerilogSource",)))
    flow.addFileset("sim",
            pfv.FSPaths([
                os.path.join(testdir, "initiator_test_pkg.sv"),
                os.path.join(testdir, "initiator_tb.sv"),
            ], 
            stype="systemVerilogSource"))
    flow.sim.top.add("initiator_tb")

    return flow

def test_smoke(initiator_tb_cfg, dirconfig):
    print("Hello: %s" % dirconfig.rundir())
    print("HdlSim: %s" % str(dirconfig.config.getHdlSim()))

    run_args = initiator_tb_cfg.sim.mkRunArgs(dirconfig.rundir())
    run_args.plusargs.append("SVT_TESTNAME=my_test")
    initiator_tb_cfg.addTaskToPhase(
        "run.main", 
        initiator_tb_cfg.sim.mkRunTask(run_args))

    initiator_tb_cfg.run_all()

