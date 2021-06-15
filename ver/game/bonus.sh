#/bin/bash
bonus.py > sim_inputs.hex
# Use -d JTFRAME_J68 for J68_cpu
# compare frame 1604 (FX) with 1599 (J68)

function convert {
    simvisdbutil $1.shm -radix hex -output $1.csv -csv -timeunits ns  -overwrite
}

# end of bonus: -d DUMP_START=1560
ARG="-nosnd  -video $((1760*2)) -d SHINOBI_BONUS -w -inputs"

if [ $1 = J68 ]; then
    echo J68; sleep 2
    # J68
    sim.sh -d JTFRAME_J68 $ARG
    mv test.shm new_j68.shm
    convert new_j68
else
    echo FX68; sleep 2
    # Fx68k
    sim.sh $ARG
    mv test.shm new_fx68.shm
    convert new_fx68
fi