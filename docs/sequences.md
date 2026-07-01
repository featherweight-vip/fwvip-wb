# Writing sequences

Three things to drive a Wishbone bench with `fwvip-wb`: stimulate the **initiator**, write a
**target responder**, and **subscribe** to the monitor. Worked source is in `tests/uvm/env/`.

## Driving the initiator

The initiator driver pulls a `fwvip_wb_transaction` off its sequencer and calls
`m_cfg.access(t)`, which drives the request and captures the response **in place** — read data
lands in `t.dat`, error in `t.err`. Any `uvm_sequence #(fwvip_wb_transaction)` on the initiator
sequencer is valid stimulus:

```systemverilog
class my_write_seq extends uvm_sequence #(fwvip_wb_transaction);
    `uvm_object_utils(my_write_seq)
    function new(string name="my_write_seq"); super.new(name); endfunction
    task body();
        fwvip_wb_transaction t = fwvip_wb_transaction::type_id::create("t");
        start_item(t);
        t.adr = 'h1000; t.dat = 'hA5A5_A5A5; t.sel = '1; t.we = 1'b1;
        finish_item(t);
        // for a read: t.we = 0; after finish_item, t.dat / t.err hold the response
    endtask
endclass
```

The reusable single-access sequence (`tests/uvm/env/fwvip_wb_init_access_seq.svh`) does exactly
this, and the **base virtual sequence** exposes convenience helpers:

```systemverilog
do_write(adr, dat, sel='1);
do_read (adr, dat, err, sel='1);
```

## Writing a target responder

The target is a **callback responder**, not a poller. Extend `fwvip_wb_target_seq` and override
`handle_request(fwvip_wb_transaction t)`. The kit's `wb_target_xtor_bridge` polls the request
FIFO and calls `config_p.access()`, which rendezvous through `driver.service()` → the sequencer
→ your `handle_request()`. Fill `t.dat` (reads) and/or set `t.err`; the response is sent back
automatically.

The memory responder (`tests/uvm/env/fwvip_wb_mem_target_seq.svh`):

```systemverilog
class fwvip_wb_mem_target_seq extends fwvip_wb_target_seq;
    `uvm_object_utils(fwvip_wb_mem_target_seq)
    bit [DATA_WIDTH_MAX-1:0] mem [bit [ADDR_WIDTH_MAX-1:0]];
    virtual task handle_request(fwvip_wb_transaction t);
        bit [ADDR_WIDTH_MAX-1:0] wa = t.adr >> 2;   // word address
        t.err = 1'b0;
        if (t.we) mem[wa] = t.dat;
        else      t.dat   = (mem.exists(wa)) ? mem[wa] : '0;
    endtask
endclass
```

Start it running forever on the target sequencer (the base vseq does this via
`create_responder()`):

```systemverilog
fwvip_wb_target_seq resp = create_responder();
fork resp.start(p_sequencer.targ_seqr); join_none
```

```{admonition} Only override handle_request()
:class: warning
Do not poll the bus from the responder — the responder is *called*. `access()`, `body()`, and
the `fwvip_wb_target_item` wrapper plumbing are already provided; override `handle_request()`
only.
```

## Subscribing to the monitor

`fwvip_wb_monitor_agent` publishes a `fwvip_wb_transaction` per observed access on its
`uvm_analysis_port ap`. Connect any `uvm_analysis_imp` / subscriber — the env connects the
scoreboard:

```systemverilog
m_mon.ap.connect(m_sb.analysis_export);   // see fwvip_wb_env::connect_phase
```

Each published item carries `adr` / `dat` / `we` / `sel` / `err` (read data is filled for
reads), so a scoreboard can self-check read-back against expected writes.

## Putting it together — a virtual sequence

The base virtual sequence (`tests/uvm/env/fwvip_wb_vseq_base.svh`) reads `+NUM_TXNS` /
`+BASE_ADDR`, forks the responder, waits on reset, then issues `do_write` / `do_read`. The
sequence library (`fwvip_wb_vseq_lib.svh`) adds the write / read / smoke / rand / sel / err
variants selected by the `+SEQ=<vseq>` plusarg. New scenarios subclass the base vseq and add
stimulus — no new test class is needed.
