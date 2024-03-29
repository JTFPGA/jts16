../../hdl/jts16_game.v
../../hdl/jts16_cen.v
../../hdl/jts16_video.v
../../hdl/jts16_char.v
../../hdl/jts16_scr.v
../../hdl/jts16_sdram.v
../../hdl/jts16_colmix.v
../../hdl/jts16_obj.v
../../hdl/jts16_obj_ram.v
../../hdl/jts16_obj_draw.v
../../hdl/jts16_obj_scan.v
../../hdl/jts16_main.v
../../hdl/jts16_mmr.v
../../hdl/jts16_snd.v
../../hdl/jts16_pcm.v
../../hdl/jts16_fd1089.v
../../hdl/jts16_trackball.v

# FD1094 - only for some versions
../../hdl/jts16_fd1094.v
../../hdl/jts16_fd1094_ctrl.v
../../hdl/jts16_fd1094_dec.v

$JTFRAME/hdl/jtframe_sh.v
$JTFRAME/hdl/jtframe_ff.v
$JTFRAME/hdl/clocking/jtframe_frac_cen.v
$JTFRAME/hdl/video/jtframe_vtimer.v
$JTFRAME/hdl/video/jtframe_blank.v
$JTFRAME/hdl/video/jtframe_linebuf.v
$JTFRAME/hdl/ram/jtframe_ram.v
$JTFRAME/hdl/ram/jtframe_prom.v
$JTFRAME/hdl/ram/jtframe_dual_ram.v
$JTFRAME/hdl/ram/jtframe_dual_ram16.v
$JTFRAME/hdl/ram/jtframe_obj_buffer.v
$JTFRAME/hdl/sound/jtframe_mixer.v
$JTFRAME/hdl/sdram/jtframe_dwnld.v
-F $JTFRAME/hdl/sdram/jtframe_sdram64.f

# 68000
-F $JTFRAME/hdl/cpu/jtframe_m68k.f

# 8255
$MODULES/jt8255/hdl/jt8255.v
