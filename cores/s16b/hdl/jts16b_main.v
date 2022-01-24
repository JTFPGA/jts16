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
    input              rst24,
    input              clk24,       // required to ease MCU synthesis
    input              pxl_cen,
    input              clk_rom,
    output             cpu_cen,
    input              mcu_cen,
    output             cpu_cenb,
    input  [7:0]       game_id,

    // Video
    input              vint,
    input              LHBL,

    // Video circuitry
    output reg         char_cs,
    output reg         pal_cs,
    output reg         objram_cs,
    input       [15:0] char_dout,
    input       [15:0] pal_dout,
    input       [15:0] obj_dout,
    output             flip,
    output             video_en,
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
    input       [15:0] joyana1b,
    input       [15:0] joyana2,
    input       [15:0] joyana2b,
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
    output             sndmap_pbf, // pbf signal == buffer full ?

    // NVRAM - debug
    input       [16:0] ioctl_addr,
    output      [ 7:0] ioctl_din,

    // status dump
    input       [ 7:0] debug_bus,
    input       [ 7:0] st_addr,
    output      [ 7:0] st_dout
);

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

wire [23:1] A,cpu_A;
wire        BERRn;
wire [ 2:0] FC;

`ifdef SIMULATION
wire [23:0] A_full = {A,1'b0};
`endif

wire        BRn, BGACKn, BGn;
wire        ASn, UDSn, LDSn, BUSn;
wire        ok_dly;
wire [15:0] rom_dec, cpu_dout_raw, mul_dout, cmp_dout, cmp2_dout;

reg         io_cs, mul_cs, cmp_cs, cmp2_cs, wdog_cs, tbank_cs;
wire        cpu_RnW;

assign UDSWn = RnW | UDSn;
assign LDSWn = RnW | LDSn;
assign BUSn  = ASn | (LDSn & UDSn);

// No peripheral bus access for now
assign cpu_addr = A[12:1];
// assign BERRn = !(!ASn && BGACKn && !rom_cs && !char_cs && !objram_cs  && !pal_cs
//                               && !io_cs  && !wdog_cs && vram_cs && ram_cs);

wire [ 7:0] active, mcu_din, mcu_dout, sys_inputs, cab_dout;
wire        mcu_wr, mcu_acc;
wire [15:0] mcu_addr;
wire [ 1:0] mcu_intn;
wire [ 2:0] cpu_ipln;
wire        DTACKn, cpu_vpan;

reg  [ 1:0] act_enc;

wire pcb_5797;
reg  pcb_5358L;

assign pcb_5797 = game_id[5]; // MVP, etc.

always @(posedge clk) begin
    pcb_5358L <= game_id==8'h10 || game_id==8'h15 || game_id==8'h1a;
end

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
            if( pcb_5358L ) // 5358 large
                rom_addr = { act_enc, A[16:1] };
            else // 5358 small
                rom_addr = { 1'b0, act_enc, A[15:1] };
        5'b0000_1: // Korean
            rom_addr = {1'b0, A[17:1]};
        default: // 5521 & 5704
            rom_addr = { act_enc[0], A[17:1] }; //  18:0 = 512kB
    endcase
end

wire bus_cs    = pal_cs | char_cs | vram_cs | ram_cs | rom_cs | objram_cs | io_cs;
wire bus_busy  = |{ rom_cs & ~ok_dly, (ram_cs | vram_cs) & ~ram_ok };
wire cpu_rst, cpu_haltn, cpu_asn;
wire [ 1:0] cpu_dsn;
reg  [15:0] cpu_din;

jts16b_mapper u_mapper(
    .rst        ( rst            ),
    .clk        ( clk            ),
    .pxl_cen    ( pxl_cen        ),
    .cpu_cen    ( cpu_cen        ),
    .cpu_cenb   ( cpu_cenb       ),
    .vint       ( vint           ),

    .addr       ( cpu_A          ),
    .cpu_dout   ( cpu_dout_raw   ),
    .cpu_dsn    ( cpu_dsn        ),
    .bus_dsn    ( {UDSn,  LDSn}  ),
    .bus_cs     ( bus_cs         ),
    .bus_busy   ( bus_busy       ),
    // effective bus signals
    .addr_out   ( A              ),

    // Bus sharing
    .bus_dout   ( cpu_din        ),
    .bus_din    ( cpu_dout       ),
    .cpu_rnw    ( cpu_RnW        ),
    .bus_rnw    ( RnW            ),
    .bus_asn    ( ASn            ),

    // M68000 control
    .cpu_berrn  ( BERRn          ),
    .cpu_brn    ( BRn            ),
    .cpu_bgn    ( BGn            ),
    .cpu_bgackn ( BGACKn         ),
    .cpu_dtackn ( DTACKn         ),
    .cpu_asn    ( cpu_asn        ),
    .cpu_fc     ( FC             ),
    .cpu_ipln   ( cpu_ipln       ),
    .cpu_vpan   ( cpu_vpan       ),
    .cpu_haltn  ( cpu_haltn      ),
    .cpu_rst    ( cpu_rst        ),

    // Sound CPU
    .sndmap_rd  ( sndmap_rd      ),
    .sndmap_wr  ( sndmap_wr      ),
    .sndmap_din ( sndmap_din     ),
    .sndmap_dout( sndmap_dout    ),
    .sndmap_pbf ( sndmap_pbf     ),

    // MCU side
    .mcu_dout   ( mcu_dout       ),
    .mcu_din    ( mcu_din        ),
    .mcu_intn   ( mcu_intn       ),
    .mcu_addr   ( mcu_addr       ),
    .mcu_wr     ( mcu_wr         ),
    .mcu_acc    ( mcu_acc        ),

    .active     ( active         ),
    //.debug_bus  ( debug_bus      ),
    .debug_bus  ( 8'd0           ),
    .st_addr    ( st_addr        ),
    .st_dout    ( st_dout        )
);

`ifndef NOMCU
    reg mcu_rst;
    reg [1:0] mcu_aux;
    reg vintl;

    always @(posedge clk24) vintl <= vint;

    always @(posedge clk24, posedge rst24) begin
        if( rst24 )
            mcu_aux <= 0;
        else if( vint && !vintl )
            mcu_aux <= { mcu_aux[0], 1'b1 };
    end

    always @(negedge clk24, posedge rst24) begin
        if( rst24 )
            mcu_rst <= 1;
        else if(mcu_aux==2'b11)
            mcu_rst <= 0;
    end


    jtframe_8751mcu #(
        .DIVCEN     ( 1             ),
        .SYNC_XDATA ( 1             ),
        .SYNC_P1    ( 1             ),
        .SYNC_INT   ( 1             )
    ) u_mcu(
        .rst        ( mcu_rst       ),
        .clk        ( clk24         ),
        .cen        ( mcu_cen       ),

        .int0n      ( mcu_intn[0]   ),
        .int1n      ( mcu_intn[1]   ),

        .p0_i       ( mcu_din       ),
        .p1_i       ( sys_inputs    ),
        .p2_i       ( 8'hff         ),
        .p3_i       ( 8'hff          ),

        .p0_o       (               ),
        .p1_o       (               ),
        .p2_o       (               ),
        .p3_o       (               ),

        // external memory
        .x_din      ( mcu_din       ),
        .x_dout     ( mcu_dout      ),
        .x_addr     ( mcu_addr      ),
        .x_wr       ( mcu_wr        ),
        .x_acc      ( mcu_acc       ),

        // ROM programming
        .clk_rom    ( clk           ),
        .prog_addr  ( prog_addr[11:0] ),
        .prom_din   ( prog_data     ),
        .prom_we    ( mcu_prog_we   )
    );
`else
    assign mcu_wr   = 0;
    assign mcu_acc  = 0;
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
            mul_cs    <= 0;
            cmp_cs    <= 0;
            cmp2_cs   <= 0;
            wdog_cs   <= 0;

            vram_cs   <= 0; // 32kB
            ram_cs    <= 0;
            tbank_cs  <= 0;
    end else begin
        if( !ASn /*&& BGACKn*/ ) begin
            rom_cs    <= (pcb_5797 ? active[0] : |active[2:0]) && RnW;
            char_cs   <= active[REG_VRAM] && A[16];

            objram_cs <= active[REG_ORAM];
            pal_cs    <= active[REG_PAL];
            io_cs     <= active[REG_IO];
            if( pcb_5797 ) begin
                if( active[1] ) begin
                    case(A[13:12])
                        0: mul_cs <= 1;
                        1: begin
                            cmp_cs <= 1;
                        end
                        2: tbank_cs <= !RnW;
                    endcase
                end
                if( active[2] ) begin
                    cmp2_cs <= 1;
                end
            end else begin
                tbank_cs <= active[2] && !RnW; // PCB 171-5521/5704
            end
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
            mul_cs    <= 0;
            wdog_cs   <= 0;
            vram_cs   <= 0;
            ram_cs    <= 0;
            tbank_cs  <= 0;
        end
    end
end

assign colscr_en   = 0;
assign rowscr_en   = 0;

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

jts16b_mul u_mul(
    .rst    ( rst       ),
    .clk    ( clk       ),
    .A      ( A         ),
    .dsn    ({UDSn,LDSn}),
    .rnw    ( RnW       ),
    .cs     ( mul_cs    ),
    .din    ( cpu_dout  ),
    .dout   ( mul_dout  )
);

jts16b_timer u_timer1(
    .rst    ( rst       ),
    .clk    ( clk       ),
    .A      ( A         ),
    .dsn    ({UDSn,LDSn}),
    .rnw    ( RnW       ),
    .cs     ( cmp_cs    ),
    .din    ( cpu_dout  ),
    .dout   ( cmp_dout  ),
    .snd_irq(           )
);

jts16b_timer u_timer2(
    .rst    ( rst       ),
    .clk    ( clk       ),
    .A      ( A         ),
    .dsn    ({UDSn,LDSn}),
    .rnw    ( RnW       ),
    .cs     ( cmp2_cs   ),
    .din    ( cpu_dout  ),
    .dout   ( cmp2_dout ),
    .snd_irq(           )
);

jts16b_cabinet u_cabinet(
    .rst            ( rst           ),
    .clk            ( clk           ),
    .LHBL           ( LHBL          ),
    .game_id        ( game_id       ),

    // CPU
    .A              ( A             ),
    .cpu_dout       ( cpu_dout      ),
    .LDSWn          ( LDSWn         ),
    .UDSWn          ( UDSWn         ),
    .LDSn           ( LDSn          ),
    .UDSn           ( UDSn          ),
    .io_cs          ( io_cs         ),

    // DIP switches
    .dip_test       ( dip_test      ),
    .dipsw_a        ( dipsw_a       ),
    .dipsw_b        ( dipsw_b       ),

    // cabinet I/O
    .joystick1      ( joystick1     ),
    .joystick2      ( joystick2     ),
    .joystick3      ( joystick3     ),
    .joystick4      ( joystick4     ),
    .joyana1        ( joyana1       ),
    .joyana1b       ( joyana1b      ),
    .joyana2        ( joyana2       ),
    .joyana2b       ( joyana2b      ),
    .joyana3        ( joyana3       ),
    .joyana4        ( joyana4       ),
    .start_button   ( start_button  ),
    .coin_input     ( coin_input    ),
    .service        ( service       ),

    .sys_inputs     ( sys_inputs    ),
    .cab_dout       ( cab_dout      ),
    .flip           ( flip          ),
    .video_en       ( video_en      )
);


// Data bus input
always @(posedge clk) begin
    if(rst) begin
        cpu_din <= 0;
    end else begin
        cpu_din <= (ram_cs | vram_cs ) ? ram_data  :
                    rom_cs             ? rom_dec   :
                    char_cs            ? char_dout :
                    pal_cs             ? pal_dout  :
                    objram_cs          ? obj_dout  :
                    io_cs              ? { 8'hff, cab_dout } :
                    mul_cs             ? mul_dout  :
                    cmp_cs             ? cmp_dout  :
                    cmp2_cs            ? cmp2_dout :
                                         cpu_din; // no change for unmapped memory
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
    wire op_n = FC[1:0]!=2'b10; // low for CPU OP requests

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
`ifndef FD1094
`ifndef FD1089
    // No main CPU encoding when sound CPU is
    assign rom_dec = rom_data;
    assign ok_dly  = rom_ok;
`endif
`endif

jtframe_m68k u_cpu(
    .clk        ( clk         ),
    .rst        ( cpu_rst     ),
    .cpu_cen    ( cpu_cen     ),
    .cpu_cenb   ( cpu_cenb    ),

    // Buses
    .eab        ( cpu_A       ),
    .iEdb       ( cpu_din     ),
    .oEdb       ( cpu_dout_raw),


    .eRWn       ( cpu_RnW     ),
    .LDSn       ( cpu_dsn[0]  ),
    .UDSn       ( cpu_dsn[1]  ),
    .ASn        ( cpu_asn     ),
    .VPAn       ( cpu_vpan    ),
    .FC         ( FC          ),

    .BERRn      ( BERRn       ),
    // Bus arbitrion
    .HALTn      ( cpu_haltn   ),
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