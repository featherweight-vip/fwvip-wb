import pytest
from .buildspec import buildspec

def test_smoke(request):
    test_rundir, sim = buildspec(request)

    runargs = sim.mkRunArgs(test_rundir)
    runargs.plusargs.append("UVM_TESTNAME=test_top")
    sim.run(runargs)

    pass