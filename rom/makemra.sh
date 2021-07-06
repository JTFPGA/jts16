#!/bin/bash

cd $JTUTIL/src
make || exit $?
cd -
echo "------------"


OUTDIR=mra

mkdir -p $OUTDIR
mkdir -p $OUTDIR/_alt

AUXTMP=/tmp/$RANDOM$RANDOM
DEF=$CORES/s16/hdl/jts16.def
jtcfgstr -target=mist -output=bash -def $DEF|grep _START > $AUXTMP
source $AUXTMP

function s16a_mra {
    NAME=$1
    FOLDER=$2
    BUTTONS="$3"
    DIPS="$4"
    CATEGORY="$5"
    PLATFORM="$6"
    CATVER="${SUBCATEGORY}"
    ALTFOLDER="_alt/_$FOLDER"
    mkdir -p "$OUTDIR/$ALTFOLDER"
    
    CATVER=`egrep "^${NAME}=" catver.ini | head -1 | cut -d '=' -f 2- | tr -d '\r' | tr -d '\n'`
    if [ -z "${CATVER}" ]; then
        CATVER="${SUBCATEGORY}"
    fi
    
    mame2mra -def $DEF -toml s16a.toml -xml $NAME.xml \
        -outdir $OUTDIR -altdir "$ALTFOLDER" \
        -info platform="$PLATFORM" \
        -info category="$CATEGORY" \
        -info catver="$CATVER" \
        -buttons "$BUTTONS"
}
#Sega Pre-System 16
s16a_mra bodyslam  "Body Slam"                       "Punch/Throw,Kick/Pin,Get Up/Tag"                                      "ff,fd" "Sports"        "Sega S16A"
s16a_mra mjleague  "Major League"                    "Open Stance,Curb/Shoot/Fork,Close Stance,Pinch Hitter/Sliding/Runner" "ff,ff" "Sports"        "Sega S16A"
s16a_mra quartet   "Quartet"                         "Jump,Shot"                                                            "ff,ff" "Run & Gun"     "Sega S16A"
#Sega System 16A
s16a_mra aceattac  "Ace Attacker"                    "None"                                                                 "ff,ff" "Sports"        "Sega S16A"
s16a_mra afighter  "Action Fighter"                  "Shot,Special Weapon,-"                                                "ff,fc" "Shoot'em Up"   "Sega S16A"
s16a_mra alexkidd  "Alex Kidd"                       "Jump/Swim,Shot"                                                       "ff,ec" "Platformer"    "Sega S16A"
s16a_mra aliensyn  "Alien Syndrome"                  "Shot"                                                                 "ff,ff" "Run & Gun"     "Sega S16A"
s16a_mra fantzone  "Fantasy Zone"                    "Shot,Bomb"                                                            "ff,fc" "Shoot'em Up"   "Sega S16A"
s16a_mra passsht   "Passing Shot"                    "Flat,Slice,Lob,Top Spin"                                              "ff,ff" "Sports"        "Sega S16A"
s16a_mra sdi       "SDI"                             "Shot"                                                                 "ff,ff" "Shoot'em Up"   "Sega S16A"
s16a_mra shinobi   "Shinobi"                         "Shuriken,Jump,Magic"                                                  "ff,fc" "Hack & Slash"  "Sega S16A"
s16a_mra sjryuko   "Sukeban"                         "None"                                                                 "ff,ff" "Puzzle"        "Sega S16A"
s16a_mra tetris    "Tetris"                          "Rotate,Rotate,Rotate"                                                 "ff,fd" "Puzzle"        "Sega S16A"
s16a_mra timescan  "Time Scanner"                    "L. Flipper/Ball Start,R. Flipper/Lane Shift,-"                        "ff,ff" "Pinball"       "Sega S16A"
s16a_mra wb3       "Wonder Boy 3"                  "Shot,Jump"                                                            "ff,fd" "Platformer"    "Sega S16A"

function s16b_mra {
    NAME=$1
    FOLDER=$2
    BUTTONS="$3"
    DIPS="$4"
    CATEGORY="$5"
    PLATFORM="$6"
    CATVER="${SUBCATEGORY}"
    ALTFOLDER="_alt/_$FOLDER"
    mkdir -p "$OUTDIR/$ALTFOLDER"
    
    CATVER=`egrep "^${NAME}=" catver.ini | head -1 | cut -d '=' -f 2- | tr -d '\r' | tr -d '\n'`
    if [ -z "${CATVER}" ]; then
        CATVER="${SUBCATEGORY}"
    fi
    
    mame2mra -def $DEF -toml s16b.toml -xml $NAME.xml \
        -outdir $OUTDIR -altdir "$ALTFOLDER" \
        -info platform="$PLATFORM" \
        -info category="$CATEGORY" \
        -info catver="$CATVER" \
        -buttons "$BUTTONS"
}
#Sega System 16B
s16b_mra aceattac       "Ace Attacker"                         "None"                                                       "ff,ff" "Sports"       "Sega S16B"
s16b_mra afighter       "Action Fighter"                       "Shot,Special Weapon,-"                                      "ff,ff" "Shoot'em Up"  "Sega S16B"
s16b_mra aliensyn       "Alien Syndrome"                       "Shot"                                                       "ff,ff" "Run & Gun"    "Sega S16B"
s16b_mra altbeast       "Altered Beast"                        "Punch,Kick,Jump"                                            "ff,ff" "Platformer"   "Sega S16B"
s16b_mra aurail         "Aurail"                               "Rapid Shot,Kite/Turn,Shield"                                "ff,ff" "Shoot'em Up"  "Sega S16B"
s16b_mra bayroute       "Bay Route"                            "Shot,Jump,Select"                                           "ff,ff" "Run & Gun"    "Sega S16B"
s16b_mra bullet         "Bullet"                               "Shot (Left),Shot (Right),Shot (Forward),Shot (Behind)"      "ff,ff" "Run & Gun"    "Sega S16B"
#Sega System 16B - Charon
s16b_mra cotton         "Cotton"                               "Shoot/Magic,Bomb/Nymphs"                                    "ff,ff" "Shoot'em Up"  "Sega S16B"
s16b_mra ddux           "Dynamite Dux"                         "Shot,Jump"                                                  "ff,ff" "Platformer"   "Sega S16B"
s16b_mra dunkshot       "Dunk Shot"                            "Shot,Pass"                                                  "ff,ff" "Sports"       "Sega S16B"
s16b_mra eswat          "Cyber Police ESWAT"                   "Shot,Jump,Special Weapons"                                  "ff,ff" "Platformer"   "Sega S16B"
s16b_mra exctleag       "Excite League"                        "Change,Select,Chase"                                        "ff,ff" "Sports"       "Sega S16B"
s16b_mra fpoint         "Flash Point"                          "Rotate,Rotate,Rotate"                                       "ff,ff" "Puzzle"       "Sega S16B"
s16b_mra goldnaxe       "Golden Axe"                           "Attack,Jump,Magic"                                          "ff,ff" "Platformer"   "Sega S16B"
s16b_mra hwchamp        "Heavyweight Champ"                    "BUTTONS"                                                    "ff,ff" "Sports"       "Sega S16B"
s16b_mra mvp            "M.V.P"                                "BUTTONS"                                                    "ff,ff" "Sports"       "Sega S16B"
s16b_mra passsht        "Passing Shot"                         "Flat,Slice,Lob,Top Spin"                                    "ff,ff" "Sports"       "Sega S16B"
s16b_mra riotcity       "Riot City"                            "Attack,Jump"                                                "ff,ff" "Beat'em Up"   "Sega S16B"
s16b_mra ryukyu         "RyuKyu"                               "Cancel,Decide"                                              "ff,ff" "Puzzle"       "Sega S16B"
s16a_mra sdi            "SDI"                                  "Shot"                                                       "ff,ff" "Shoot'em Up"  "Sega S16B"
s16b_mra sonicbom       "Sonic Boom"                           "Shot,Super Shot"                                            "ff,ff" "Shoot'em Up"  "Sega S16B"
s16a_mra shinobi        "Shinobi"                              "Shuriken,Jump,Magic"                                        "ff,fc" "Hack & Slash" "Sega S16B"
s16b_mra sjryuko        "Sukeban"                              "None"                                                       "ff,ff" "Puzzle"       "Sega S16B"
s16b_mra suprleag       "Super League"                         "Change,Select,Chase"                                        "ff,ff" "Sports"       "Sega S16B"
s16a_mra tetris         "Tetris"                               "Rotate,Rotate,Rotate"                                       "ff,fd" "Puzzle"       "Sega S16B"
s16b_mra timescan       "Time Scanner"                         "L. Flipper/Ball Start,R. Flipper/Lane Shift,-"              "ff,ff" "Pinball"      "Sega S16B"
s16b_mra toryumon       "Toryumon"                             "Block Turn"                                                 "ff,ff" "Puzzle"       "Sega S16B"
s16b_mra tturf          "Tough Turf"                           "Punch,Kick,Jump"                                            "ff,ff" "Beat'em Up"   "Sega S16B"
s16b_mra ultracin       "Waku Waku Ultraman Racing"            "Attack"                                                     "ff,ff" "Racing"       "Sega S16B"
s16b_mra wb3            "Wonder Boy 3"                       "Shot,Jump"                                                  "ff,fd" "Platformer"   "Sega S16B"
s16b_mra wrestwar       "Wrestle War"                          "Punch,Kick"                                                 "ff,ff" "Sports"       "Sega S16B"
#Sega System 16C
s16b_mra fantzn2x       "Fantasy Zone II The Tears of Opa-Opa" "Shot,Bomb"                                                  "ff,ff" "Shoot'em Up"  "Sega S16C"
#Sega System 16B - Korean
s16b_mra atomicp        "Atomic Point"                         "Rotate"                                                     "ff,ff" "Puzzle"       "Sega S16B"
s16b_mra snapper        "Snapper"                              "Left,Right,Shot"                                            "ff,ff" "Puzzle"       "Sega S16B"
s16b_mra lockonph       "Lock On"                              "Shot,Bomb"                                                  "ff,ff" "Shoot'em Up"  "Sega S16B"
s16b_mra dfjail         "The Destroyer From Jail"              "Assualt Rifle,Jump,R.P.G"                                   "ff,ff" "Run & Gun"    "Sega S16B"

# echo "Enter MiSTer's root password"
# scp -r mra/* root@MiSTer.home:/media/fat/_S16
