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
ARG="-nosnd -video 100 -w"

if [ $1 = J68 ]; then
    echo J68; sleep 2
    # J68
    sim.sh -d JTFRAME_J68 $ARG
    delete_old slow_j68
    convert slow_j68
else
    echo FX68; sleep 2
    # Fx68k
    echo Fx68k
    sim.sh $ARG
    delete_old slow_fx68
    convert slow_fx68
fi

go run cmpwrites.go
