
# Prompt
Implement a Wishbone initiator transactor in fwvip_wb_initiator_core.sv. The transactor operates as follows:
- Accepts requests via a FIFO interface req_. Drive request data on the 'i' port of the transactor
- Returns responses via a FIFO interface rsp_. 
- Ensure that a new request is only driven once a response to the previous request is received.
You may reference the Wishbone protocol docs here: https://wishbone-interconnect.readthedocs.io/en/latest/03_classic.html. Use `curl` to access docs

# What worked
Mostly everything

# What didn't
- Tried to use a very manual method to convert between struct and wire
-> Convert FIFO data to/from the req_s and rsp_s packed structs
- Had to be corrected with macro usage not to use '.' separators
-> The RV macros produce names like req_data, req_valid, req_ready. Don't use dots



