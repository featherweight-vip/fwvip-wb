import os
import pytest
import pytest_fv as pfv
from pytest_fv.fixtures import *


def test_smoke(dirconfig: pfv.DirConfig):
    flow = pfv.FlowSim(dirconfig)

    repo = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../.."))

    # UVM
    flow.addFileset("sim", pfv.FSPaths(
        os.path.join(repo, "packages/uvm/src"), [
            "uvm_pkg.sv"
        ],
        stype="systemVerilogSource",
        incs=[os.path.join(repo, "packages/uvm/src")]
    ))

    # VIP BFMs
    flow.addFileset("sim", pfv.FSPaths(
        os.path.join(repo, "src/vip/sv"), [
            "fwvip_wb_bfm_pkg.sv",
            "fwvip_wb_initiator_core.sv",
            "fwvip_wb_initiator_if.sv",
            "fwvip_wb_target_core.sv",
            "fwvip_wb_target_if.sv",
            "fwvip_wb_monitor_core.sv",
            "fwvip_wb_monitor_if.sv",
        ],
        stype="systemVerilogSource",
        incs=[
            os.path.join(repo, "packages/fwprotocol-defs/verilog/rtl"),
            os.path.join(repo, "src/vip/sv"),
            os.path.join(repo, "packages/fwvip-common/src/vip")
        ]
    ))

    # VIP UVM
    flow.addFileset("sim", pfv.FSPaths(
        os.path.join(repo, "src/vip/uvm"), [
            "fwvip_wb_pkg.sv"
        ],
        stype="systemVerilogSource",
        incs=[os.path.join(repo, "src/vip/uvm")]
    ))

    # Env, Tests, and TB tops
    flow.addFileset("sim", pfv.FSPaths(
        os.path.join(repo, "src/verif/env"), [
            "fwvip_wb_env_pkg.sv"
        ],
        stype="systemVerilogSource",
        incs=[os.path.join(repo, "src/verif/env")]
    ))
    flow.addFileset("sim", pfv.FSPaths(
        os.path.join(repo, "src/verif/tests"), [
            "fwvip_wb_tests_pkg.sv"
        ],
        stype="systemVerilogSource",
        incs=[os.path.join(repo, "src/verif/tests")]
    ))
    flow.addFileset("sim", pfv.FSPaths(
        os.path.join(repo, "src/verif/tb"), [
            "fwvip_wb_hdl_top.sv",
            "fwvip_wb_hvl_top.sv"
        ],
        stype="systemVerilogSource",
        incs=[
            os.path.join(repo, "src/verif/tb"),
            os.path.join(repo, "src/vip/uvm")
        ]
    ))

    flow.sim.top.add("fwvip_wb_hvl_top")

    run_args = flow.sim.mkRunArgs(dirconfig.rundir())
    run_args.plusargs.append("UVM_TESTNAME=fwvip_wb_test_init")
    flow.addTaskToPhase("run.main", flow.sim.mkRunTask(run_args))

    flow.run_all()
