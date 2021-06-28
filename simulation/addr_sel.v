/****************************************************************
 * Support modules for address selection.                       *
 * @Furrtek schematics on 052109 die:                           *
 * https://github.com/furrtek/VGChips/tree/master/Konami/052109 *
 * Author: @RndMnkIII                                           *
 * Repository: https://github.com/RndMnkIII/k052109_verilog     *
 * Version: 1.0 28/06/2021                                      *
 ***************************************************************/
`default_nettype none
`timescale 1ns/1ps

 module ADRR_SEL ( input A1,
                        input A2,
                        input B1,
                        input B2,
                        input C,
                 input SELA,
                 input SELAn,
                 input SELB,
                 input SELBn,
                 input SELC,
                 input SELCn,
                 output RA);
    wire SELAB_Xn;
    T5A_DLY selab (.A1(A1), .A2(A2), .B1(B1), .B2(B2), .S1n(SELA), .S2(SELAn), .S3n(SELAn), .S4(SELA), .S5n(SELB), .S6(SELBn), .Xn(SELAB_Xn));

    wire SELAB; //Logic Cell V1N
    assign #0.55 SELAB = ~SELAB_Xn;

    wire SELABC_Xn;
    D24_DLY SELABC (.A1(C), .A2(SELC), .B1(SELAB), .B2(SELCn), .X(SELABC_Xn)); 

    wire SELABC; //Logic Cell V2B
    assign #0.64 SELABC = ~SELABC_Xn;

    assign RA = SELABC;
endmodule

 module ADRR_SEL2 ( input A,
                        input B,
                 input SELC,
                 input SELCn,
                 output VRAM_OE_CS);
    wire SELAB_Xn;
    D24_DLY SELABC (.A1(A), .A2(SELC), .B1(B), .B2(SELCn), .X(SELAB_Xn)); 

    wire SELAB; //Logic Cell V2B
    assign #0.64 SELAB = ~SELAB_Xn;
    
    assign VRAM_OE_CS = SELAB;
endmodule