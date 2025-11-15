Implement a monitor transactor and UVM agent. The monitor core must expose an egress transactor with adr, dat, we, sel, err. The UVM agent must have an analysis port. The UVM agent must 
   implement run_phase to continuously read transactions from the transactor and write them to the analysis port.
