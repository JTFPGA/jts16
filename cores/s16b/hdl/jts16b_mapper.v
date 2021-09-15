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

// This module represents the SEGA 315-5195
//
//  Region 0 - Program ROM
//  Region 3 - 68000 work RAM
//  Region 4 - Text/tile RAM
//  Region 5 - Object RAM
//  Region 6 - Color RAM
//  Region 7 - I/O area

// Quick count from die photo by Furrtek
// 11 x 4-bit counters -> what for?
// 36 x 4-bit latches

// base address = 8x2 x 4-bit = 16 x 4-bit
// control      =                8 x 4-bit

// write address = 3x8 = 6 x 4 -> 5 x 4 ?
// read  address = 3x8 = 6 x 4 -> 5 x 4 ?

// DTACK cycles
// Programmed with bits [3:2] of size registers
// D[3:2] | DTACK (# cycles)
// -------|--------
//  11    | use EDACK pin
//  10    | 3
//  01    | 2
//  00    | 1


module jts16b_mapper(
    input             rst,
    input             clk,
    input             pxl_cen,
    output            cpu_cen,
    output            cpu_cenb,
    output reg        cpu_rst,
    input             bus_cs,
    input             bus_busy,
    input             vint,

    // M68000 interface
    input      [23:1] addr,
    input      [15:0] cpu_dout,
    input      [ 1:0] cpu_dsn,
    output     [ 1:0] bus_dsn,
    output            bus_asn,
    output     [ 2:0] cpu_ipln,
    output            cpu_haltn,
    output            cpu_vpan,

    // Bus sharing
    output            cpu_berrn,
    output            cpu_brn,
    input             cpu_bgn,
    output            cpu_bgackn,
    output            cpu_dtackn,
    input             cpu_asn,
    input      [ 2:0] cpu_fc,
    input             cpu_rnw,
    output            bus_rnw,

    // Z80 interface
    input             sndmap_rd,
    input             sndmap_wr,
    input      [ 7:0] sndmap_din,
    output     [ 7:0] sndmap_dout,
    output reg        sndmap_pbf, // pbf signal == buffer full ?

    // MCU side
    input      [ 7:0] mcu_dout,
    output reg [ 7:0] mcu_din,
    input      [15:0] mcu_addr,
    input             mcu_acc,
    input             mcu_wr,
    output     [ 1:0] mcu_intn,

    // Bus interface
    output     [23:1] addr_out,
    input      [15:0] bus_dout,
    output     [15:0] bus_din,
    output reg [ 7:0] active,

    // status dump
    input      [ 7:0] debug_bus,
    input      [ 7:0] st_addr,
    output reg [ 7:0] st_dout
);

reg  [ 1:0] dtack_cyc;    // number of DTACK cycles
reg  [ 7:0] mmr[0:31];
wire        none = active==0;
wire        bus_rq;
wire        mcu_cen;
reg         cpu_sel;
reg         irqn; // VBLANK
reg         rdmem, wrmem;
reg         mcu_vintn, mcu_snd_intn;

wire [23:1] rdaddr, wraddr;
wire [15:0] wrdata;
wire [ 1:0] cpu_dswn;
wire        bus_mcu;    // the MCU controls the bus

assign mcu_intn = { mcu_snd_intn, mcu_vintn };
assign wraddr   = { mmr[10][6:0],mmr[11],mmr[12] };
assign rdaddr   = { mmr[ 7][6:0],mmr[ 8],mmr[ 9] };
assign wrdata   = { mmr[0], mmr[1] };
assign bus_rq   = rdmem | wrmem;
assign bus_rnw  = ~bus_mcu ? cpu_rnw : ~wrmem;
assign bus_dsn  = ~bus_mcu ? cpu_dsn : 2'b00;
assign cpu_dswn = cpu_dsn & {2{cpu_rnw}};
assign bus_asn  = ~bus_mcu ? cpu_asn : ~bus_rq;
assign bus_mcu  = bus_rq & (~cpu_bgackn | cpu_rst | ~cpu_haltn);

`ifdef SIMULATION
wire [7:0] base0 = mmr[ {1'b1, 3'd0, 1'b1 }];
wire [7:0] base1 = mmr[ {1'b1, 3'd1, 1'b1 }];
wire [7:0] base2 = mmr[ {1'b1, 3'd2, 1'b1 }];
wire [7:0] base3 = mmr[ {1'b1, 3'd3, 1'b1 }];
wire [7:0] base4 = mmr[ {1'b1, 3'd4, 1'b1 }];
wire [7:0] base5 = mmr[ {1'b1, 3'd5, 1'b1 }];
wire [7:0] base6 = mmr[ {1'b1, 3'd6, 1'b1 }];
wire [7:0] base7 = mmr[ {1'b1, 3'd7, 1'b1 }];

wire [1:0] size0, dtack0,
           size1, dtack1,
           size2, dtack2,
           size3, dtack3,
           size4, dtack4,
           size5, dtack5,
           size6, dtack6,
           size7, dtack7;

assign {dtack0, size0 } = mmr[ {1'b1, 3'd0, 1'b0 }];
assign {dtack1, size1 } = mmr[ {1'b1, 3'd1, 1'b0 }];
assign {dtack2, size2 } = mmr[ {1'b1, 3'd2, 1'b0 }];
assign {dtack3, size3 } = mmr[ {1'b1, 3'd3, 1'b0 }];
assign {dtack4, size4 } = mmr[ {1'b1, 3'd4, 1'b0 }];
assign {dtack5, size5 } = mmr[ {1'b1, 3'd5, 1'b0 }];
assign {dtack6, size6 } = mmr[ {1'b1, 3'd6, 1'b0 }];
assign {dtack7, size7 } = mmr[ {1'b1, 3'd7, 1'b0 }];
`endif

assign addr_out  = bus_mcu ? (rdmem ? rdaddr : wraddr ) : addr;
assign bus_din   = bus_mcu ? wrdata : cpu_dout;

assign cpu_haltn = ~mmr[2][1];
assign cpu_berrn = 1;
assign sndmap_dout = mmr[3];

reg  asnl;

always @(posedge clk) if( cpu_cen ) begin
    asnl <= cpu_asn;
end

reg rst_aux;

always @(negedge clk) begin
    { cpu_rst, rst_aux } <= { rst_aux, mmr[2][0] | rst };
end

wire [15:0] mcu_addr_s;
wire        mcu_wr_s, mcu_acc_s, mcu_rd_s;

assign mcu_rd_s = mcu_acc_s & ~mcu_wr_s;

jtframe_sync #(.W(2+16)) u_sync(
    .clk    (   clk                                 ),
    .raw    ( { mcu_acc,   mcu_wr,   mcu_addr    }  ),
    .sync   ( { mcu_acc_s, mcu_wr_s, mcu_addr_s  }  )
);

// Interface with sound CPU
reg [7:0] snd_latch;

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        snd_latch <= 0;
        mcu_snd_intn <= 1;
    end else begin
        if(sndmap_wr) begin
            snd_latch <= sndmap_dout;
            mcu_snd_intn <= 0;
        end
        if( mcu_rd_s && mcu_addr[1:0]==2'b11 ) begin
            mcu_snd_intn <= 1;
        end
    end
end

// Data to MCU
always @(posedge clk) begin
    case( mcu_addr_s[1:0] )
        0: mcu_din <= mmr[0];
        1: mcu_din <= mmr[1];
        2: mcu_din <= {
            1'b0,
            bus_rq,
            2'b00,
            ~&cpu_ipln, // not sure about this one
            cpu_berrn,
            cpu_haltn,
            ~cpu_rst }; // see schematics page 10
        3: mcu_din <= snd_latch;
    endcase
end

`ifdef SIMULATION
reg mcu_rd_l;

always @(posedge clk) begin
    mcu_rd_l <= mcu_rd_s;
    if( ( mcu_addr_s==0 || mcu_addr_s==1 ) && mcu_rd_s && !mcu_rd_l ) begin
        $display("MCU reads %X from address %X",wrdata, rdaddr);
    end
end
`endif


function check(input [2:0] region );
    case( mmr[ {1'b1, region[2:0], 1'b0 } ][1:0] )
        0: check = addr_out[23:16] == mmr[ {1'b1, region[2:0], 1'b1 } ];      //   64 kB
        1: check = addr_out[23:17] == mmr[ {1'b1, region[2:0], 1'b1 } ][7:1]; //  128 kB
        2: check = addr_out[23:19] == mmr[ {1'b1, region[2:0], 1'b1 } ][7:3]; //  512 kB
        3: check = addr_out[23:21] == mmr[ {1'b1, region[2:0], 1'b1 } ][7:5]; // 2048 kB
    endcase
endfunction

always @(addr_out,cpu_fc,mmr) begin
    active[0] = check(0);
    active[1] = check(1) & ~active[0];
    active[2] = check(2) & ~active[1:0];
    active[3] = check(3) & ~active[2:0];
    active[4] = check(4) & ~active[3:0];
    active[5] = check(5) & ~active[4:0];
    active[6] = check(6) & ~active[5:0];
    active[7] = check(7) & ~active[6:0];
    if( &cpu_fc ) active = 0; // irq ack or end of bus cycle
    case( active )
        8'h01: dtack_cyc = mmr[ {1'b1,3'd0,1'b0}][3:2];
        8'h02: dtack_cyc = mmr[ {1'b1,3'd1,1'b0}][3:2];
        8'h04: dtack_cyc = mmr[ {1'b1,3'd2,1'b0}][3:2];
        8'h08: dtack_cyc = mmr[ {1'b1,3'd3,1'b0}][3:2];
        8'h10: dtack_cyc = mmr[ {1'b1,3'd4,1'b0}][3:2];
        8'h20: dtack_cyc = mmr[ {1'b1,3'd5,1'b0}][3:2];
        8'h40: dtack_cyc = mmr[ {1'b1,3'd6,1'b0}][3:2];
        8'h80: dtack_cyc = mmr[ {1'b1,3'd7,1'b0}][3:2];
        default: dtack_cyc = 0;
    endcase
end

// DTACK generation
wire dtackn1;
reg  dtackn2, dtackn3;
wire BUSn = cpu_asn | (&cpu_dsn);
wire [15:0] fave, fworst;

jtframe_68kdtack #(.W(8),.RECOVERY(1),.MFREQ(50_349)) u_dtack(
    .rst        ( rst       ),
    .clk        ( clk       ),
    .cpu_cen    ( cpu_cen   ),
    .cpu_cenb   ( cpu_cenb  ),
    .bus_cs     ( bus_cs    ),
    .bus_busy   ( bus_busy  ),
    .bus_legit  ( 1'b0      ),
    .ASn        ( cpu_asn   ),  // BUSn = ASn | (LDSn & UDSn)
    .DSn        ( cpu_dsn   ),
    .num        ( 8'd29     ),  // numerator
    .den        ( 8'd146    ),  // denominator
    .DTACKn     ( dtackn1   ),
    .fave       ( fave      ),
    .fworst     ( fworst    ),
    .frst       ( debug_bus[4] )
);

// sets the number of delay clock cycles for DTACKn depending on the
// mapper configuration
assign cpu_dtackn = dtack_cyc==3 ? dtackn3 : (dtack_cyc==2 ? dtackn2 : dtackn1);

always @(posedge clk) begin
    if( cpu_asn ) begin
        dtackn2 <= 1;
        dtackn3 <= 1;
    end else if(cpu_cen) begin
        dtackn2 <= dtackn1;
        dtackn3 <= dtackn2;
    end
end

// select between CPU or MCU access to registers
wire [4:0] asel   = cpu_sel ? addr[5:1] : mcu_addr_s[4:0];
wire [7:0] din    = cpu_sel ? cpu_dout[7:0] : mcu_dout;
wire       wren   = cpu_sel ? (~cpu_asn & ~cpu_dswn[0] & none) : mcu_wr_s;
wire       inta_n = ~&{ cpu_fc, ~cpu_asn }; // interrupt ack.
reg  [1:0] bus_wait;
reg        wren_l, bus_busy_l;

always @(posedge clk, posedge rst ) begin
    if( rst ) begin
        mmr[0] <= 0; mmr[10] <= 0; mmr[20] <= 0; mmr[30] <= 0;
        mmr[1] <= 0; mmr[11] <= 0; mmr[21] <= 0; mmr[31] <= 0;
        mmr[2] <= 0; mmr[12] <= 0; mmr[22] <= 0;
        mmr[3] <= 0; mmr[13] <= 0; mmr[23] <= 0;
        mmr[4] <= 7; mmr[14] <= 0; mmr[24] <= 0;
        mmr[5] <= 0; mmr[15] <= 0; mmr[25] <= 0;
        mmr[6] <= 0; mmr[16] <= 0; mmr[26] <= 0;
        mmr[7] <= 0; mmr[17] <= 0; mmr[27] <= 0;
        mmr[8] <= 0; mmr[18] <= 0; mmr[28] <= 0;
        mmr[9] <= 0; mmr[19] <= 0; mmr[29] <= 0;
        sndmap_pbf <= 0;
        cpu_sel    <= 1;
        wrmem      <= 0;
        rdmem      <= 0;
        bus_wait   <= 0;
        wren_l     <= 0;
        bus_busy_l <= 0;
    end else begin
        wren_l <= wren;
        bus_busy_l <= bus_busy;
        if( bus_wait!=0 && bus_mcu ) bus_wait <= bus_wait-1'd1;
        if( !bus_wait && !bus_busy && !bus_busy_l ) begin
            wrmem <= 0;
            rdmem <= 0;
            if( rdmem ) {mmr[0], mmr[1]} <= bus_dout;
        end
        if( mcu_wr_s ) cpu_sel <= 0; // once cleared, it stays like that until reset
        if( wren && !wren_l ) begin
            mmr[ asel ] <= din;
            if( asel == 3 )
                sndmap_pbf <= 1;
            if( asel==5 ) begin
                wrmem <= din[1:0]==2'b01;
                rdmem <= din[1:0]==2'b10;
                if( din[1]^din[0] ) bus_wait <= 2'b11;
            end
        end
        if( sndmap_rd )
            sndmap_pbf <= 0;
        if( !inta_n )
            mmr[4][2:0] <= 3'b111;
    end
end

// interrupt generation
reg        last_vint;

assign cpu_vpan = inta_n;
assign cpu_ipln = cpu_sel ? { irqn, 2'b11 } : mmr[4][2:0];

reg [7:0] mcu_cnt;

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        irqn <= 1;
        mcu_vintn <= 1;
    end else begin
        last_vint <= vint;

        if( mcu_cnt!=0 && pxl_cen ) mcu_cnt   <= mcu_cnt-1'd1;
        if( mcu_cnt==0 ) mcu_vintn <= 1;

        if( !inta_n ) begin
            irqn <= 1;
        end else if( vint && !last_vint ) begin
            irqn <= 0;
            mcu_vintn <= 0;
            mcu_cnt  <= ~7'd0;
        end
    end
end

jtframe_68kdma u_dma(
    .rst        ( rst       ),
    .clk        ( clk       ),
    .cen        ( cpu_cen   ),
    .cpu_BRn    ( cpu_brn   ),
    .cpu_BGACKn ( cpu_bgackn),
    .cpu_BGn    ( cpu_bgn   ),
    .cpu_ASn    ( cpu_asn   ),
    .cpu_DTACKn ( cpu_dtackn),
    .dev_br     ( bus_rq    )      // high to signal a bus request from a device
);

// Debug
always @(posedge clk) begin
    // 0-7 base registers
    // 8-F size registers
    // 10-11, average frequency
    if( st_addr[4] )
        case( st_addr[1:0] )
            0: st_dout <= fave[7:0];
            1: st_dout <= fave[15:8];
            2: st_dout <= fworst[7:0];
            3: st_dout <= fworst[15:8];
        endcase
    else
        st_dout <= mmr[ {1'b1, st_addr[2:0], st_addr[3]} ];
end

endmodule