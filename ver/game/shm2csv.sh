#/bin/bash
RANGE="-range 0.0004:3s"

simvisdbutil new_fx68.shm -radix hex -output new_fx68.csv -csv -timeunits ns  $RANGE -overwrite

simvisdbutil /nobackup/jtejada/git/jts16/ver/game/new_j68.shm -radix hex -output new_j68.csv -csv -timeunits ns $RANGE -overwrite
