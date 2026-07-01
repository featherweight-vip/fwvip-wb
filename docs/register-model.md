# Register-model front door

Because Wishbone is addressed, `fwvip-wb` ships a `uvm_reg` adapter so a register model can
issue front-door accesses through the initiator. Worked source:
`tests/uvm/tests/fwvip_wb_vseq_reg.svh`.

## The adapter

`fwvip_wb_reg_adapter` maps `uvm_reg_bus_op` ↔ `fwvip_wb_transaction`:

- **`reg2bus`** builds a transaction: `we = (kind == UVM_WRITE)`, `sel = '1` (full byte enable),
  `adr` / `dat` from the bus op.
- **`bus2reg`** reports `status = err ? UVM_NOT_OK : UVM_IS_OK` and `n_bits = DATA_WIDTH_MAX`,
  and copies `adr` / `dat` / `kind` back from the transaction.

## Hooking it up

Create the adapter and attach it to the register block's map, pointing the map's sequencer at
the **initiator** sequencer:

```systemverilog
fwvip_wb_reg_adapter adapter = fwvip_wb_reg_adapter::type_id::create("adapter");
blk.default_map.set_sequencer(p_sequencer.init_seqr, adapter);

blk.r.write(status, 'hA5A5A5A5, .parent(this));
blk.r.read (status, rdat,       .parent(this));
```

Front-door reads return whatever the **target responder** holds, so the background memory
responder (see {doc}`sequences`) must be running for a read to observe a prior write. The
`org.fwvip.wb.uvm-test-reg` scenario exercises exactly this path.

```{admonition} Why no back door
:class: note
The VIP models the *bus*, not a DUT's storage — there is no register file behind it to peek.
Reads are serviced by whatever responder you install on the target; with the memory responder, a
front-door read-back reflects earlier front-door writes.
```
