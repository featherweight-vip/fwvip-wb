# Getting started

This page builds the VIP's example testbenches and runs them. Everything is driven through
**DV Flow Manager** (`dfm`) tasks in the `org.fwvip.wb` package.

## Prerequisites

The VIP depends on the `fw-proto-wb` kit and `fwvip-core` (imported by the top-level
`flow.yaml`), plus a simulator and UVM. Dependencies are declared in `ivpm.yaml` and fetched
with [IVPM](https://github.com/fvutils/ivpm); the environment (tool `PATH`, `PYTHONPATH`,
`UVM_HOME`, `IVPM_PACKAGES`) is set by the checked-in `.envrc` via
[direnv](https://direnv.net/).

```console
$ ivpm update                 # fetch deps into ./packages (default + default-dev sets)
$ direnv allow                # load .envrc: tool paths, PYTHONPATH=src/python, UVM_HOME, ...
```

```{admonition} CI does the same thing
:class: note
`.github/workflows/ci.yml` performs exactly these steps with the `fvutils/ivpm-setup` and
`dv-flow/run-dvflow` actions — so a green `dfm run` locally is what CI checks too.
```

## Run the UVM tests

All UVM scenarios share one simulation image and the single base test
`fwvip_wb_test_base`; the scenario is selected by a `+SEQ=<vseq>` plusarg, which each `dfm`
task supplies for you.

```console
$ dfm run org.fwvip.wb.uvm-test-smoke      # block of writes + self-checked read-back
$ dfm run org.fwvip.wb.uvm-test-write      # write-only traffic
$ dfm run org.fwvip.wb.uvm-test-read       # read traffic
$ dfm run org.fwvip.wb.uvm-test-rand       # randomized access
$ dfm run org.fwvip.wb.uvm-test-sel        # byte-select coverage
$ dfm run org.fwvip.wb.uvm-test-err        # error-termination handling
$ dfm run org.fwvip.wb.uvm-test-reg        # uvm_reg front door (see register-model)
```

Extra knobs append as plusargs to the scenario (e.g. `+NUM_TXNS`, `+BASE_ADDR`).
`org.fwvip.wb.uvm-sim-run-base` is the bare run (defaults to the smoke sequence).

## Run the transactor-core and monitor smokes

```console
$ dfm run org.fwvip.wb.core-b2b-sim-run    # initiator-core <-> target-core, back-to-back
$ dfm run org.fwvip.wb.mon-sim-run         # monitor core, standalone
```

## Run the cocotb front-end check

The cocotb test drives the same VIP through its Python front-end. It runs on **both**
simulators:

```console
$ dfm run org.fwvip.wb.cocotb-check        # Verilator
$ dfm run org.fwvip.wb.cocotb-ivl-check    # Icarus
```

See {doc}`cocotb` for the Python API these exercise.

## Build the docs (this site)

```console
$ python -m pip install -r docs/requirements.txt
$ sphinx-build -b html -W --keep-going docs docs/_build/html
$ open docs/_build/html/index.html
```

The `-W` flag turns warnings into errors, matching the `Docs` GitHub Actions workflow.
