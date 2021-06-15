#/bin/bash
bonus.py > sim_inputs.hex
# Use -d JTFRAME_J68 for J68_cpu
# compare frame 1604 (FX) with 1599 (J68)

function convert {
    simvisdbutil $1.shm -radix hex -output $1.csv -csv -timeunits ns  -overwrite
}

function delete_old {
    rm -f $1.csv
    rm -rf $1.shm
    mv test.shm $1.shm
}

# end of bonus: -d DUMP_START=1560
ARG="-nosnd -d NOIRQ -frame 100 -w"
# J68
sim.sh -d JTFRAME_J68 $ARG
delete_old noirq_j68
convert noirq_j68
# Fx68k
echo Fx68k
sim.sh $ARG
delete_old noirq_fx68.shm
convert noirq_fx68

go run cmpwrites.go