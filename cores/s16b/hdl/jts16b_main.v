/*  This file is part of JTS16.
    JTS16 program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    JTS16 program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with JTS16.  If not, see <http://www.gnu.org/licenses/>.

    Author: Jose Tejada Gomez. Twitter: @topapate
    Version: 1.0
    Date: 5-7-2021 */

module jts16b_main(
    input              rst,
    input              clk,
    input              clk24,       // required to ease MCU synthesis
    input              clk_rom,
    output             cpu_cen,
    output             mcu_cen,
    output             cpu_cenb,
    input  [7:0]       game_id,

    // Video
    input              vint,

    // Video circuitry
    output reg         char_cs,
    output reg         pal_cs,
    output reg         objram_cs,
    input       [15:0] char_dout,
    input       [15:0] pal_dout,
    input       [15:0] obj_dout,
    output reg         flip,
    output reg         video_en,
    output             colscr_en,
    output             rowscr_en,
    output reg  [ 5:0] tile_bank,

    // RAM access
    output reg         ram_cs,
    output reg         vram_cs,
    input       [15:0] ram_data,   // coming from VRAM or RAM
    input              ram_ok,
    // CPU bus
    output      [15:0] cpu_dout,
    output             UDSWn,
    output             LDSWn,
    output             RnW,
    output      [12:1] cpu_addr,

    // cabinet I/O
    input       [ 7:0] joystick1,
    input       [ 7:0] joystick2,
    input       [ 7:0] joystick3,
    input       [ 7:0] joystick4,
    input       [15:0] joyana1,
    input       [15:0] joyana2,
    input       [15:0] joyana3,
    input       [15:0] joyana4,
    input       [ 3:0] start_button,
    input       [ 3:0] coin_input,
    input              service,
    // ROM access
    output reg         rom_cs,
    output reg  [18:1] rom_addr,
    input       [15:0] rom_data,
    input              rom_ok,

    // Decoder configuration
    input              dec_en,
    input              dec_type,
    input       [12:0] prog_addr,
    input              key_we,
    input              fd1089_we,
    input       [ 7:0] prog_data,

    // DIP switches
    input              dip_pause,
    input              dip_test,
    input    [7:0]     dipsw_a,
    input    [7:0]     dipsw_b,

    // MCU enable and ROM programming
    input              mcu_en,
    input              mcu_prog_we,

    // Sound - Mapper interface
    input              sndmap_rd,
    input              sndmap_wr,
    input    [7:0]     sndmap_din,
    output   [7:0]     sndmap_dout,
    output             sndmap_obf, // pbf signal == buffer full ?

    // NVRAM - debug
    input       [16:0] ioctl_addr,
    output      [ 7:0] ioctl_din,

    // status dump
    input       [ 7:0] debug_bus,
    input       [ 7:0] st_addr,
    output      [ 7:0] st_dout
);

localparam [7:0] GAME_SDI=1,
                 GAME_PASSSHT=2,
                 GAME_BULLET=8'h11,
                 GAME_PASSSHT2='h13,
                 GAME_PASSSHT3='h18;


//  Region 0 - Program ROM
//  Region 3 - 68000 work RAM
//  Region 4 - Text/tile RAM
//  Region 5 - Object RAM
//  Region 6 - Color RAM
//  Region 7 - I/O area
localparam [2:0] REG_RAM  = 3,
                 REG_ORAM = 4,
                 REG_VRAM = 5,
                 REG_PAL  = 6,
                 REG_IO   = 7;

reg         game_passsht;

wire [23:1] A;
wire        BERRn;
wire [ 2:0] FC;

`ifdef SIMULATION
wire [23:0] A_full = {A,1'b0};
`endif

wire        BRn, BGACKn, BGn;
wire        ASn, UDSn, LDSn, BUSn;
wire        ok_dly;
wire [15:0] rom_dec;

reg         io_cs, wdog_cs, tbank_cs;

assign UDSWn = RnW | UDSn;
assign LDSWn = RnW | LDSn;
assign BUSn  = ASn | (LDSn & UDSn);

// No peripheral bus access for now
assign cpu_addr = A[12:1];
// assign BERRn = !(!ASn && BGACKn && !rom_cs && !char_cs && !objram_cs  && !pal_cs
//                               && !io_cs  && !wdog_cs && vram_cs && ram_cs);

wire [ 7:0] active, mcu_din, mcu_dout;
wire        mcu_wr;
wire [15:0] mcu_addr;
wire [ 1:0] mcu_intn;
wire [ 2:0] cpu_ipln;
wire        DTACKn, cpu_vpan;
reg  [ 1:0] act_enc;

always @(*) begin
    case( active[2:0] )
        3'b001: act_enc = 0;
        3'b010: act_enc = 1;
        3'b100: act_enc = 2;
        default: act_enc = 0;
    endcase
    casez( game_id[7:3] )
        5'b001?_?: // 5797
            rom_addr = A[18:1];
        5'b0001_?: // 5358
            if( game_id==8'h10 || game_id==8'h1a ) // 5358 large
                rom_addr = { act_enc, A[16:1] };
            else // 5358 small
                rom_addr = { 1'b0, act_enc, A[15:1] };
        5'b0000_1: // Korean
            rom_addr = {1'b0, A[17:1]};
        default: // 5521 & 5704
            rom_addr = { act_enc[0], A[17:1] }; //  18:0 = 512kB
    endcase
end

always @(posedge clk) begin
    game_passsht <= game_id==GAME_PASSSHT2 || game_id==GAME_PASSSHT3 || game_id==GAME_PASSSHT;
end

wire bus_cs    = pal_cs | char_cs | vram_cs | ram_cs | rom_cs | objram_cs | io_cs;
wire bus_busy  = |{ rom_cs & ~ok_dly, (ram_cs | vram_cs) & ~ram_ok };

jts16b_mapper u_mapper(
    .rst        ( rst            ),
    .clk        ( clk            ),
    .cpu_cen    ( cpu_cen        ),
    .cpu_cenb   ( cpu_cenb       ),
    .vint       ( vint           ),

    .addr       ( A              ),
    .addr_out   (                ),
    .cpu_dout   ( cpu_dout       ),
    .cpu_dswn   ( {UDSWn, LDSWn} ),
    .cpu_dsn    ( {UDSn,  LDSn}  ),
    .bus_cs     ( bus_cs         ),
    .bus_busy   ( bus_busy       ),

    // Bus sharing
    .bus_dout   ( 16'hffff       ),
    .bus_din    (                ),

    // M68000 control
    .cpu_berrn  ( BERRn          ),
    .cpu_brn    ( BRn            ),
    .cpu_bgn    ( BGn            ),
    .cpu_bgackn ( BGACKn         ),
    .cpu_dtackn ( DTACKn         ),
    .cpu_asn    ( ASn            ),
    .cpu_fc     ( FC             ),
    .cpu_ipln   ( cpu_ipln       ),
    .cpu_vpan   ( cpu_vpan       ),
    .cpu_haltn  (                ),
    .cpu_rstn   (                ),

    // Sound CPU
    .sndmap_rd  ( sndmap_rd      ),
    .sndmap_wr  ( sndmap_wr      ),
    .sndmap_din ( sndmap_din     ),
    .sndmap_dout( sndmap_dout    ),
    .sndmap_obf ( sndmap_obf     ),

    // MCU side
    .mcu_dout   ( mcu_dout       ),
    .mcu_din    ( mcu_din        ),
    .mcu_intn   ( mcu_intn       ),
    .mcu_addr   ( mcu_addr       ),
    .mcu_wr     ( mcu_wr         ),

    .active     ( active         ),
    .debug_bus  ( debug_bus      ),
    .st_addr    ( st_addr        ),
    .st_dout    ( st_dout        )
);

`ifndef NOMCU
    reg mcu_rst;

    always @(posedge clk24) begin
        mcu_rst <= rst | ~mcu_en;
    end

    jtframe_8751mcu u_mcu(
        .rst        ( mcu_rst       ),
        .clk        ( clk24         ),
        .cen        ( mcu_cen       ),

        .int0n      ( mcu_intn[0]   ),
        .int1n      ( mcu_intn[1]   ),

        .p0_i       ( mcu_din       ),
        .p1_i       ( 8'hff         ),
        .p2_i       ( 8'hff         ),
        .p3_i       (               ),

        .p0_o       (               ),
        .p1_o       (               ),
        .p2_o       (               ),
        .p3_o       (               ),

        // external memory
        .x_din      ( mcu_din       ),
        .x_dout     ( mcu_dout      ),
        .x_addr     ( mcu_addr      ),
        .x_wr       ( mcu_wr        ),

        // ROM programming
        .clk_rom    ( clk           ),
        .prog_addr  ( prog_addr[11:0] ),
        .prom_din   ( prog_data     ),
        .prom_we    ( mcu_prog_we   )
    );
`else
    assign mcu_wr   = 0;
    assign mcu_dout = 0;
`endif

// System 16B memory map
always @(posedge clk, posedge rst) begin
    if( rst ) begin
            rom_cs    <= 0;
            char_cs   <= 0; // 4 kB
            objram_cs <= 0; // 2 kB
            pal_cs    <= 0; // 4 kB
            io_cs     <= 0;
            wdog_cs   <= 0;

            vram_cs   <= 0; // 32kB
            ram_cs    <= 0;
            tbank_cs  <= 0;
    end else begin
        if( !ASn && BGACKn ) begin
            rom_cs    <= |active[2:0] && RnW;
            char_cs   <= active[REG_VRAM] && A[16];

            objram_cs <= active[REG_ORAM];
            pal_cs    <= active[REG_PAL];
            io_cs     <= active[REG_IO];
            tbank_cs  <= active[2] && !RnW; // PCB 171-5521/5704

            // jtframe_ramrq requires cs to toggle to
            // process a new request. BUSn will toggle for
            // read-modify-writes
            vram_cs <= !BUSn && active[REG_VRAM] && !A[16];
            ram_cs  <= !BUSn && active[REG_RAM];
        end else begin
            rom_cs    <= 0;
            char_cs   <= 0;
            objram_cs <= 0;
            pal_cs    <= 0;
            io_cs     <= 0;
            wdog_cs   <= 0;
            vram_cs   <= 0;
            ram_cs    <= 0;
            tbank_cs  <= 0;
        end
    end
end

// cabinet input
reg [ 7:0] cab_dout, sort1, sort2, sort3;
reg        last_iocs;

wire       op_n; // low for CPU OP requests
wire [7:0] sort1_bullet, sort2_bullet, sort3_bullet;

assign op_n        = FC[1:0]!=2'b10;
assign snd_irqn    = 1;
assign colscr_en   = 0;
assign rowscr_en   = 0;
assign sort1_bullet = { sort1[3:0], sort1[7:4] };
assign sort2_bullet = { sort2[3:0], sort2[7:4] };
assign sort3_bullet = { sort3[3:0], sort3[7:4] };

function [7:0] sort_joy( input [7:0] joy_in );
    sort_joy = { joy_in[1:0], joy_in[3:2], joy_in[7], joy_in[5:4], joy_in[6] };
endfunction

always @(*) begin
    sort1 = sort_joy( joystick1 );
    sort2 = sort_joy( joystick2 );
    sort3 = sort_joy( joystick3 );
end

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        tile_bank <= 0;
    end else begin
        if( tbank_cs && !LDSWn )
            if( A[1] )
                tile_bank[5:3] <= cpu_dout[2:0];
            else
                tile_bank[2:0] <= cpu_dout[2:0];
    end
end

wire [8:0] joyana_sum = {joyana1[15], joyana1[15:8]} + {joyana2[15], joyana2[15:8]};
reg  [7:0] ana_in;

function [7:0] pass_joy( input [7:0] joy_in );
    pass_joy = { joy_in[7:4], joy_in[1:0], joy_in[3:2] };
endfunction

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        cab_dout  <= 8'hff;
        flip      <= 0;
        video_en  <= 1;
    end else  begin
        last_iocs <= io_cs;
        cab_dout  <= 8'hff;
        if(io_cs) case( A[13:12] )
            0: if( !LDSWn ) begin
                flip     <= cpu_dout[6];
                video_en <= cpu_dout[5];
            end
            1:
                case( A[2:1] )
                    0: begin
                        cab_dout <= { 2'b11, start_button[1:0], service, dip_test, coin_input[1:0] };
                        if( game_id == GAME_BULLET ) begin
                            cab_dout[7] <= coin_input[2];
                            cab_dout[6] <= start_button[2];
                        end
                        if( game_passsht )  begin
                            cab_dout[7:6] <= start_button[3:2];
                        end
                    end
                    1: begin
                        cab_dout <= game_id == GAME_BULLET ? sort1_bullet : sort1;
                    end
                    2: begin
                        if ( game_id == GAME_BULLET ) cab_dout <= sort3_bullet;
                    end
                    3: begin
                        cab_dout <= game_id == GAME_BULLET ? sort2_bullet : sort2;
                    end
                endcase
            2:
                cab_dout <= { A[1] ? dipsw_a : dipsw_b };
            3: begin // custom inputs
                case( game_id )
                    1: begin // Heavy Champion
                        if( A[9:8]== 2'b10 ) begin
                            if (!LDSWn || !UDSWn) begin
                                case( A[2:1])
                                    0: ana_in <= joyana_sum[8:1];
                                    1: ana_in <= joyana1[15:8];
                                    2: ana_in <= joyana2[15:8];
                                    3: ana_in <= 8'hff;
                                endcase
                            end else if(!last_iocs) begin // read value
                                ana_in <= ana_in << 1;
                                cab_dout <= { 7'd0, ana_in[7] };
                            end
                        end
                    end
                    8'h13: begin // Passing Shot (J)
                        if( A[9:8]== 2'b10 ) begin
                            case( A[2:1] )
                                0: cab_dout <= pass_joy( joystick1 );
                                1: cab_dout <= pass_joy( joystick2 );
                                2: cab_dout <= pass_joy( joystick3 );
                                3: cab_dout <= pass_joy( joystick4 );
                            endcase
                        end
                    end
                    8'h12,8'h19: begin // SDI / Defense
                        if( A[9:8]== 2'b10 ) begin
                            case( A[2:1] )
                                // 1P
                                0: cab_dout <= joyana1[15:8];
                                1: cab_dout <= joyana2[15:8];
                                // 2P
                                2: cab_dout <= joyana3[15:8];
                                3: cab_dout <= joyana4[15:8];
                            endcase
                        end
                    end
                endcase
            end
        endcase
    end
end

// Data bus input
reg  [15:0] cpu_din;

always @(posedge clk) begin
    if(rst) begin
        cpu_din <= 16'hffff;
    end else begin
        cpu_din <= (ram_cs | vram_cs ) ? ram_data  : (
                    rom_cs             ? rom_dec   : (
                    char_cs            ? char_dout : (
                    pal_cs             ? pal_dout  : (
                    objram_cs          ? obj_dout  : (
                    io_cs              ? { 8'hff, cab_dout } :
                                       cpu_din ))))); // no change for unmapped memory
    end
end

`ifdef FD1094
    jts16_fd1094 u_dec(
        .rst        ( rst       ),
        .clk        ( clk       ),

        // Configuration
        .prog_addr  ( prog_addr ),
        .fd1094_we  ( key_we    ),
        .prog_data  ( prog_data ),

        // Operation
        .dec_en     ( dec_en    ),
        .FC         ( FC        ),
        .ASn        ( ASn       ),

        .addr       ( A         ),
        .enc        ( rom_data  ),
        .dec        ( rom_dec   ),

        .dtackn     ( DTACKn    ),
        .rom_ok     ( rom_ok    ),
        .ok_dly     ( ok_dly    )
    );
`endif
`ifdef FD1089
    jts16_fd1089 u_dec(
        .rst        ( rst       ),
        .clk        ( clk       ),

        // Configuration
        .prog_addr  ( prog_addr ),
        .key_we     ( key_we    ),
        .fd1089_we  ( fd1089_we ),
        .prog_data  ( prog_data ),

        // Operation
        .dec_type   ( dec_type  ), // 0=a, 1=b
        .dec_en     ( dec_en    ),
        .rom_ok     ( rom_ok    ),
        .ok_dly     ( ok_dly    ),

        .op_n       ( op_n      ),     // OP (0) or data (1)
        .addr       ( A         ),
        .enc        ( rom_data  ),
        .dec        ( rom_dec   )
    );
`endif
`ifdef MC8123
    // No main CPU encoding when sound CPU is
    assign rom_dec = rom_data;
    assign ok_dly  = rom_ok;
`endif

jtframe_m68k u_cpu(
    .clk        ( clk         ),
    .rst        ( rst         ),
    .cpu_cen    ( cpu_cen     ),
    .cpu_cenb   ( cpu_cenb    ),

    // Buses
    .eab        ( A           ),
    .iEdb       ( cpu_din     ),
    .oEdb       ( cpu_dout    ),


    .eRWn       ( RnW         ),
    .LDSn       ( LDSn        ),
    .UDSn       ( UDSn        ),
    .ASn        ( ASn         ),
    .VPAn       ( cpu_vpan    ),
    .FC         ( FC          ),

    .BERRn      ( BERRn       ),
    // Bus arbitrion
    .HALTn      ( dip_pause   ),
    .BRn        ( BRn         ),
    .BGACKn     ( BGACKn      ),
    .BGn        ( BGn         ),

    .DTACKn     ( DTACKn      ),
    .IPLn       ( cpu_ipln    ) // VBLANK
);

// Debug
`ifdef MISTER
`ifndef NOSHADOW
jts16_shadow #(.VRAMW(15)) u_shadow(
    .clk        ( clk       ),
    .clk_rom    ( clk_rom   ),

    // Capture SDRAM bank 0 inputs
    .addr       ( A[15:1]   ),
    .char_cs    ( char_cs   ),    //  4k
    .vram_cs    ( vram_cs   ),    // 64k
    .pal_cs     ( pal_cs    ),    //  4k
    .objram_cs  ( objram_cs ),    //  2k
    .din        ( cpu_dout  ),
    .dswn       ( {UDSWn, LDSWn} ),  // write mask -active low

    .tile_bank  ( tile_bank ),
    // Let data be dumped via NVRAM interface
    .ioctl_addr ( ioctl_addr),
    .ioctl_din  ( ioctl_din )
);
`endif
`endif

endmodule