# Getting started

This page builds the VIP's example testbenches and runs them. Everything is driven through
**DV Flow Manager** (`dfm`). In this repository `dfm` loads `flow.dv`, the developer project
(`org.fwvip.wb.dev`), which imports the VIP exactly as a consumer would and adds the tests.
Consumers load `flow.yaml`, which holds the VIP sources only.

## Prerequisites

The VIP depends on the `fw-proto-wb` kit and `fwvip-core`, plus a simulator and UVM.
Dependencies are declared in `ivpm.yaml` and fetched with [IVPM](https://github.com/fvutils/ivpm);
the environment (tool `PATH`, `PYTHONPATH`, `UVM_HOME`, `IVPM_PACKAGES`) is set by the checked-in
`.envrc` via [direnv](https://direnv.net/).

```console
$ ivpm update                 # fetch deps into ./packages (the `dev` set)
$ direnv allow                # load .envrc: tool paths, PYTHONPATH=src/python, UVM_HOME, ...
```

```{admonition} CI does the same thing
:class: note
Both CI workflows call `ci/run.sh`, which runs these same steps and the same `dfm run`
commands as below -- so a green run locally is what CI checks too.
```

## Run the tests

`dfm run tests` is the one test command. What a test is lives in the suites wired into it --
`uvm`, `cocotb` and `formal` -- and cases are selected by path:

```console
$ dfm run tests-info                 # the suites and their cases; builds nothing
$ dfm run tests                      # everything
$ dfm run tests --tests uvm.err      # one case
$ dfm run smoke                      # one case per harness
```

`tests-uvm`, `tests-cocotb` and `tests-formal` are the same command restricted to one kind of
harness, because not every harness runs on every tool.

### UVM

All UVM cases share one simulation image and the single base test `fwvip_wb_test_base`; the
scenario is selected by a `+SEQ=<vseq>` plusarg, which each case supplies:

```console
$ dfm run tests-uvm                  # smoke, write, read, rand, sel, err, reg
$ dfm run tests --tests uvm.reg      # uvm_reg front door (see register-model)
```

Extra knobs append as plusargs to the scenario (e.g. `+NUM_TXNS`, `+BASE_ADDR`).
`uvm-sim-run-base` is the bare run (defaults to the smoke sequence).

### cocotb

The cocotb test drives the same VIP through its Python front-end. cocotb is a mode the
simulator runs in, so the simulator is the `--sim` knob:

```console
$ dfm run tests-cocotb               # Verilator
$ dfm run tests-cocotb --sim ivl     # Icarus
```

See {doc}`cocotb` for the Python API these exercise.

### Formal

```console
$ dfm run tests-formal               # bounded proof of the initiator against the kit's checker
```

## Build the docs (this site)

```console
$ python -m pip install -r docs/requirements.txt
$ sphinx-build -b html -W --keep-going docs docs/_build/html
$ open docs/_build/html/index.html
```

The `-W` flag turns warnings into errors, matching the `Docs` GitHub Actions workflow.
