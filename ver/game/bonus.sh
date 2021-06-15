#/bin/bash
bonus.py > sim_inputs.hex
# Use -d JTFRAME_J68 for J68_cpu
# compare frame 1604 (FX) with 1599 (J68)

# end of bonus: -d DUMP_START=1560
ARG="-nosnd  -video 1760 -d SHINOBI_BONUS -w -inputs"
# J68
#sim.sh -d JTFRAME_J68 $ARG
#mv test.shm new_j68.shm
# Fx68k
sim.sh $ARG
mv test.shm new_fx68.shm
