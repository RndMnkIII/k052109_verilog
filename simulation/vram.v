/********************************************
* VRAM SRAM with data loaded for simulation *
* Author: @RndMnkIII                        *
# Date: 02/07/2021.                         *
********************************************/
`default_nettype none
`timescale 1ns/1ps

//VRAM for address space 0x0-0x1FFF o Low VRAM
module VRAM_G23(
    input [12:0] ADDR, //8Kx8bit
    input CEn,
    input OEn,
    input WEn,
    inout [7:0] DATA);

    localparam ADDR_WIDTH = 13; //8Kx8bit

    reg [7:0] mem[0:(2**ADDR_WIDTH)-1]; //8Kx8bit
    reg [7:0] data_out;
    
    initial begin
        $readmemh("ALIENS_ST1_VRAM_LOW.hex", mem);
    end

    always @*
    begin: mem_write
        if (!CEn && !WEn) begin
          mem[ADDR] = DATA;
        end
    end

    always @*
    begin
        if (!CEn && WEn && !OEn) begin
          data_out = mem[ADDR];
        end
    end

    //Address Access Time tAA max. 100ns
    assign #100.00 DATA = ((!CEn) && WEn && (!OEn)) ? data_out : {8{1'bz}};
endmodule

//VRAM for address space 0x2000-0x3FFF o High VRAM
module VRAM_I23(
    input [12:0] ADDR, //8Kx8bit
    input CEn,
    input OEn,
    input WEn,
    inout [7:0] DATA);

    localparam ADDR_WIDTH = 13; //8Kx8bit

    reg [7:0] mem[0:(2**ADDR_WIDTH)-1]; //8Kx8bit
    reg [7:0] data_out;
    
    initial begin
        $readmemh("ALIENS_ST1_VRAM_HIGH.hex", mem);
    end

    always @*
    begin: mem_write
        if (!CEn && !WEn) begin
          mem[ADDR] = DATA;
        end
    end

    always @*
    begin
        if (!CEn && WEn && !OEn) begin
          data_out = mem[ADDR];
        end
    end

    //Address Access Time tAA max. 100ns
    assign #100.00 DATA = ((!CEn) && WEn && (!OEn)) ? data_out : {8{1'bz}};
endmodule
