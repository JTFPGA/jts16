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
    Date: 10-3-2021 */

module jts16_mmr(
    input              rst,
    input              clk,

    input              flip,
    // CPU interface
    input              char_cs,
    input      [11:1]  cpu_addr,
    input      [15:0]  cpu_dout,
    input      [ 1:0]  dsn,

    // Video registers
    output reg [15:0]  scr1_pages,
    output reg [15:0]  scr2_pages,

    output reg [15:0]  scr1_hpos,
    output reg [15:0]  scr1_vpos,

    output reg [15:0]  scr2_hpos,
    output reg [15:0]  scr2_vpos,

    // status dump
    input      [ 7:0]  st_addr,
    output reg [ 7:0]  st_dout
);

reg [15:0]  scr1_pages_flip, scr2_pages_flip,
            scr1_pages_nofl, scr2_pages_nofl;

function [15:0] bytemux( input [15:0] old );
    bytemux = { dsn[1] ? old[15:8] : cpu_dout[15:8], dsn[0] ? old[7:0] : cpu_dout[7:0] };
endfunction

always @(posedge clk) begin
    scr1_pages <= flip ? scr1_pages_flip : scr1_pages_nofl;
    scr2_pages <= flip ? scr2_pages_flip : scr2_pages_nofl;
end

`ifdef SIMULATION
    reg [15:0] sim_cfg[0:511];

    initial begin
        $readmemh( "mmr.hex", sim_cfg );

        scr1_pages_flip = sim_cfg[9'h08e];
        scr1_pages_nofl = sim_cfg[9'h09e];
        scr2_pages_flip = sim_cfg[9'h08c];
        scr2_pages_nofl = sim_cfg[9'h09c];
        scr1_vpos       = sim_cfg[9'h124];
        scr2_vpos       = sim_cfg[9'h126];
        scr1_hpos       = sim_cfg[9'h1f8];
        scr2_hpos       = sim_cfg[9'h1fa];
    end
`endif

always @(posedge clk) begin
    if( char_cs && cpu_addr[11:9]==3'b111 && dsn!=2'b11) begin
        case( {cpu_addr[8:1], 1'b0} )
            9'h08e: scr1_pages_flip <= bytemux( scr1_pages_flip );
            9'h09e: scr1_pages_nofl <= bytemux( scr1_pages_nofl );
            9'h08c: scr2_pages_flip <= bytemux( scr2_pages_flip );
            9'h09c: scr2_pages_nofl <= bytemux( scr2_pages_nofl );
            9'h124: scr1_vpos       <= bytemux( scr1_vpos       );
            9'h126: scr2_vpos       <= bytemux( scr2_vpos       );
            9'h1f8: scr1_hpos       <= bytemux( scr1_hpos       );
            9'h1fa: scr2_hpos       <= bytemux( scr2_hpos       );
            default:;
        endcase
    end
end

`ifdef JTFRAME_CHEAT
always @(posedge clk) begin
    case( st_addr )
        0:  st_dout <= scr1_pages_nofl[ 7:0];
        1:  st_dout <= scr1_pages_nofl[15:8];
        2:  st_dout <= scr2_pages_nofl[ 7:0];
        3:  st_dout <= scr2_pages_nofl[15:8];
        4:  st_dout <= scr1_vpos[ 7:0];
        5:  st_dout <= scr1_vpos[15:8];
        6:  st_dout <= scr2_vpos[ 7:0];
        7:  st_dout <= scr2_vpos[15:8];
        8:  st_dout <= scr1_hpos[ 7:0];
        9:  st_dout <= scr1_hpos[15:8];
        10: st_dout <= scr2_hpos[ 7:0];
        11: st_dout <= scr2_hpos[15:8];
        default: st_dout <= 0;
    endcase
end
`endif

endmodule