
# Prompt
Update fwvip_wb_hdl_top.sv to:
- Add a clock and reset generator
- Create instances of fwvip_wb_initator and fwvip_wb_target
- Create a wishbone bus bundle using the macros and connect it to the instances using macros

Test your work by running `dfm run sim-img`. Correct any issues. 
Use the '_core' types in both cases

# What worked
- Correct content for clock and reset
- Followed direction to use macros
- Created localparams for modularity

# What didn't
- Struggled to get semicolons right, but eventually did using feedback
- Doesn't realize that the target and initiator transactors need 
  to be parameterized (or, it might, and realizes that the values are the same)

