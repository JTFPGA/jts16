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
    Date: 30-6-2021 */

module jts16_shadow #(parameter VRAMW=14) (
    input             clk,
    input             clk_rom,

    // Capture SDRAM bank 0 inputs
    input      [15:1] addr,
    input             char_cs,    //  4k
    input             vram_cs,    // 32k
    input             pal_cs,     //  4k
    input             objram_cs,  //  2k
    input      [15:0] din,
    input      [ 1:0] dswn,  // write mask -active low

    input      [ 5:0] tile_bank,
    output reg        dump_pal,
    output reg        dump_obj,
    input      [15:0] dump_dout,

    // Let data be dumped via NVRAM interface
    input             ioctl_ram,
    input      [16:0] ioctl_addr,
    output     [ 7:0] ioctl_din
);

`ifndef MISTER
    assign ioctl_din = 0;
`else

wire [15:0] vram_dout, char_dout;
reg  [15:0] dout, dout_latch;
wire [ 7:0] dump_byte;

wire [ 1:0] vram_we   = vram_cs   ? ~dswn : 2'b0;
wire [ 1:0] char_we   = char_cs   ? ~dswn : 2'b0;
wire [ 1:0] pal_we    = pal_cs    ? ~dswn : 2'b0;
wire [ 1:0] objram_we = objram_cs ? ~dswn : 2'b0;
assign ioctl_din = ~ioctl_addr[0] ? dout_latch[15:8] : dout_latch[7:0];
assign dump_byte = ioctl_addr[1] ? dump_dout[7:0] : dump_dout[15:0];

always @(*) begin
    dump_pal = 0;
    dump_obj = 0;
    if( VRAMW==14 ) begin
        casez( ioctl_addr[15:11] )
            5'b0???_?: dout = vram_dout;
            5'b1000_?: begin
                dump_obj = 1;
                dout = char_dout;
            end
            5'b1001_?: begin
                dump_pal = 1;
                dout = dump_byte;
            end
            5'b1010_0: dout = dump_byte;
            default:   dout = 16'hffff;
        endcase
    end else begin
        dout = vram_dout;
        if( ioctl_addr[16] ) begin
            casez( ioctl_addr[15:12] )
                4'b0000: dout = char_dout;    // 4kB
                4'b0001: begin
                    dump_pal = 1;
                    dout = dump_byte;     // 4kB
                end
                4'b0010: begin
                    dump_obj = ~ioctl_addr[11];
                    dout = ioctl_addr[11] ? {2'd0, tile_bank} : dump_byte;  // 2kB
                end
                default: dout = 16'hffff;
            endcase
        end
    end
    if(!ioctl_ram) begin
        dump_pal = 0;
        dump_obj = 0;
    end
end

always @(posedge clk_rom) begin
    if( ioctl_addr[0] )
        dout_latch <= dout;
end

jtframe_dual_ram16 #(.aw(VRAMW)) u_vram(
    .clk0       ( clk       ),
    .clk1       ( clk_rom   ),
    // CPU writes
    .data0      ( din       ),
    .addr0      ( addr      ),
    .we0        ( vram_we   ),
    .q0         (           ),
    // hps_io reads
    .data1      (           ),
    .addr1      ( ioctl_addr[VRAMW:1] ),
    .we1        ( 2'b0      ),
    .q1         ( vram_dout )
);

jtframe_dual_ram16 #(.aw(11)) u_char(
    .clk0       ( clk       ),
    .clk1       ( clk_rom   ),
    // CPU writes
    .data0      ( din       ),
    .addr0      ( addr[11:1]),
    .we0        ( char_we   ),
    .q0         (           ),
    // hps_io reads
    .data1      (           ),
    .addr1      ( ioctl_addr[11:1] ),
    .we1        ( 2'b0      ),
    .q1         ( char_dout )
);


`endif
endmodule