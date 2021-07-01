/*****************************************************************
 * Verilog simulation module of the k052109 Tile Layer Generator *
 * Based on @Furrtek schematics on 051962 die tracing:           *
 * https://github.com/furrtek/VGChips/tree/master/Konami/052109  *
 * Author: @RndMnkIII                                            *
 * Repository: https://github.com/RndMnkIII/k052109_verilog      *
 * Version: 1.0 28/06/2021                                       *
 ****************************************************************/
/* k052109 FACTS:
 * The k052109 can address a maximum of 24Kbytes of VRAM divided in 3 banks
 * The K052109 can read/write the VRAM in BYTE mode selecting the HIGH or LOW byte to be read by the CPU.
 * The CPU is the responsible to compose each tilemap and to update the tilemaps on each screen update.
 * The K052109 can read the VRAM in 16bit WORD mode when rendering the screen.
*/
`default_nettype none
`timescale 1ns/1ps
//iverilog -g2005-sv -s k052109_DLY k052109.v addr_sel.v fujitsu_AV_UnitCellLibrary_DLY.v

module k052109_DLY (
    input wire M24,
    input wire RES,

    //TIMING, CLOCKING, INTERRUPT SIGNALS
    output wire M12, //main CPU clocking
    output wire PE, PQ, //6809 style 90 degree phase delay clocks
    output wire NMI, IRQ, FIRQ, //6809 style interrupts.

    //CPU bus interface
    output wire RST, //Delayed RES signal
    input wire NRD, //CPU NRD=1 WRITE, NRD=0 READ
    input wire VCS, //CPU VRAMCS
    input wire RMRD, //READ DATA FROM GFX ROMS -> CPU DATA BUS
    input wire CRCS, //SAME AS CPU VRAMCS???
    input wire [15:0] AB, //CPU BUS ADDRESS
    inout wire [7:0] DB, //CPU BUS DATA
    
    //ROM addressing interface  
    output wire [7:0] COL, //COL[5:0] -> GFX ROM ADDR[16:11] Aliens Sch.
    output wire [10:0] VC, //VC[10:0] -> GFX ROM ADDR[10:0] Aliens Sch.
    output wire CAB1, CAB2, //ROMBANK SELECTORS: CAB1 -> GFX ROM ADDR[17] //FOR 256Kx16-bit GFX ROM Aliens Sch.
                           //                   CAB2 -> GFX ROM OEn  //FOR GFX ADDR 0x00000-0x3FFFF Aliens Sch.
                           //                  ~CAB2 -> GFX ROM OEn  //FOR GFX ADDR 0x40000-0x5FFFF Aliens Sch. (Max. 0x7FFFF)

    //VRAM interface
    output wire [12:0] RA, //VRAM ADDRESS
    inout wire [15:0] VD, //VRAM DATA
    output wire [1:0] RCS, //VRAM CS
    output wire [2:0] ROE, //VRAM OE
    output wire [2:0] RWE, //VRAM WE

    //sprite engine interface
    output wire HVOT,

    //k051962 interface 
    output wire BEN, //related to BUS ENABLE in k051962 
    //COL[7:6] <-> k051962
    output wire ZB4H, ZB2H, ZB1H,
    output wire ZA4H, ZA2H, ZA1H,

    //CRAM interface
    output wire WRP, //inhibits CRAM writes if equal to 1

    //MISC. signals
    output wire RDEN, WREN, //???
    input wire TEST, //factory test, connected to GND when not used
    output wire VDE,

    //Simulator DEBUG interface
    output [63:0] DBG);

    //dummy output signals
    assign DBG = {64{1'b0}};
    //*** PAGE 1: VRAM address ***
    //* START Section 1.1. PXH1/PXH2 buffer signals *
    wire N72; //Logic Cell V1N
    assign #0.55 N72 = ~TEST_D8;

    wire N73_X0n;
    wire N73_X1n;
    T2C_DLY n73 (.A1(PXH1), .A2(TEST_D9), .B1(PXH2), .B2(TEST_D10), .S1n(TEST_D8), .S2(N72), .X0n(N73_X0n), .X1n(N73_X1n));

    wire N70; //Logic Cell V2B
    wire N16_QA_BUF;
    assign #0.64 N70 = ~N73_X0n;
    assign N16_QA_BUF = N70;

    wire N68; //Logic Cell V2B
    wire N16_QB_BUF;
    assign #0.64 N68 = ~N73_X1n;
    assign N16_QB_BUF = N68;

    wire N16_QA_BUF2; //Logic Cell K1B
    assign #1.26 N16_QA_BUF2 = N70;

    wire N16_QA_BUF3n; //Logic Cell V2B
    assign #0.64 N16_QA_BUF3n = ~N70;

    wire N16_QA_BUF2n; //Logic Cell V2B
    assign #0.64 N16_QA_BUF2n = ~N70;

    wire N16_QA_BUFn; //Logic Cell V2B
    assign #0.64 N16_QA_BUFn = ~N70;

    wire N16_QB_BUF2; //Logic Cell K1B
    assign #1.26 N16_QB_BUF2 = N68;

    wire N16_QB_BUF3n; //Logic Cell V2B
    assign #0.64 N16_QB_BUF3n = ~N68;

    wire N16_QB_BUF2n; //Logic Cell V2B
    assign #0.64 N16_QB_BUF2n = ~N68;

    wire N16_QB_BUFn; //Logic Cell V2B
    assign #0.64 N16_QB_BUFn = ~N68;
    //* END Section 1.1. PXH1/PXH2 buffer signals *

    //* START Section 1.2. TEST_D13 addresses selector signals *
    /*
    always @ * begin
        case ({AA58,AA38})
            2'bx1: begin
                Y129=ROW[5]; Y78=ROW[6]; Y91=ROW[7]; Y80=1'b1; 
            end     
            2'bx0: begin
                Y129=1'b0; Y78=1'b0; Y91=1'b0; Y80=1'b0; 
            end 
        endcase
    end
    */
    wire Y69_X;
    D24_DLY y69 (.A1(ROW[5]), .A2(AA38), .B1(1'b0), .B2(AA58), .X(Y69_X));
    wire Y129; //Logic Cell V1N
    assign #0.55 Y129 = ~Y69_X;

    wire Y71_X;
    D24_DLY y71 (.A1(ROW[6]), .A2(AA38), .B1(1'b0), .B2(AA58), .X(Y71_X));
    wire Y78; //Logic Cell V1N
    assign #0.55 Y78 = ~Y71_X;

    wire Y73_X;
    D24_DLY y73 (.A1(ROW[7]), .A2(AA38), .B1(1'b0), .B2(AA58), .X(Y73_X));
    wire Y91; //Logic Cell V1N
    assign #0.55 Y91 = ~Y73_X;

    wire Y75_X;
    D24_DLY y75 (.A1(1'b1), .A2(AA38), .B1(1'b0), .B2(AA58), .X(Y75_X));
    wire Y80; //Logic Cell V1N
    assign #0.55 Y80 = ~Y75_X;
    //* END Section 1.2. TEST_D13 addresses selector signals *

    //* START Section 1.3. VRAM address outputs selection: A=CPU B=Rendering C=TEST_D11 *
    wire D50; //Logic Cell V1N
    assign #0.55 D50 = ~TEST_D11;

    wire D47_Xn;
    T2B_DLY d47 (.A(TEST_D12), .B(J79), .S1n(TEST_D11), .S2(D50), .Xn(D47_Xn));
    wire R113; //Logic Cell K2B
    assign #1.83 R113 = D47_Xn;
    wire R117; //Logic Cell V2B
    assign #0.64 R117 = ~D47_Xn;

    ADRR_SEL ra_0 (.A1(SCROLL_RAM_A[0]), .A2(MAP_A[0]), .B1(PXH3F), .B2(MAP_B[0]), .C(AB[0]),  .SELA(N16_QA_BUF), .SELAn(N16_QA_BUFn), .SELB(N16_QB_BUF), .SELBn(N16_QB_BUFn), .SELC(R113), .SELCn(R117), .RA(RA[0]));
    ADRR_SEL ra_1 (.A1(SCROLL_RAM_A[1]), .A2(MAP_A[1]), .B1(PXH4F), .B2(MAP_B[1]), .C(AB[1]),  .SELA(N16_QA_BUF), .SELAn(N16_QA_BUFn), .SELB(N16_QB_BUF), .SELBn(N16_QB_BUFn), .SELC(R113), .SELCn(R117), .RA(RA[1]));
    ADRR_SEL ra_2 (.A1(SCROLL_RAM_A[2]), .A2(MAP_A[2]), .B1(PXH5),  .B2(MAP_B[2]), .C(AB[2]),  .SELA(N16_QA_BUF), .SELAn(N16_QA_BUFn), .SELB(N16_QB_BUF), .SELBn(N16_QB_BUFn), .SELC(R113), .SELCn(R117), .RA(RA[2]));
    ADRR_SEL ra_3 (.A1(SCROLL_RAM_A[3]), .A2(MAP_A[3]), .B1(PXH6),  .B2(MAP_B[3]), .C(AB[3]),  .SELA(N16_QA_BUF), .SELAn(N16_QA_BUFn), .SELB(N16_QB_BUF), .SELBn(N16_QB_BUFn), .SELC(R113), .SELCn(R117), .RA(RA[3]));
    ADRR_SEL ra_4 (.A1(SCROLL_RAM_A[4]), .A2(MAP_A[4]), .B1(PXH7),  .B2(MAP_B[4]), .C(AB[4]),  .SELA(N16_QA_BUF), .SELAn(N16_QA_BUFn), .SELB(N16_QB_BUF), .SELBn(N16_QB_BUFn), .SELC(R113), .SELCn(R117), .RA(RA[4]));
    ADRR_SEL ra_5 (.A1(SCROLL_RAM_A[5]), .A2(MAP_A[5]), .B1(PXH8),  .B2(MAP_B[5]), .C(AB[5]),  .SELA(N16_QA_BUF), .SELAn(N16_QA_BUFn), .SELB(N16_QB_BUF), .SELBn(N16_QB_BUFn), .SELC(R113), .SELCn(R117), .RA(RA[5]));
    ADRR_SEL ra_6 (.A1(Y129),            .A2(MAP_A[6]), .B1(ROW[3]),  .B2(MAP_B[6]), .C(AB[6]),  .SELA(N16_QA_BUF), .SELAn(N16_QA_BUFn), .SELB(N16_QB_BUF), .SELBn(N16_QB_BUFn), .SELC(R113), .SELCn(R117), .RA(RA[6]));
    //----------------BUF2
    ADRR_SEL ra_7 (.A1(Y78),             .A2(MAP_A[7]), .B1(ROW[4]),  .B2(MAP_B[7]), .C(AB[7]),  .SELA(N16_QA_BUF), .SELAn(N16_QA_BUF2n), .SELB(N16_QB_BUF), .SELBn(N16_QB_BUF2n), .SELC(R113), .SELCn(R117), .RA(RA[7]));
    ADRR_SEL ra_8 (.A1(Y91),             .A2(MAP_A[8]), .B1(ROW[5]),  .B2(MAP_B[8]), .C(AB[8]),  .SELA(N16_QA_BUF), .SELAn(N16_QA_BUF2n), .SELB(N16_QB_BUF), .SELBn(N16_QB_BUF2n), .SELC(R113), .SELCn(R117), .RA(RA[8]));
    ADRR_SEL ra_9 (.A1(Y80),             .A2(MAP_A[9]), .B1(ROW[6]),  .B2(MAP_B[9]), .C(AB[9]),  .SELA(N16_QA_BUF), .SELAn(N16_QA_BUF2n), .SELB(N16_QB_BUF), .SELBn(N16_QB_BUF2n), .SELC(R113), .SELCn(R117), .RA(RA[9]));
    ADRR_SEL ra_A (.A1(1'b0),            .A2(MAP_A[10]),.B1(ROW[7]),  .B2(MAP_B[10]),.C(AB[10]), .SELA(N16_QA_BUF), .SELAn(N16_QA_BUF2n), .SELB(N16_QB_BUF), .SELBn(N16_QB_BUF2n), .SELC(R113), .SELCn(R117), .RA(RA[10]));
    ADRR_SEL ra_B (.A1(1'b1),            .A2(1'b1),    .B1(1'b0),  .B2(1'b0),    .C(AB[11]), .SELA(N16_QA_BUF), .SELAn(N16_QA_BUF2n), .SELB(N16_QB_BUF), .SELBn(N16_QB_BUF2n), .SELC(R113), .SELCn(R117), .RA(RA[11]));
    ADRR_SEL ra_C (.A1(1'b1),            .A2(1'b0),    .B1(1'b0),  .B2(1'b1),    .C(AB[12]), .SELA(N16_QA_BUF), .SELAn(N16_QA_BUF2n), .SELB(N16_QB_BUF), .SELBn(N16_QB_BUF2n), .SELC(R113), .SELCn(R117), .RA(RA[12]));
 
    ADRR_SEL2 roe_0(.A(RDEN), .B(J140_Qn), .SELC(R113), .SELCn(R117), .X(ROE[0]));
    ADRR_SEL2 roe_1(.A(RDEN), .B(J151), .SELC(R113), .SELCn(R117), .X(ROE[1]));
    ADRR_SEL2 roe_2(.A(RDEN), .B(1'b1), .SELC(R113), .SELCn(R117), .X(ROE[2]));
    ADRR_SEL2 rcs_0(.A(CPU_VRAM_CS0), .B(1'b0), .SELC(R113), .SELCn(R117), .X(RCS[0]));
    ADRR_SEL2 rcs_1(.A(CPU_VRAM_CS1), .B(1'b0), .SELC(R113), .SELCn(R117), .X(RCS[1]));
    //* END Section 1.3. VRAM address outputs selection: A=CPU B=Rendering C=TEST_D11*



    //*** PAGE 2: GFX ROM address ***
    //* START Section 2.1. Timings signals *
    wire K148_Q;
    FDO_DLY k148(.D(K123_Q),.Rn(RES_SYNC3n), .CK(M24), .Q(K148_Q));

    wire L120_Q;
    FDE_DLY l120 (.D(K148_Q), .CLn(RES_SYNC3n), .CK(M24), .Q(L120_Q));

    wire M13; //Logic Cell K1B
    assign #1.26 M13 = L120_Q;
    assign PE = M13; //*** OUTPUT SIGNAL PE ***

    wire K130_Q;
    FDO_DLY k130(.D(K148_Q),.Rn(RES_SYNC3n), .CK(M24), .Q(K130_Q));

    wire K123_Q, K123_Qn;
    FDO_DLY k123(.D(J94_Qn),.Rn(RES_SYNC3n), .CK(M24), .Q(K123_Q), .Qn(K123_Qn));

    wire K119; //Logic Cell N3N
    assign #0.83 K119 = ~(NRD & K123_Qn & K130_Q);
    
    wire K114; //Logic Cell N3N
    assign #0.83 K114 = ~(NRD & K117 & K123_Qn);

    wire K121; //Logic Cell N2P
    assign #1.41 K121 = (NRD & K123_Q);

    wire [3:0] K77_Q;
    FDR_DLY k77( .D({K121, K114, K119, K117}), .CLn(RES_SYNC3n), .CK(M24), .Q(K77_Q));

    wire K110; //Logic Cell K1B
    assign #1.26 K110 = K77_Q[0];
    assign PQ = K110; //*** OUTPUT SIGNAL PQ ***

    wire K72; //Logic Cell K1B
    assign #1.26 K72 = K77_Q[1];
    assign WRP = K72; //*** OUTPUT SIGNAL WRP ***

    wire K55; //Logic Cell K1B
    assign #1.26 K55 = K77_Q[2];
    assign WREN = K55; //*** OUTPUT SIGNAL WREN ***

    wire K112; //Logic Cell K1B
    assign #1.26 K112 = K77_Q[3];
    assign RDEN = K112; //*** OUTPUT SIGNAL RDEN ***
    //* END Section 2.1. Timings signals *

    //* START Section 2.2. More timings signals *
    wire K141_Q, K141_Qn;
    FDN_DLY k141(.D(K141_Qn), .Sn(RES_SYNC3n), .CK(M24), .Q(K141_Q), .Qn(K141_Qn));
    wire M15; //Logic Cell K1B
    assign #1.26 M15 = K141_Q;
    assign M12 = M15; //*** OUTPUT SIGNAL M12 ***

    // wire Z4_Q, Z4_Qn;
    // FDN_DLY z4( .D(Z4_Qn), .Sn(BB8_BOT), .CK(M24), .Q(Z4_Q), .Qn(Z4_Qn)); //outputs to M12 bypass Z11 buffer
    // wire Z11; //Logic Cell K1B
    // assign #1.26 Z11 = Z4_Q;
    // assign M12 = Z11; //*** M12 Output Signal ***

    wire J110; //Logic Cell X2B
    assign #3.50 J110 = K141_Qn ^ J114_Qn;

    wire J114_Q, J114_Qn;
    FDN_DLY j114(.D(J110), .Sn(RES_SYNC3n), .CK(M24), .Q(J114_Q), .Qn(J114_Qn));

    wire M12n;
    assign M12n = K141_Qn;

    wire J109; //Logic Cell N2N
    assign #0.71 J109 = ~(K141_Qn & J114_Qn);

    wire J121; //Logic Cell KCB
    assign #3.31 J121 = J114_Q; //*** CLOCK TREE J121 ***

    wire J101; //Logic Cell X2B
    assign #3.50 J101 = (J109 ^ J94_Q);

    wire J94_Q, J94_Qn;
    FDN_DLY j94(.D(J101), .Sn(RES_SYNC3n), .CK(M24), .Q(J94_Q), .Qn(J94_Qn));

    wire J78; //Logic Cell V1N
    assign #0.55 J78 = ~M24;

    wire J79;
    FDE_DLY j79(.D(J94_Qn), .CLn(RES_SYNC3n), .CK(J78), .Q(J79));

    wire K117; //Logic Cell V1N
    assign #0.55 K117 = ~ J94_Qn;

    wire L80; //Logic Cell V2B
    assign #0.64 L80 = ~ K117;

    wire L78; //Logic Cell V2B
    assign #0.64 L78 = ~ L80;

    wire L82; //Logic Cell V1N
    assign #0.55 L82 = ~ L78; //** LATCH VRAM DATA  SC. 3.10 **

    wire L119; //Logic Cell V1N
    assign #0.55 L119 = ~ CRCS;

    wire L83; //Logic Cell N3P
    assign #1.82 L83 = L78 & L119 & PQ;

    wire C92; //R2N
    assign #0.87 C92 = ~(L83 | REG1C00[5]);
    
    //----------------------------------------------------------------------
    
    wire J140_Q, J140_Qn;
    FDO_DLY j140(.D(J121), .Rn(RES_SYNC3n), .CK(M12n), .Q(J140_Q), .Qn(J140_Qn));

    wire J151; //Logic Cell N2P
    assign #1.41 J151 = REG1C00[5] & J140_Q;

    wire H78; //Logic Cell V1N
    assign #0.55 H78 = ~PQ;

    wire H79_Q;
    FDO_DLY h79(.D(H78), .Rn(J79), .CK(J121), .Q(H79_Q));

    wire E143; //Logic Cell R2P
    assign #1.97 E143 = H79_Q | RMRD;

    assign VDE = E143; //*** OUTPUT SIGNAL VDE ***
    //* END Section 2.2. More timings signals *

    //* START Section 2.3. CPU(RMRD) ADDR -> GFX ROM *
    wire C111_Q;
    LTK_DLY c111 (.D(AB[4]), .Gn(C92), .Q(C111_Q));
    wire B106; //Logic Cell BD3
    assign #11.80 B106 = C111_Q;
    wire B111; //Logic Cell BD3
    assign #11.80 B111 = B106;

    wire C107_Q;
    LTK_DLY c107 (.D(AB[3]), .Gn(C92), .Q(C107_Q));
    wire C149; //Logic Cell BD3
    assign #11.80 C149 = C107_Q;
    wire C144; //Logic Cell BD3
    assign #11.80 C144 = C149;

    wire C129_Q;
    LTK_DLY c129 (.D(AB[3]), .Gn(C92), .Q(C129_Q));
    wire C124; //Logic Cell BD3
    assign #11.80 C124 = C129_Q;
    wire C119; //Logic Cell BD3
    assign #11.80 C119 = C124;
    //---------------------------------------------
    wire C64_Q;
    FDO_DLY c64 (.D(DB_BUF[2]), .Rn(RES_SYNCn), .CK(BEN), .Q(C64_Q));
    wire C81; //Logic Cell N2P
    assign #1.41 C81 = C64_Q & COL[1];
    
    //VC[2]
    wire CC59_Q;
    FDG_DLY cc59 (.D(ROW[2]), .CLn(RES_SYNCn), .CK(PXH1), .Q(CC59_Q));
    wire BB58_Xn;
    always @* begin
        if ((N16_QA_BUF2 === N16_QA_BUF3n) || (N16_QA_BUF3n === N16_QA_BUF2) || (N16_QB_BUF2 === N16_QB_BUF3n)) $display("*** BAD BB58 Sxx INPUT ***");
    end
    T5A_DLY bb58 (.A1(CC59_Q), .A2(CC59_Q), .B1(ROW_B[2]), .B2(ROW_A[2]), .S1n(N16_QA_BUF2), .S2(N16_QA_BUF3n), .S3n(N16_QA_BUF3n), .S4(N16_QA_BUF2), .S5n(N16_QB_BUF2), .S6(N16_QB_BUF3n), .Xn(BB58_Xn));
    wire M73; //Logic Cell V1N
    assign #0.55 M73 = ~BB58_Xn;
    wire C83; //Logic Cell X2B
    assign #3.50 C83 = M73 ^ C81;
    wire C99_Q;
    LTK_DLY c99 (.D(C83), .Gn(J79), .Q(C99_Q));
    wire C115_Xn;
    T2B_DLY c115 (.A(B111), .B(C99_Q), .S1n(RMRD_BUF), .S2(RMRDn), .Xn(C115_Xn));
    wire B118; //Logic Cell V2B
    assign #0.64 B118 = ~C115_Xn;
    assign VC[2] = B118;

    //VC[1]
    wire CC39; //Logic Cell BD5
    assign #22.18 CC39 = ROW[1]; //DELAY CELL LOOK DEEPER
    wire CC68_Q;
    FDG_DLY cc68 (.D(CC39), .CLn(RES_SYNCn), .CK(PXH1), .Q(CC68_Q));
    wire BB63_Xn;
    always @* begin
        if ((N16_QA_BUF2 === N16_QA_BUF3n) || (N16_QA_BUF3n === N16_QA_BUF2) || (N16_QB_BUF2 === N16_QB_BUF3n)) $display("*** BAD BB63 Sxx INPUT ***");
    end
    T5A_DLY bb63 (.A1(CC68_Q), .A2(CC68_Q), .B1(ROW_B[1]), .B2(ROW_A[1]), .S1n(N16_QA_BUF2), .S2(N16_QA_BUF3n), .S3n(N16_QA_BUF3n), .S4(N16_QA_BUF2), .S5n(N16_QB_BUF2), .S6(N16_QB_BUF3n), .Xn(BB63_Xn));
    wire M69; //Logic Cell V1N
    assign #0.55 M69 = ~BB63_Xn;
    wire C77; //Logic Cell X2B
    assign #3.50 C77 = M69 ^ C81;
    wire C93_Q;
    LTK_DLY c93 (.D(C77), .Gn(J79), .Q(C93_Q));
    wire C133_Xn;
    T2B_DLY c133 (.A(C144), .B(C93_Q), .S1n(RMRD_BUF), .S2(RMRDn), .Xn(C133_Xn));
    wire C137; //Logic Cell V2B
    assign #0.64 C137 = ~C133_Xn;
    assign VC[1] = C137;

    //VC[0]
    wire BB39_Q;
    FDG_DLY bb39 (.D(ROW[0]), .CLn(RES_SYNCn), .CK(PXH1), .Q(BB39_Q));
    wire BB68_Xn;
    T5A_DLY bb68 (.A1(BB39_Q), .A2(CC68_Q), .B1(ROW_B[0]), .B2(ROW_A[0]), .S1n(N16_QA_BUF2), .S2(N16_QA_BUF3n), .S3n(N16_QA_BUF3n), .S4(N16_QA_BUF2), .S5n(N16_QB_BUF2), .S6(N16_QB_BUF3n), .Xn(BB68_Xn));
    wire M71; //Logic Cell V1N
    assign #0.55 M71 = ~BB68_Xn;
    wire C87; //Logic Cell X2B
    assign #3.50 C87 = M71 ^ C81;
    wire C103_Q;
    LTK_DLY c103 (.D(C87), .Gn(J79), .Q(C103_Q));
    wire C117_Xn;
    T2B_DLY c117 (.A(C119), .B(C103_Q), .S1n(RMRD_BUF), .S2(RMRDn), .Xn(C117_Xn));
    wire C139; //Logic Cell V2B
    assign #0.64 C139 = ~C117_Xn;
    assign VC[0] = C139;
    
    //*** VC[6:3] ***
    wire [3:0] E120_P;
    LT4_DLY e120 (.D({AB[5],AB[6],AB[7],AB[8]}), .Gn(C92),.P(E120_P));
    wire [3:0] D96_Q;
    FDS_DLY d96 (.D({{VD_IN[0],VD_IN[1],VD_IN[2],VD_IN[3]}}), .CK(PXH0n), .Q(D96_Q));
    //VC[6] 
    wire D128_Xn;
    T2B_DLY d128 (.A(E120_P[0]), .B(D96_Q[0]), .S1n(RMRD_BUF), .S2(RMRDn), .Xn(D128_Xn));
    wire A144; //Logic Cell V2B
    assign #0.64 A144 = ~D128_Xn;
    assign VC[6] = A144;
    //VC[5] 
    wire D130_Xn;
    T2B_DLY d130 (.A(E120_P[1]), .B(D96_Q[1]), .S1n(RMRD_BUF), .S2(RMRDn), .Xn(D130_Xn));
    wire A146; //Logic Cell V2B
    assign #0.64 A146 = ~D130_Xn;
    assign VC[5] = A146;
    //VC[4] 
    wire D132_Xn;
    T2B_DLY d132 (.A(E120_P[2]), .B(D96_Q[2]), .S1n(RMRD_BUF), .S2(RMRDn), .Xn(D132_Xn));
    wire C143; //Logic Cell V2B
    assign #0.64 C143 = ~D132_Xn;
    assign VC[4] = C143;
    //VC[3] 
    wire D124_Xn;
    T2B_DLY d124 (.A(E120_P[3]), .B(D96_Q[3]), .S1n(RMRD_BUF), .S2(RMRDn), .Xn(D124_Xn));
    wire C141; //Logic Cell V2B
    assign #0.64 C141 = ~D124_Xn;
    assign VC[3] = C141;

    //VC[7:10]
    wire [3:0] D81_P;
    LT4_DLY d81 (.D({AB[9],AB[10],AB[11],AB[12]}), .Gn(C92),.P(D81_P));
    wire [3:0] D136_Q;
    FDS_DLY d136 (.D({{VD_IN[4],VD_IN[5],VD_IN[6],VD_IN[7]}}), .CK(PXH0n), .Q(D136_Q));
    //VC[7] 
    wire D126_Xn;
    T2B_DLY d126 (.A(D81_P[0]), .B(D136_Q[3]), .S1n(RMRD_BUF), .S2(RMRDn), .Xn(D126_Xn));
    wire A142; //Logic Cell V2B
    assign #0.64 A142 = ~D126_Xn;
    assign VC[7] = A142;
    //VC[8] 
    wire D122_Xn;
    T2B_DLY d122 (.A(D81_P[1]), .B(D136_Q[2]), .S1n(RMRD_BUF), .S2(RMRDn), .Xn(D122_Xn));
    wire A124; //Logic Cell V2B
    assign #0.64 A124 = ~D122_Xn;
    assign VC[8] = A124;
    //VC[9] 
    wire D120_Xn;
    T2B_DLY d120 (.A(D81_P[2]), .B(D136_Q[1]), .S1n(RMRD_BUF), .S2(RMRDn), .Xn(D120_Xn));
    wire A122; //Logic Cell V2B
    assign #0.64 A122 = ~D120_Xn;
    assign VC[9] = A122;
    //VC[10] 
    wire D118_Xn;
    T2B_DLY d118 (.A(D81_P[3]), .B(D136_Q[0]), .S1n(RMRD_BUF), .S2(RMRDn), .Xn(D118_Xn));
    wire A120; //Logic Cell V2B
    assign #0.64 A120 = ~D118_Xn;
    assign VC[10] = A120;
    //* END Section 2.3. CPU(RMRD) ADDR -> GFX ROM *


    //*** PAGE 3: CPU Stuff ***
    //* START Section 3.1. Reset synchronizer signals *
    
 
    wire N122_Q,RES_SYNC3n;
    FDE_DLY n122 (.D(1'b1), .CLn(RES), .CK(M24), .Q(N122_Q));
    assign RES_SYNC3n = N122_Q;


    wire M74; //Logic Cell K2B
    wire RES_SYNCn;
    assign #1.83 M74 = N122_Q;
    assign RES_SYNCn = M74;

    wire H12; //Logic Cell K1B
    wire RES_SYNC2n;
    assign #1.26 H12 = M74;
    assign RES_SYNC2n = H12;
    //* END Section 3.1. Reset synchronizer signals *

    //* START Section 3.2. Reset 8-frame delayed signal *
    wire [3:0] P51_Q;
    FDR_DLY p51(.D({P51_Q[2],P51_Q[1],P51_Q[0],RES_SYNC3n}), .CLn(RES_SYNC3n), .CK(TRIG_IRQ), .Q(P51_Q));

    wire [3:0] P18_Q;
    FDR_DLY p18(.D({P18_Q[2],P18_Q[1],P18_Q[0],P51_Q[3]}), .CLn(RES_SYNC3n), .CK(TRIG_IRQ), .Q(P18_Q));

    assign RST = P18_Q[3]; //*** OUTPUT SIGNAL RST ***
    //* END Section 3.2. Reset delayed signal *

    //* START Section 3.3. Buffered,inverted and ANDed signals *
    wire AB9_INV, AB9_BUF; //Logic Cell V1N 0.55//AB9_INV
    wire AB8_INV, AB8_BUF; //Logic Cell V1N 0.55//AB8_INV
    wire AB7_INV, AB7_BUF; //Logic Cell V1N 0.55//AB7_INV
    wire RMRDn; //Logic Cell V2B 0.64
    wire RMRD_BUF; //Logic Cell K1B 1.26
    wire AB_18XX; //Logic Cell K3B

    assign #0.55 AB9_INV = ~AB[9];
    assign #0.55 AB9_BUF = ~AB9_INV;
    
    assign #0.55 AB8_INV = ~AB[8];
    assign #0.55 AB8_BUF = ~AB8_INV;
    
    assign #0.55 AB7_INV = ~AB[7];
    assign #0.55 AB7_BUF = ~AB7_INV;

    assign #1.26 RMRDn = ~RMRD;
    assign #0.64 RMRD_BUF = RMRD;

    assign #1.45 AB_18XX = AB[12] & AB[12];
    //* END Section 3.3. Buffered,inverted and ANDed signals *

    //* START Section 3.4. Buffered DB_IN[7:0], Tri-State ports for DB, VD signals *
    wire [7:0] DB_IN;
    wire [7:0] DB_OUT; //DATA OUT K052109 -> CPU DATA BUS
    wire [7:0] DB_BUF;
    wire [15:0] VD_IN;

    //DB_BUF
    generate
        genvar i;
        for(i=0; i < 8; i=i+1) begin
            //Logic Cell K2B
            assign #1.83 DB_BUF[i] = DB_IN[i];
        end
    endgenerate
    
    //Port DB
    generate
        for(i=0; i < 8; i=i+1) begin: DB_IO_PORT
            //H6T
            assign #6.47 DB[i] = ~DB_DIR ? DB_OUT[i] : 1'bZ ;
            assign #3.08 DB_IN[i] = DB[i];
        end
    endgenerate

    //Port VD[15:8]
    generate
        for(i=15; i >= 8; i=i-1) begin: VD_HIGH_IO_PORT
            //H6T
            assign #6.47 VD[i] = ~VD_HIGH_DIR ? DB_BUF[i-8] : 1'bZ ;
            assign #3.08 VD_IN[i] = VD[i];
        end
    endgenerate

    //Port VD[7:0]
    generate
        for(i=7; i >= 0; i=i-1) begin: VD_LOW_IO_PORT
            //H6T
            assign #6.47 VD[i] = ~VD_LOW_DIR ? DB_BUF[i] : 1'bZ ;
            assign #3.08 VD_IN[i] = VD[i];
        end
    endgenerate
    //* END Section 3.4. Buffered DB_IN[7:0] signals *

    //* START Section 3.5. Interrupt flags signals *
    wire P4_Q;
    FDN_DLY p4(.D(1'b0), .Sn(REG1D00[2]), .CK(TRIG_IRQ), .Q(P4_Q));
    assign IRQ = P4_Q; //*** OUTPUT SIGNAL IRQ ***

    wire F27_Q;
    FDN_DLY f27(.D(1'b0), .Sn(REG1D00[1]), .CK(TRIG_FIRQ), .Q(F27_Q));
    assign FIRQ = F27_Q; //*** OUTPUT SIGNAL FIRQ ***

    wire CC52_Q;
    FDN_DLY cc52(.D(1'b0), .Sn(REG1D00[0]), .CK(TRIG_NMI), .Q(CC52_Q));
    assign NMI = CC52_Q; //*** OUTPUT SIGNAL NMI ***
    //* END Section 3.5. Interrupt flags signals *

    //* START Section 3.6. CPU data bus Tri-state control and VD_IN byte selector (high or low) signals *
    wire B125; //Logic Cell R2P
    assign #1.97 B125 = CPU_VRAM_CS0 | RDEN;
    wire C72; //Logic Cell V1N
    assign #0.55 C72 = ~REG1C00[4];

    wire B123; //Logic Cell R2P
    assign #1.97 B123 = B125 | C72;
    
    wire B121; //Logic Cell N2P
    assign #1.41 B121 = C72 & REG1C00[3];
    wire B134; //Logic Cell V1N
    assign #0.55 B134 = ~B121;
    wire B146; //Logic Cell V1N
    assign #0.55 B146 = ~B134;
    
    wire A151; //Logic Cell R2P
    assign #1.97 A151 = CPU_VRAM_CS1 | RDEN;
    wire A154; //Logic Cell V1N
    assign #0.55 A154 = ~A151;

    wire B119; //Logic Cell N2P
    assign #1.41 B119 = C72 & REG1C00[2];
    wire B132; //Logic Cell V1N
    assign #0.55 B132 = ~B119;
    wire B142; //Logic Cell V1N
    assign #0.55 B142 = ~B132;

    wire B127; //Logic Cell R2P
    assign #1.97 B127 = A126 | RDEN;
    wire B129; //Logic Cell R2P
    assign #1.97 B129 = B127 | C72;

    wire B137; //Logic Cell N3N
    assign #0.83 B137 = ~(A154 & B132 & B134);
    wire B143; //Logic Cell N3N
    assign #0.83 B143 = ~(A154 & B132 & B146);
    wire B139; //Logic Cell N3N
    assign #0.83 B139 = ~(A154 & B134 & B142);

    wire B147; //Logic Cell N2P
    assign #1.41 B147 = B123 & B143;

    wire B149; //Logic Cell K3B
    assign #1.45 B149 = B137 & B147;

    wire B152; //Logic Cell K3B
    assign #1.45 B152 = B129 & B139;

    wire L143; //Logic Cell K3B
    assign #1.45 L143 = B149 & B152;

    wire DB_DIR;
    assign DB_DIR = L143; //*** CPU DATA BUS DIRECTION CONTROL ***
    wire L147; //Logic Cell V2B
    assign #0.64 L147 = ~B152; //** Selects VRAM DATA BYTE (HIGH OR LOW) SC. 3.10
    wire L148; //Logic Cell K2B
    assign #1.83 L148 = B152; //** Selects VRAM DATA BYTE (HIGH OR LOW) SC. 3.10
    //* END Section 3.6. CPU data bus Tri-state control and VD_IN byte selector (high or low) signals *

    //* START Section 3.7. VRAM config and CS/RW control signals *
    //Reg 1C00 bits 0 and 1 used for VRAM map and chip configuration
    // ----------------------------------------------------
    //| 1C00[1:0] | RWE[1]        | RWE[2]        | RWE[0]        |
    //|-----------+-------------+-------------+-------------|
    //|    0  0   | 0x0000-1FFF | 0x2000-3FFF | 0x4000-5FFF |
    //|    0  1   | 0x2000-3FFF | 0x4000-5FFF | 0x6000-7FFF |
    //|    1  0   | 0x4000-5FFF | 0x6000-7FFF | 0x8000-9FFF |
    //|    1  1   | 0x6000-7FFF | 0x8000-9FFF | 0xA000-BFFF |
    // -----------------------------------------------------
    wire CC34; //Logic Cell V1N
    assign #0.55 CC34 = ~AB[15];
    wire A92; //Logic Cell V1N
    assign #0.55 A92 = ~CC34;

    wire CC51; //Logic Cell V1N
    assign #0.55 CC51 = ~AB[14];
    wire A90; //Logic Cell V1N
    assign #0.55 A90 = ~CC51;

    wire CC49; //Logic Cell V1N
    assign #0.55 CC49 = ~AB[13];
    wire A94; //Logic Cell V1N
    assign #0.55 A94 = ~CC49;

    wire E34; //Logic Cell R2B
    assign #1.97 E34 = ~(VCS | RMRD);

    wire A77; //Logic Cell N4N
    assign #0.96 A77 = ~(CC34 & E34 & CC49 & CC51); //RANGE 0X0000-0X1FFF
    wire A83; //Logic Cell N4N
    assign #0.96 A83 = ~(CC34 & E34 & A94 & CC51); //RANGE 0X2000-0X3FFF
    wire A79; //Logic Cell N4N
    assign #0.96 A79 = ~(CC34 & E34 & CC49 & A90); //RANGE 0X4000-0X5FFF
    wire A85; //Logic Cell N4N
    assign #0.96 A85 = ~(CC34 & E34 & A94 & A90); //RANGE 0X6000-0X7FFF
    wire A81; //Logic Cell N4N
    assign #0.96 A81 = ~(E34 & CC49 & CC51 & A92); //RANGE 0X8000-0X9FFF
    wire A87; //Logic Cell N4N
    assign #0.96 A87 = ~(E34 & A94 & CC51 & A92); //RANGE 0XA000-0XBFFF

    wire A128; //Logic Cell V1N
    assign #0.55 A128 = ~REG1C00[1];
    wire A130; //Logic Cell V1N
    assign #0.55 A130 = ~A128;
    wire A131; //Logic Cell K1B
    assign #1.26 A131 = A128;

    wire A136; //Logic Cell V1N
    assign #0.55 A136 = ~REG1C00[0];
    wire A148; //Logic Cell V1N
    assign #0.55 A148 = ~A136;
    wire A149; //Logic Cell K1B
    assign #1.26 A149 = A136;

    wire A101_Xn;
    T5A_DLY a101 (.A1(A77), .A2(A83), .B1(A85), .B2(A79), .S1n(A149), .S2(A148), .S3n(A148), .S4(A149), .S5n(A131), .S6(A130), .Xn(A101_Xn));
    wire A100; //Logic Cell V1N
    assign #0.55 A100 = ~A101_Xn;
    wire CPU_VRAM_CS1;
    assign CPU_VRAM_CS1 = A100;
    wire L12; //Logic Cell R2P
    assign #1.97 L12 = CPU_VRAM_CS1 | WRP;
    assign RWE[1] = L12; //*** OUTPUT SIGNAL RWE[1] ***
    wire L15; //Logic Cell V2B
    assign #0.64 L15 = ~L12;

    wire A106_Xn;
    T5A_DLY a106 (.A1(A83), .A2(A79), .B1(A81), .B2(A85), .S1n(A149), .S2(A148), .S3n(A148), .S4(A149), .S5n(A131), .S6(A130), .Xn(A106_Xn));
    wire A126; //Logic Cell V1N
    assign #0.55 A126 = ~A106_Xn;
    wire A44; //Logic Cell K4B
    assign #1.45 A44 = A126 | WREN; 
    wire VD_LOW_DIR;
    assign VD_LOW_DIR = A44; //*** VD_LOW_DIR TRI-STATE CONTROL VD[7:0] ***
    wire L10; //Logic Cell R2P
    assign #1.97 L10 = A126 | WRP;
    assign RWE[2] = L10; //*** OUTPUT SIGNAL RWE[2] ***

    wire A111_Xn;
    T5A_DLY a111 (.A1(A79), .A2(A85), .B1(A87), .B2(A81), .S1n(A149), .S2(A148), .S3n(A148), .S4(A149), .S5n(A131), .S6(A130), .Xn(A111_Xn));
    wire A134; //Logic Cell V1N
    assign #0.55 A134 = ~A111_Xn;
    wire CPU_VRAM_CS0;
    assign CPU_VRAM_CS0 = A134;
    wire M35; //Logic Cell R2P
    assign #1.97 M35 = CPU_VRAM_CS0 | WRP;
    assign RWE[0] = M35; //*** OUTPUT SIGNAL RWE[0] ***

    wire A39; //Logic Cell N2P
    assign #1.41 A39 = CPU_VRAM_CS1 & CPU_VRAM_CS0;

    wire A41; //Logic Cell K4B
    assign #1.45 A41 = A39 | WREN;
    wire VD_HIGH_DIR = A41; //*** VD_HIGH_DIR TRI-STATE CONTROL VD[15:8] ***
    //* END Section 3.7. VRAM config and CS/RW control signals *

    //* START Section 3.8. Set Scroll interval 32/256 *
    wire E45; //Logic Cell V1N
    assign #0.55 E45 = ~G29_Q[0]; //G29_QA

    wire E38; //Logic Cell N2P
    assign #1.41 E38 = REG1C80[0] & G29_Q[0];
    wire E42; //Logic Cell N2P
    assign #1.41 E42 = E45 & REG1C80[3];
    wire E40; //Logic Cell R2P
    assign #1.97 E40 = E38 | E42;

    wire AA61; //Logic Cell N2P
    assign #1.41 AA61 = ROW[0] & E40;
    wire AA59; //Logic Cell N2P
    assign #1.41 AA59 = ROW[1] & E40;
    wire AA63; //Logic Cell N2P
    assign #1.41 AA63 = ROW[2] & E40;

    wire [3:0] Z3_S;
    wire Z3_CO;
    A4H_DLY z3 (.A({PXH6,PXH5,PXH4F,PXH3F}),.B({4{FLIP_SCREEN}}), .CI(1'b0), .S(Z3_S), .CO(Z3_CO));
    wire [1:0] Z53_S;
    wire Z53_CO;
    A2N_DLY z53 (.A({PXH8,PXH7}),.B({2{FLIP_SCREEN}}), .CI(Z3_CO), .S(Z53_S), .CO(Z53_CO));

    //SCROLL RAM Address lines
    wire [5:0] SCROLL_RAM_A;
    //SCROLL_RAM_A[0]
    wire AA75_X;
    D24_DLY aa75 (.A1(PXH3), .A2(AA38), .B1(Z3_S[0]), .B2(AA58), .X(AA75_X));
    wire AA80; //Logic Cell V1N
    assign #0.55 AA80 = ~AA75_X;
    assign SCROLL_RAM_A[0] = AA80;
    //SCROLL_RAM_A[1]
    wire AA65_X;
    D24_DLY aa65 (.A1(AA61), .A2(AA38), .B1(Z3_S[1]), .B2(AA58), .X(AA65_X)); //ROW[0]
    wire AA78; //Logic Cell V1N
    assign #0.55 AA78 = ~AA65_X;
    assign SCROLL_RAM_A[1] = AA78;
    //SCROLL_RAM_A[2]
    wire AA67_X;
    D24_DLY aa67 (.A1(AA59), .A2(AA38), .B1(Z3_S[2]), .B2(AA58), .X(AA67_X)); //ROW[1]
    wire Z154; //Logic Cell V1N
    assign #0.55 Z154 = ~AA67_X;
    assign SCROLL_RAM_A[2] = Z154;
    //SCROLL_RAM_A[3]
    wire AA69_X;
    D24_DLY aa69 (.A1(AA63), .A2(AA38), .B1(Z3_S[3]), .B2(AA58), .X(AA69_X)); //ROW[2]
    wire Z136; //Logic Cell V1N
    assign #0.55 Z136 = ~AA69_X;
    assign SCROLL_RAM_A[3] = Z136;
    //SCROLL_RAM_A[4]
    wire AA71_X;
    D24_DLY aa71 (.A1(ROW[3]), .A2(AA38), .B1(Z53_S[0]), .B2(AA58), .X(AA71_X)); //ROW[3]
    wire Z156; //Logic Cell V1N
    assign #0.55 Z156 = ~AA71_X;
    assign SCROLL_RAM_A[4] = Z156;
    //SCROLL_RAM_A[5]
    wire AA73_X;
    D24_DLY aa73 (.A1(ROW[4]), .A2(AA38), .B1(Z53_S[1]), .B2(AA58), .X(AA73_X)); //ROW[4]
    wire Z134; //Logic Cell V1N
    assign #0.55 Z134 = ~AA73_X;
    assign SCROLL_RAM_A[5] = Z134;
    //* END Section 3.8. Set Scroll interval 32/256 *

    //* START Section 3.9. VRAM read by CPU *
    wire [3:0] M77_P;
    LT4_DLY m77 (.D(VD_IN[3:0]), .Gn(L82),.P(M77_P));
    //DB_OUT[0]
    wire M90_Xn;
    T2B_DLY m90 (.A(L95_P[0]), .B(M77_P[0]), .S1n(L148), .S2(L147), .Xn(M90_Xn));
    wire M144; //Logic Cell V2B
    assign #0.64 M144 = ~M90_Xn;
    assign DB_OUT[0] = M144;
    //DB_OUT[1]
    wire L86_Xn;
    T2B_DLY l86 (.A(L95_P[1]), .B(M77_P[1]), .S1n(L148), .S2(L147), .Xn(L86_Xn));
    wire L117; //Logic Cell V2B
    assign #0.64 L117 = ~L86_Xn;
    assign DB_OUT[1] = L117;
    
    wire [3:0] M100_P;
    LT4_DLY m100 (.D(VD_IN[7:4]), .Gn(L82),.P(M100_P));
    //DB_OUT[2]
    wire M96_Xn;
    T2B_DLY m96 (.A(L95_P[2]), .B(M77_P[2]), .S1n(L148), .S2(L147), .Xn(M96_Xn));
    wire M146; //Logic Cell V2B
    assign #0.64 M146 = ~M96_Xn;
    assign DB_OUT[2] = M146;
    //DB_OUT[3]
    wire M98_Xn;
    T2B_DLY m98 (.A(L95_P[3]), .B(M77_P[3]), .S1n(L148), .S2(L147), .Xn(M98_Xn));
    wire M148; //Logic Cell V2B
    assign #0.64 M148 = ~M98_Xn;
    assign DB_OUT[3] = M148;
    
    wire [3:0] L95_P;
    LT4_DLY l95 (.D(VD_IN[11:8]), .Gn(L82),.P(L95_P));
    //DB_OUT[4]
    wire M141_Xn;
    T2B_DLY m141 (.A(M117_P[0]), .B(M100_P[0]), .S1n(L148), .S2(L147), .Xn(M141_Xn));
    wire M150; //Logic Cell V2B
    assign #0.64 M150 = ~M141_Xn;
    assign DB_OUT[4] = M150;
    //DB_OUT[5]
    wire M132_Xn;
    T2B_DLY m132 (.A(M117_P[1]), .B(M100_P[1]), .S1n(L148), .S2(L147), .Xn(M132_Xn));
    wire M152; //Logic Cell V2B
    assign #0.64 M152 = ~M132_Xn;
    assign DB_OUT[5] = M152;
    
    wire [3:0] M117_P;  
    LT4_DLY m117 (.D(VD_IN[15:12]), .Gn(L82),.P(M117_P));
    //DB_OUT[6]
    wire M134_Xn;
    T2B_DLY m134 (.A(M117_P[2]), .B(M100_P[2]), .S1n(L148), .S2(L147), .Xn(M134_Xn));
    wire M154; //Logic Cell V2B
    assign #0.64 M154 = ~M134_Xn;
    assign DB_OUT[6] = M154;
    //DB_OUT[7]
    wire M130_Xn;
    T2B_DLY m130 (.A(M117_P[3]), .B(M100_P[3]), .S1n(L148), .S2(L147), .Xn(M130_Xn));
    wire M118; //Logic Cell V2B
    assign #0.64 M118 = ~M130_Xn;
    assign DB_OUT[7] = M118;
    //* END Section 3.9. VRAM read by CPU *


    //*** PAGE 4: H/V Counters ***
    //* START Section 4.1. HORIZONTAL COUNTER signals *
    wire H20_Q;
    FDO_DLY h20(.D(PQ),.Rn(RES_SYNC2n), .CK(J121), .Q(H20_Q));

    wire H15; //Logic Cell R2P
    assign #0.87 H15 = TEST_D15 | H20_Q;

    wire H17; //Logic Cell K2B
    assign #1.83 H17 = H20_Q;

    wire PXH0; //Logic Cell K2B
    wire PXH0n; //Logic Cell V1N
    assign #1.83 PXH0 = H17;
    assign #0.55 PXH0n = ~PXH0;

    wire N16_CO;
    wire N16_QD, N16_QC, N16_QB, N16_QA;
    wire PXH1, PXH2;
    C43_DLY n16(.CK(J121),
                .CLn(RES_SYNC2n),
                .Ln(LINE_ENDn),
                .CI(H15),
                .EN(H15),
                .CO(N16_CO),
                .Q({N16_QD,N16_QC,N16_QB, N16_QA}),
                .D({4{1'b0}}));
    assign PXH1 = N16_QA;
    assign PXH2 = N16_QB;

    wire [3:0] G29_Q;
    C43_DLY g29(.CK(J121),
                .CLn(RES_SYNC2n),
                .Ln(LINE_ENDn),
                .CI(N16_CO),
                .EN(N16_CO),
                .Q(G29_Q),
                .D({{3{1'b0}},1'b1}));
    //*** G29_Q[0] -> 3.8, 7.5             

    wire G44; //AND-OR-NAND
    assign #4 G44 = ~(((N16_CO & G29_Q[1]) | G4_Q) & LINE_ENDn);

    wire G4_Q; //connects to 4.3, 7 Scroll RAM read triggers
    FDO_DLY g4(.D(F16),.Rn(RES_SYNC2n), .CK(J121), .Q(G4_Q));

    wire F16; //Logic Cell V1N
    assign #0.55 F16 = ~G44;

    wire PXH3;
    wire PXH4;
    assign PXH3 = N16_QC;
    assign PXH4 = N16_QD;

    wire PXH3F; //Logic Cell X2B
    assign #3.50 PXH3F = FLIP_SCREEN ^ N16_QC;

    wire PXH4F; //Logic Cell X2B
    assign #3.50 PXH4F = FLIP_SCREEN ^ N16_QD;

    wire PXH5; //Logic Cell X2B
    assign #3.50 PXH5 = FLIP_SCREEN ^ G29_Q[0];

    wire PXH6; //Logic Cell X2B
    assign #3.50 PXH6 = FLIP_SCREEN ^ G29_Q[1];

    wire PXH7; //Logic Cell X2B
    assign #3.50 PXH7 = FLIP_SCREEN ^ G29_Q[2];  

    wire PXH8; //Logic Cell X2B
    assign #3.50 PXH8 = FLIP_SCREEN ^ G29_Q[3];    

    wire LINE_END; //Logic Cell N3P
    assign #1.82 LINE_END = G29_Q[2] & G29_Q[3] & N16_CO;

    wire LINE_ENDn; //Logic Cell V1N
    assign #0.55 LINE_ENDn = ~LINE_END;
    //* END Section 4.1. HORIZONTAL COUNTER signals *

    //* START Section 4.2. VERTICAL COUNTER signals *
    wire G11; //Logic Cell X2B
    assign #3.50 G11 = LINE_END ^ G20_Qn;

    wire G20_Q, G20_Qn;
    FDO_DLY g20(.D(G11),.Rn(RES_SYNC2n), .CK(J121), .Q(G20_Q), .Qn(G20_Qn));

    wire TRIG_FIRQ; //Logic Cell V2B
    assign #0.64 TRIG_FIRQ = ~G20_Qn;

    wire H6; //Logic Cell R2P
    assign #1.97 H6 = G20_Q | TEST_D15;

    wire H10; //Logic Cell N2P
    assign #1.41 H10 = G20_Q & LINE_END;

    wire H8; //Logic Cell R2P
    assign #1.97 H8 = H10 | TEST_D15;

    wire H4; //Logic Cell R2P
    assign #1.97 H4 = TEST_D15 | G20_Q;

    wire [3:0] J29_Q;
    wire J29_CO;
    C43_DLY j29 (.CK(J121),
    .CLn(RES_SYNC2n),
    .Ln(H3),
    .CI(H8),
    .EN(H6),
    .CO(J29_CO),
    .Q(J29_Q),
    .D({{2{1'b1}},{2{1'b0}}}));

    wire [3:0] H29_Q;
    wire H29_CO;
    C43_DLY h29 (.CK(J121),
    .CLn(RES_SYNC2n),
    .Ln(H3),
    .CI(J29_CO),
    .EN(H4),
    .CO(H29_CO),
    .Q(H29_Q),
    .D({1'b0,{3{1'b1}}}));

    wire H3; //Logic Cell V1N
    assign #0.55 H3 = ~H29_CO;

    wire R10; //Logic Cell BD5
    assign #22.18 R10 = H3; //LOOK DEEPER AT THIS, real delay capture HVOT signal
    wire R19; //Logic Cell K1B
    assign #1.26 R19 = R10;

    assign HVOT = R19; //*** OUTPUT SIGNAL HVOT ***

    //--G20--
    wire [7:0] ROW; //Logic Cell X2B
    assign #3.50 ROW[0] = FLIP_SCREEN ^ G20_Q;

    //--J29--

    assign #3.50 ROW[1] = FLIP_SCREEN ^ J29_Q[0]; //QA

    assign #3.50 ROW[2] = FLIP_SCREEN ^ J29_Q[1]; //QB

    assign #3.50 ROW[3] = FLIP_SCREEN ^ J29_Q[2]; //QC

    assign #3.50 ROW[4] = FLIP_SCREEN ^ J29_Q[3]; //QD

    //--H29--

    assign #3.50 ROW[5] = FLIP_SCREEN ^ H29_Q[0]; //QA

    assign #3.50 ROW[6] = FLIP_SCREEN ^ H29_Q[1]; //QB

    assign #3.50 ROW[7] = FLIP_SCREEN ^ H29_Q[2]; //QC

    wire CC13_Q, CC13_Qn;
    FDG_DLY cc13 (.D(CC13_Qn), .CLn(RES_SYNCn), .CK(J29_Q[1]), .Q(CC13_Q),.Qn(CC13_Qn));

    wire CC24_Q, CC24_Qn;
    FDG_DLY cc24 (.D(CC24_Qn), .CLn(RES_SYNCn), .CK(CC13_Q), .Q(CC24_Q),.Qn(CC24_Qn));

    wire TRIG_NMI;
    assign TRIG_NMI = CC24_Q;

    wire K74; //Logic Cell N3P
    assign #1.82 K74 = H29_Q[0] & H29_Q[1] & H29_Q[2];

    wire K37; //Logic Cell BD3
    assign #11.80 K37 = K74; 

    wire TRIG_IRQ; //LOOK DEEPER AT THIS, real delay capture TRIG_IRQ signal
    FDO_DLY k42 (.D(K37), .Rn(RES_SYNC2n), .CK(J29_Q[3]), .Q(TRIG_IRQ));
    //* END Section 4.2. VERTICAL COUNTER signals *

    //* START Section 4.3. TEST D13,D14 signals *
    wire D42; //Logic Cell V1N
    assign #0.55 D42 = ~TEST_D13;

    wire D39;
    D24_DLY d39 (.A1(G4_Q), .A2(D42), .B1(TEST_D14), .B2(TEST_D13), .X(D39));

    wire AA38;//Logic Cell K2B
    assign #1.83 AA38 = D39; //SECTION 3.8, PAGE 1 Y69

    wire AA58; //Logic Cell V2B
    assign #0.64 AA58 = ~D39; //SECTION 3.8, PAGE 1 Y69
    //* END Section 4.3. TEST D13,D14 signals *

    //*** PAGE 5: REGISTERS ***
    //* START Section 5.1. TEST signals *
    wire TEST_D15;
    wire TEST_D14;
    wire TEST_D13;
    wire TEST_D12;

    wire TEST_D11;
    wire TEST_D10;
    wire TEST_D9;
    wire TEST_D8;

    wire AB3_REG;
    wire AB2_REG;
    wire AB1_REG;

    wire V51_QD;
    FDR_DLY v51(.D({AB[0],AB[1],AB[2],AB[3]}), 
                .CLn(RES_SYNCn),
                .CK(TEST), 
                .Q({V51_QD,AB1_REG,AB2_REG,AB3_REG}));

    wire TEST_EN2n; //Logic Cell V2B
    wire TEST_ENn; //Logic Cell V1N
    wire TEST_EN; //Logic Cell K1B
    
    assign #0.64 TEST_EN2n = ~V51_QD;
    assign #0.55 TEST_ENn = ~V51_QD;
    assign #1.26 TEST_EN = V51_QD;

    FDR_DLY d51(.D({DB_BUF[4],DB_BUF[5],DB_BUF[6],DB_BUF[7]}),  
            .CLn(RES_SYNCn),
            .CK(TEST), 
            .Q({TEST_D12,TEST_D13,TEST_D14,TEST_D15}));

    FDR_DLY l51(.D({DB_BUF[0],DB_BUF[1],DB_BUF[2],DB_BUF[3]}), 
            .CLn(RES_SYNCn),
            .CK(TEST), 
            .Q({TEST_D8,TEST_D9,TEST_D10,TEST_D11}));
    //* END Section 5.1. TEST signals *
    
    //* START Section 5.2. REGISTER 0x1D80 *
    wire D12; //Logic Cell N6B
    assign #2.83 D12 = ~(L15 & AB9_INV & AB[10] & AB7_BUF & AB8_BUF & AB_18XX); //L15 FROM SECTION 3.8

    wire [7:0] REG1D80;
    FDR_DLY a5 (.D({DB_BUF[4],DB_BUF[5],DB_BUF[6],DB_BUF[7]}), .CLn(RES_SYNCn), .CK(D12), .Q({REG1D80[4],REG1D80[5],REG1D80[6],REG1D80[7]}));
    FDR_DLY c3 (.D({DB_BUF[0],DB_BUF[1],DB_BUF[2],DB_BUF[3]}), .CLn(RES_SYNCn), .CK(D12), .Q({REG1D80[0],REG1D80[1],REG1D80[2],REG1D80[3]}));
    //* END Section 5.2. REGISTER 0x1D80 *

    //* START Section 5.3. REGISTER 0x1D00 *
    wire D18; //Logic Cell N6B
    assign #2.83 D18 = ~(L15 & AB9_INV & AB[10] & AB7_INV & AB8_BUF & AB_18XX); //L15 FROM SECTION 3.8

    wire [3:0] REG1D00;
    FDR_DLY f51 (.D({DB_BUF[0],DB_BUF[1],DB_BUF[2],DB_BUF[3]}), .CLn(RES_SYNCn), .CK(D18), .Q({REG1D00[0],REG1D00[1],REG1D00[2],REG1D00[3]}));
    //* END Section 5.3. REGISTER 0x1D00 *

    //* START Section 5.4. REGISTER 0x1C00 *
    wire D23; //Logic Cell N6B
    assign #2.83 D23 = ~(L15 & AB9_INV & AB[10] & AB7_INV & AB8_INV & AB_18XX); //L15 FROM SECTION 3.8

    wire [7:0] REG1C00;
    FDR_DLY c38 (.D({DB_BUF[4],DB_BUF[5],DB_BUF[6],DB_BUF[7]}), .CLn(RES_SYNCn), .CK(D23), .Q({REG1C00[4],REG1C00[5],REG1C00[6],REG1C00[7]}));
    FDR_DLY b77 (.D({DB_BUF[0],DB_BUF[1],DB_BUF[2],DB_BUF[3]}), .CLn(RES_SYNCn), .CK(D23), .Q({REG1C00[0],REG1C00[1],REG1C00[2],REG1C00[3]}));
    //* END Section 5.4. REGISTER 0x1C00 *

    //* START Section 5.5. REGISTER 0x1C80 *
    wire D7; //Logic Cell N6B
    assign #2.83 D7 = ~(L15 & AB9_INV & AB[10] & AB7_BUF & AB8_INV & AB_18XX); //L15 FROM SECTION 3.8

    wire [7:0] REG1C80;
    FDR_DLY e4 (.D({DB_BUF[4],DB_BUF[5],DB_BUF[6],DB_BUF[7]}), .CLn(RES_SYNCn), .CK(D7), .Q({REG1C80[4],REG1C80[5],REG1C80[6],REG1C80[7]}));
    FDR_DLY e51 (.D({DB_BUF[0],DB_BUF[1],DB_BUF[2],DB_BUF[3]}), .CLn(RES_SYNCn), .CK(D7), .Q({REG1C80[0],REG1C80[1],REG1C80[2],REG1C80[3]}));
    //* END Section 5.5. REGISTER 0x1C80 *

    //* START Section 5.6. REGISTER 0x1F00 *
    wire D33; //Logic Cell N6B
    assign #2.83 D33 = ~(L15 & AB9_BUF & AB[10] & AB7_INV & AB8_BUF & AB_18XX); //L15 FROM SECTION 3.8

    wire [7:0] REG1F00;
    FDR_DLY a51 (.D({DB_BUF[4],DB_BUF[5],DB_BUF[6],DB_BUF[7]}), .CLn(RES_SYNCn), .CK(D33), .Q({REG1F00[4],REG1F00[5],REG1F00[6],REG1F00[7]}));
    FDR_DLY b51 (.D({DB_BUF[0],DB_BUF[1],DB_BUF[2],DB_BUF[3]}), .CLn(RES_SYNCn), .CK(D33), .Q({REG1F00[0],REG1F00[1],REG1F00[2],REG1F00[3]}));
    //* END Section 5.6. REGISTER 0x1F00 *

    //* START Section 5.7. REGISTER 0x1E80 *
    wire D2; //Logic Cell N6B
    assign #2.83 D2 = ~(L15 & AB9_BUF & AB[10] & AB7_BUF & AB8_INV & AB_18XX); //L15 FROM SECTION 3.8
    assign BEN = D2; //*** OUTPUT SIGNAL BEN ***
    
    wire M53_Q;
    FDO_DLY m53 (.D(DB_BUF[0]), .Rn(RES_SYNCn), .CK(BEN), .Q(M53_Q));
    wire FLIP_SCREEN; //Logic Cell K2B
    assign #1.83 FLIP_SCREEN = M53_Q;

    wire FLIP_SCREEN_BUF; //Logic Cell K1B
    assign #1.26 FLIP_SCREEN_BUF = FLIP_SCREEN;
    //* END Section 5.7. REGISTER 0x1E80 *

    //* START Section 5.8. REGISTER 0x1E00 *
    wire REG_1E00_WRn; //Logic Cell N6B
    assign #2.83 REG_1E00_WRn = ~(L15 & AB9_BUF & AB[10] & AB7_INV & AB8_INV & AB_18XX); //L15 FROM SECTION 3.8
    //* END Section 5.8. REGISTER 0x1E00 *


    //*** PAGE 6: LAYER B SCROLL ***
    //* START Section 6.1. Layer B Tilemap X Address generetor signals *
    wire BB2_Q;
    FDN_DLY bb2 (.D(PXH3), .Sn(READ_SCROLL_B), .CK(PXH1), .Q(BB2_Q));
    wire BB50_X;
    D24_DLY bb50 (.A1(BB2_Q), .A2(TEST_EN2n), .B1(AB1_REG), .B2(TEST_EN), .X(BB50_X));

    wire BB9_Qn;
    FDE_DLY bb9 (.D(PXH3), .CLn(READ_SCROLL_B), .CK(PXH1), .Qn(BB9_Qn));
    wire BB52_X;
    D24_DLY bb52 (.A1(BB9_Qn), .A2(TEST_EN2n), .B1(AB2_REG), .B2(TEST_EN), .X(BB52_X));

    wire [3:0] CC77_Q;
    FDR_DLY cc77 (.D({VD_IN[0],VD_IN[1],VD_IN[2],VD_IN[3]}), .CLn(RES_SYNCn), .CK(BB50_X), .Q(CC77_Q)); //inverted data port D
    wire [3:0] Y131_Q;
    FDR_DLY y131 (.D({VD_IN[4],VD_IN[5],VD_IN[6],VD_IN[7]}), .CLn(RES_SYNCn), .CK(BB50_X), .Q(Y131_Q)); //inverted data port D

    wire AA81_Q;
    FDE_DLY aa81 (.D(VD_IN[0]), .CLn(RES_SYNCn), .CK(BB52_X), .Q(AA81_Q));

    wire AA91; //Logic Cell K1B
    assign #1.26 AA91 = FLIP_SCREEN;

    wire [3:0] CC107_S;
    wire CC107_CO;
    A4H_DLY cc107 (.A({{CC77_Q[0],CC77_Q[1],CC77_Q[2],CC77_Q[3]}}),.B({AA91,1'b0,{2{AA91}}}), .CI(1'b0), .S(CC107_S), .CO(CC107_CO)); //inverted data port D
    wire [3:0] AA106_S;
    wire AA106_CO;
    A4H_DLY aa106 (.A({Y131_Q[0],Y131_Q[1],Y131_Q[2],Y131_Q[3]}),.B({4{AA91}}), .CI(CC107_CO), .S(AA106_S), .CO(AA106_CO)); //inverted data port D
    wire AA98_S;
    A1N_DLY aa98 (.A(AA81_Q),.B(AA91), .CI(AA106_CO), .S(AA98_S)); //.B(FLIP_SCREEN)

    wire CC103; //Logic Cell X2B
    assign #3.50 CC103 = AA91 ^ CC107_S[0]; //FLIP_SCREEN ^ CC107_S[0]
    wire AA93; //Logic Cell X2B
    assign #3.50 AA93 = AA91 ^ CC107_S[1]; //FLIP_SCREEN ^ CC107_S[1]
    wire BB103; //Logic Cell X2B
    assign #3.50 BB103 = AA91 ^ CC107_S[2]; //FLIP_SCREEN ^ CC107_S[2]

    wire W99_S;
    wire W99_CO;
    A1N_DLY w99 (.A(PXH0),.B(CC103), .CI(1'b0), .S(W99_S), .CO(W99_CO));
    assign ZB1H = W99_S; //*** OUTPUT SIGNAL ZB1H ***

    wire [1:0] W81_S;
    A2N_DLY w81 (.A({PXH2,PXH1}),.B({BB103,AA93}), .CI(W99_CO), .S(W81_S));
    assign {ZB4H,ZB2H} = W81_S; //*** OUTPUT SIGNALS ZB4H, ZB2H ***

    wire [10:0] MAP_B; //*** declare bus for MAP_B signals ***
    wire [3:0] Z77_S;
    wire Z77_CO;
    A4H_DLY z77 (.A({AA106_S[2:0],CC107_S[3]}),.B({PXH6,PXH5,PXH4F,PXH3F}), .CI(1'b0), .S(Z77_S), .CO(Z77_CO));
    wire [1:0] Z137_S;
    A2N_DLY z137 (.A({AA98_S,AA106_S[3]}),.B({PXH8,PXH7}), .CI(Z77_CO), .S(Z137_S));
    
    assign MAP_B[5:0] = {Z137_S,Z77_S};
    //* END Section 6.1. Layer B Tilemap X Address generetor signals *

    //* START Section 6.2. Layer B Tilemap Y Address generetor signals *
    wire M28; //Logic Cell V1N
    assign #0.55 M28 = ~REG1C80[5];

    wire BB34; //Logic Cell N2P
    assign #1.41 BB34 = BB33 & M28;

    wire BB37; //Logic Cell R2N
    assign #0.87 BB37 = ~(PXH2 | BB34);

    wire C22; //Logic Cell N2P
    assign #1.41 C22 = BB37 & RES_SYNCn;

    wire CC3_Qn;
    FDE_DLY cc3 (.D(1'b1), .CLn(C22), .CK(PXH1), .Qn(CC3_Qn));

    wire CC37_X;
    D24_DLY cc37 (.A1(CC3_Qn), .A2(TEST_EN2n), .B1(AB3_REG), .B2(TEST_EN), .X(CC37_X));

    wire [3:0] BB77_Q;
    FDR_DLY bb77 (.D({VD_IN[0],VD_IN[1],VD_IN[2],VD_IN[3]}), .CLn(RES_SYNCn), .CK(CC37_X), .Q(BB77_Q)); //inverted data port D
    
    wire [3:0] V77_Q;
    FDR_DLY v77 (.D({VD_IN[4],VD_IN[5],VD_IN[6],VD_IN[7]}), .CLn(RES_SYNCn), .CK(CC37_X), .Q(V77_Q)); //inverted data port D

    wire [3:0] BB107_S;
    wire BB107_CO;
    A4H_DLY bb107 (.A({BB77_Q[0],BB77_Q[1],BB77_Q[2],BB77_Q[3]}) ,.B(ROW[3:0]), .CI(1'b0), .S(BB107_S), .CO(BB107_CO)); //inverted port A

    wire [3:0] X107_S;
    A4H_DLY x107 (.A({V77_Q[0],V77_Q[1],V77_Q[2],V77_Q[3]}),.B(ROW[7:4]), .CI(BB107_CO), .S(X107_S)); //inverted port A
    
    assign MAP_B[10:6] = {X107_S,BB107_S[3]};
    
    wire [2:0] ROW_B; //*** declare bus for ROW_B signals ***
    assign ROW_B = BB107_S[2:0];
    //* END Section 6.2. Layer B Tilemap Y Address generetor signals *


    //*** PAGE 7: COL OUTPUTS ***
    //* START Section 7.1. col[1:0] Signals *
    wire F130; //Logic Cell N3P
    assign #1.82 F130 = J121 & REG1C00[5] & PXH0n;

    wire [3:0] H127_Q;
    FDS_DLY h127 (.D({VD_IN[8],VD_IN[9],VD_IN[10],VD_IN[11]}), .CK(J140_Qn), .Q(H127_Q));

    wire [3:0] G136_Q;
    FDS_DLY g136 (.D({VD_IN[8],VD_IN[9],VD_IN[10],VD_IN[11]}), .CK(PXH0n), .Q(G136_Q));

    wire F126; //Logic Cell K1B
    assign #1.26 F126 = RMRD;

    wire F128; //Logic Cell K1B
    assign #1.26 F128 = F130;

    wire G100; //Logic Cell V2B
    assign #0.64 G100 = ~F128;

    wire G133; //Logic Cell V2B
    assign #0.64 G133 = ~F126;

    wire F147; //Logic Cell V1N
    assign #0.55 F147 = ~F128;

    wire F144_Xn;
    T2B_DLY f144 (.A(H127_Q[0]), .B(G136_Q[0]), .S1n(F128), .S2(F147), .Xn(F144_Xn));
    wire F24; //Logic Cell V1N
    assign #0.55 F24 = ~F144_Xn;

    wire F142_Xn;
    T2B_DLY f142 (.A(H127_Q[1]), .B(G136_Q[1]), .S1n(F128), .S2(F147), .Xn(F142_Xn));
    wire F41; //Logic Cell V1N
    assign #0.55 F41 = ~F142_Xn;

    wire G122_Xn;
    T5A_DLY g122 (.A1(G136_Q[2]), .A2(H127_Q[2]), .B1(E77_Q[2]), .B2(E77_Q[2]), .S1n(F128), .S2(G100), .S3n(G100), .S4(F128), .S5n(F126), .S6(G133), .Xn(G122_Xn));
    wire F125; //Logic Cell V1N
    assign #0.55 F125 = ~G122_Xn;
    assign COL[1] = F125; //*** OUTPUT SIGNAL COL[1] ***
    
    wire G127_Xn;
    T5A_DLY g127 (.A1(G136_Q[3]), .A2(H127_Q[3]), .B1(E77_Q[3]), .B2(E77_Q[3]), .S1n(F128), .S2(G100), .S3n(G100), .S4(F128), .S5n(F126), .S6(G133), .Xn(G127_Xn));
    wire F141; //Logic Cell V1N
    assign #0.55 F141 = ~G127_Xn;
    assign COL[0] = F141; //*** OUTPUT SIGNAL COL[0] ***
    //* END Section 7.1. col[1:0] Signals *

    //* START Section 7.2. col[3:2], CAB1, CAB2 Signals *
    wire B14; //Logic Cell K2B
    assign #1.83 B14 = F41;
    wire B13; //Logic Cell V2B
    assign #0.64 B13 = ~F41;

    wire A35; //Logic Cell V1N
    assign #0.55 A35 = ~F24;
    wire A31; //Logic Cell K2B
    assign #1.83 A31 = F24;

    wire C74; //Logic Cell V1N
    assign #0.55 C74 = ~REG1C00[5];

    wire [3:0] E77_Q;
    FDR_DLY e77 (.D({DB_BUF[0],DB_BUF[1],DB_BUF[2],DB_BUF[3]}), .CLn(RES_SYNCn), .CK(REG_1E00_WRn), .Q(E77_Q));

    wire E149; //Logic Cell V1N
    assign #0.55 E149 = ~RMRD;

    //COL2
    wire B3_X;
    T34_DLY b3 (.A1(REG1D80[0]), .A2(A35), .A3(B13), .B1(REG1D80[4]), .B2(A35), .B3(B14), .C1(REG1F00[0]), .C2(A31), .C3(B13), .D1(REG1F00[4]), .D2(A31), .D3(B14), .X(B3_X));
    
    wire C36; //Logic Cell V1N
    assign #0.55 C36 = ~B3_X;
    
    wire C29_X;
    D24_DLY c29 (.A1(C36), .A2(C74), .B1(B14), .B2(REG1C00[6]), .X(C29_X));
    
    wire E150; //Logic Cell V2B
    assign #0.64 E150 = ~C29_X;
    
    wire E145_Xn;
    T2B_DLY e145 (.A(E77_Q[1]), .B(E150), .S1n(RMRD), .S2(E149), .Xn(E145_Xn));
    
    wire F149; //Logic Cell V1N
    assign #0.55 F149 = ~E145_Xn;
    assign COL[2] = F149; //*** OUTPUT SIGNAL COL[2] ***
    //COL3
    wire B19_X;
    T34_DLY b19 (.A1(REG1D80[1]), .A2(A35), .A3(B13), .B1(REG1D80[5]), .B2(A35), .B3(B14), .C1(REG1F00[1]), .C2(A31), .C3(B13), .D1(REG1F00[5]), .D2(A31), .D3(B14), .X(B19_X));
    
    wire B39; //Logic Cell V1N
    assign #0.55 B39 = ~B19_X;
    
    wire C75_X;
    D24_DLY c75 (.A1(B39), .A2(C74), .B1(A31), .B2(REG1C00[6]), .X(C75_X));
    
    wire C155; //Logic Cell V2B
    assign #0.64 C155 = ~C75_X;
    
    wire E141_Xn;
    T2B_DLY e141 (.A(E77_Q[0]), .B(C155), .S1n(RMRD), .S2(E149), .Xn(E141_Xn));
    
    wire H124; //Logic Cell V1N
    assign #0.55 H124 = ~E141_Xn;
    assign COL[3] = H124; //*** OUTPUT SIGNAL COL[3] ***
    //CAB1
    wire B40_X;
    T34_DLY b40 (.A1(REG1D80[2]), .A2(A35), .A3(B13), .B1(REG1D80[6]), .B2(A35), .B3(B14), .C1(REG1F00[2]), .C2(A31), .C3(B13), .D1(REG1F00[6]), .D2(A31), .D3(B14), .X(B40_X));
    
    wire A38; //Logic Cell V1N
    assign #0.55 A38 = ~B40_X;
    assign CAB1 = A38; //*** OUTPUT SIGNAL CAB1 ***
    //CAB2
    wire B28_X;
    T34_DLY b28 (.A1(REG1D80[3]), .A2(A35), .A3(B13), .B1(REG1D80[7]), .B2(A35), .B3(B14), .C1(REG1F00[3]), .C2(A31), .C3(B13), .D1(REG1F00[7]), .D2(A31), .D3(B14), .X(B28_X));
    
    wire A48; //Logic Cell V1N
    assign #0.55 A48 = ~B28_X;
    assign CAB2 = A48; //*** OUTPUT SIGNAL CAB2 ***
    //* END Section 7.2. col[3:2], CAB1, CAB2 Signals *

    //* START Section 7.3. col[7:4] *
    wire [3:0] G77_Q;
    FDS_DLY g77 (.D({VD_IN[12],VD_IN[13],VD_IN[14],VD_IN[15]}), .CK(PXH0n), .Q(G77_Q));
    wire [3:0] H92_Q;
    FDS_DLY h92 (.D({VD_IN[12],VD_IN[13],VD_IN[14],VD_IN[15]}), .CK(J140_Qn), .Q(H92_Q));
    wire [3:0] F77_Q;
    FDS_DLY f77 (.D({DB_BUF[4],DB_BUF[5],DB_BUF[6],DB_BUF[7]}), .CK(REG_1E00_WRn), .Q(F77_Q));

    //COL[7]
    wire G101_Xn;
    T5A_DLY g101 (.A1(G77_Q[0]), .A2(H92_Q[0]), .B1(F77_Q[0]), .B2(F77_Q[0]), .S1n(F128), .S2(G100), .S3n(G100), .S4(F128), .S5n(F126), .S6(G133), .Xn(G101_Xn));
    wire L140; //Logic Cell V1N
    assign #0.55 L140 = ~G101_Xn;
    assign COL[7] = L140;
    //COL[6]
    wire G106_Xn;
    T5A_DLY g106 (.A1(G77_Q[1]), .A2(H92_Q[1]), .B1(F77_Q[1]), .B2(F77_Q[1]), .S1n(F128), .S2(G100), .S3n(G100), .S4(F128), .S5n(F126), .S6(G133), .Xn(G106_Xn));
    wire L142; //Logic Cell V1N
    assign #0.55 L142 = ~G106_Xn;
    assign COL[6] = L142;
    //COL[5]
    wire G117_Xn;
    T5A_DLY g117 (.A1(G77_Q[2]), .A2(H92_Q[2]), .B1(F77_Q[2]), .B2(F77_Q[2]), .S1n(F128), .S2(G100), .S3n(G100), .S4(F128), .S5n(F126), .S6(G133), .Xn(G117_Xn));
    wire J150; //Logic Cell V1N
    assign #0.55 J150 = ~G117_Xn;
    assign COL[5] = J150;
    //COL[4]
    wire G111_Xn;
    T5A_DLY g111 (.A1(G77_Q[2]), .A2(H92_Q[2]), .B1(F77_Q[2]), .B2(F77_Q[2]), .S1n(F128), .S2(G100), .S3n(G100), .S4(F128), .S5n(F126), .S6(G133), .Xn(G111_Xn));
    wire J148; //Logic Cell V1N
    assign #0.55 J148 = ~G111_Xn;
    assign COL[4] = J148;
    //* END Section 7.3. col[7:4]

    //* START Section 7.4. BB33 Signal *
    wire AA14; //Logic Cell V1N
    assign #0.55 AA14 = ~PXH6;

    wire AA16; //Logic Cell V1N
    assign #0.55 AA16 = ~PXH5;

    wire AA32; //Logic Cell R6B
    assign #3.80 AA32 = ~(PXH8 | PXH7 | AA14 | AA16 | PXH4F | PXH3);

    wire BB33; //Logic Cell V1N
    assign #0.55 BB33 = ~AA32;
    //* END Section 7.4. BB33 Signal *

    //* START Section 7.5. Scroll RAM read triggers *
    wire X57; //Logic Cell R8B
    assign #4.81 X57 = ~(ROW[0] | ROW[4] | ROW[3] | ROW[2] | ROW[1] | ROW[7] | ROW[6] | ROW[5]);

    wire F8; //Logic Cell R2P
    assign #1.97 F8 = REG1C80[4] | X57;
    
    wire F25; //Logic Cell R2P
    assign #1.97 F25 = REG1C80[1] | X57;
    
    wire F7; //Logic Cell V1N
    assign #0.55 F7 = ~G4_Q;
    
    wire F14; //Logic Cell V1N
    assign #0.55 F14 = ~G29_Q[0]; //G29_QA
    
    wire F10; //Logic Cell N4P
    assign #2.15 F10 = F7 & F14 & F8 & RES_SYNCn;
    
    wire F36; //Logic Cell N4P
    assign #2.15 F36 = F7 & G29_Q[0] & F25 & RES_SYNCn;
    
    wire READ_SCROLL_B;
    assign READ_SCROLL_B = F10; //*** TO 6.1 Layer B Tilemap X address Gen.
    
    wire READ_SCROLL_A;
    assign READ_SCROLL_A = F36; //*** TO 8.1 Layer A Tilemap X address Gen.
    //* END Section 7.5. Scroll RAM read triggers *


    //*** PAGE 8: LAYER A SCROLL ***
    //* START Section 8.1. Layer A Tilemap X Address generetor signals *
    wire AA2_Q;
    FDN_DLY aa2 (.D(PXH3), .Sn(READ_SCROLL_A), .CK(PXH1), .Q(AA2_Q));
    wire X55_X;
    D24_DLY x55 (.A1(AA2_Q), .A2(TEST_ENn), .B1(AB1_REG), .B2(TEST_EN), .X(X55_X));

    wire AA22_Qn;
    FDE_DLY aa22 (.D(PXH3), .CLn(READ_SCROLL_A), .CK(PXH1), .Qn(AA22_Qn));
    wire AA53_X;
    D24_DLY aa53 (.A1(AA22_Qn), .A2(TEST_EN2n), .B1(AB2_REG), .B2(TEST_EN), .X(AA53_X));

    wire [3:0] T51_Q;
    FDR_DLY t51 (.D({VD_IN[8],VD_IN[9],VD_IN[10],VD_IN[11]}), .CLn(RES_SYNCn), .CK(X55_X), .Q(T51_Q)); //inverted data port D
    wire [3:0] S51_Q;
    FDR_DLY s51 (.D({VD_IN[12],VD_IN[13],VD_IN[14],VD_IN[15]}), .CLn(RES_SYNCn), .CK(X55_X), .Q(S51_Q)); //inverted data port D

    wire AA41_Qn;
    FDE_DLY aa41 (.D(VD_IN[8]), .CLn(RES_SYNCn), .CK(AA53_X), .Q(AA41_Qn));

    wire [3:0] X4_S;
    wire X4_CO;
    A4H_DLY x4 (.A({{T51_Q[0],T51_Q[1],T51_Q[2],T51_Q[3]}}),.B({FLIP_SCREEN_BUF,1'b0,{2{FLIP_SCREEN_BUF}}}), .CI(1'b0), .S(X4_S), .CO(X4_CO)); //inverted data port D
    wire [3:0] W3_S;
    wire W3_CO;
    A4H_DLY w3 (.A({S51_Q[0],S51_Q[1],S51_Q[2],S51_Q[3]}),.B({4{FLIP_SCREEN_BUF}}), .CI(X4_CO), .S(W3_S), .CO(W3_CO)); //inverted data port D
    wire Z69_S;
    A1N_DLY z69 (.A(AA41_Qn),.B(FLIP_SCREEN_BUF), .CI(W3_CO), .S(Z69_S)); //.B(FLIP_SCREEN)

    wire X73; //Logic Cell X2B
    assign #3.50 X73 = FLIP_SCREEN_BUF ^ X4_S[0]; //FLIP_SCREEN ^ X4_S[0]
    wire X65; //Logic Cell X2B
    assign #3.50 X65 = FLIP_SCREEN_BUF ^ X4_S[1]; //FLIP_SCREEN ^ X4_S[1]
    wire X69; //Logic Cell X2B
    assign #3.50 X69 = FLIP_SCREEN_BUF ^ X4_S[2]; //FLIP_SCREEN ^ X4_S[2]

    wire W53_S;
    wire W53_CO;
    A1N_DLY w53 (.A(PXH0),.B(X73), .CI(1'b0), .S(W53_S), .CO(W53_CO));
    assign ZA1H = W53_S; //*** OUTPUT SIGNAL ZA1H ***

    wire [1:0] W61_S;
    A2N_DLY w61 (.A({PXH2,PXH1}),.B({X69,X65}), .CI(W99_CO), .S(W61_S));
    assign {ZA4H,ZA2H} = W61_S; //*** OUTPUT SIGNALS ZA4H, ZA2H ***

    wire [10:0] MAP_A; //*** declare bus for MAP_A signals ***
    wire [3:0] Y3_S;
    wire Y3_CO;
    A4H_DLY y3 (.A({W3_S[2:0],X4_S[3]}),.B({PXH6,PXH5,PXH4F,PXH3F}), .CI(1'b0), .S(Y3_S), .CO(Y3_CO));
    wire [1:0] Y53_S;
    A2N_DLY y53 (.A({Z69_S,W3_S[3]}),.B({PXH8,PXH7}), .CI(Y3_CO), .S(Y53_S));
    
    assign MAP_A[5:0] = {Y53_S,Y3_S};
    //* END Section 8.1. Layer A Tilemap X Address generetor signals *

    //* START Section 8.2. Layer A Tilemap Y Address generetor signals *
    wire M49; //Logic Cell V1N
    assign #0.55 M49 = ~REG1C80[2];

    wire BB56; //Logic Cell N2P
    assign #1.41 BB56 = BB33 & M49;

    wire BB55; //Logic Cell R2N
    assign #0.87 BB55 = ~(PXH2 | BB56);

    wire BB30; //Logic Cell N2P
    assign #1.41 BB30 = BB55 & RES_SYNCn;

    wire BB20_Qn;
    FDE_DLY bb20 (.D(1'b1), .CLn(BB30), .CK(PXH1), .Qn(BB20_Qn));

    wire AA55_X;
    D24_DLY aa55 (.A1(BB20_Qn), .A2(TEST_ENn), .B1(AB3_REG), .B2(TEST_EN), .X(AA55_X));

    wire [3:0] T77_Q;
    FDR_DLY t77 (.D({VD_IN[8],VD_IN[9],VD_IN[10],VD_IN[11]}), .CLn(RES_SYNCn), .CK(AA55_X), .Q(T77_Q)); //inverted data port D
    
    wire [3:0] P77_Q;
    FDR_DLY p77 (.D({VD_IN[12],VD_IN[13],VD_IN[14],VD_IN[15]}), .CLn(RES_SYNCn), .CK(AA55_X), .Q(P77_Q)); //inverted data port D

    wire [3:0] W107_S;
    wire W107_CO;
    A4H_DLY w107 (.A({T77_Q[0],T77_Q[1],T77_Q[2],T77_Q[3]}) ,.B(ROW[3:0]), .CI(1'b0), .S(W107_S), .CO(W107_CO)); //inverted port A

    wire [3:0] V106_S;
    A4H_DLY v106 (.A({P77_Q[0],P77_Q[1],P77_Q[2],P77_Q[3]}),.B(ROW[7:4]), .CI(W107_CO), .S(V106_S)); //inverted port A
    
    assign MAP_A[10:6] = {V106_S,W107_S[3]};
    
    wire [2:0] ROW_A; //*** declare bus for ROW_A signals ***
    assign ROW_A = W107_S[2:0];
    //* END Section 8.2. Layer A Tilemap Y Address generetor signals *
endmodule