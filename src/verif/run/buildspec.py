
import os
import pytest
from pytest_fv import *
import shutil

def buildspec(request):
    rundir = os.path.dirname(os.path.abspath(__file__))
    fwvip_wb_dir = os.path.abspath(os.path.join(rundir, "../../"))

    fs = FuseSoc()
    fs.add_library(os.path.join(fwvip_wb_dir, "vip"))
    fs.add_library(os.path.join(fwvip_wb_dir, "verif/verification_ip"))
    fs.add_library(os.path.join(fwvip_wb_dir, "verif/project_benches"))
    fs.add_library(os.path.abspath(
        os.path.join(fwvip_wb_dir, "../packages/uvmf-core/src/uvmf/share/uvmf_base_pkg")))

    test_builddir = os.path.join(rundir, "rundir")
    test_rundir = os.path.join(rundir, "rundir/run")

    if not os.path.isdir(test_builddir):
        os.makedirs(test_builddir)

    if os.path.isdir(test_rundir):
        shutil.rmtree(test_rundir)
    os.makedirs(test_rundir)

    sim = HdlSim.create(test_builddir)
    sim.debug = True
    sim.top.add("hdl_top")
    sim.top.add("hvl_top")
    sim.addFiles(fs.getFiles("uvmf:project_benches:fwvip_wb_b2b_tb"), flags={"sv-uvm": True})

    sim.build()

    return (test_rundir, sim)

