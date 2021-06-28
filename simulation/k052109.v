/*****************************************************************
 * Verilog simulation module of the k052109 Tile Layer Generator *
 * Based on @Furrtek schematics on 051962 die tracing:           *
 * https://github.com/furrtek/VGChips/tree/master/Konami/052109  *
 * Author: @RndMnkIII                                            *
 * Repository: https://github.com/RndMnkIII/k052109_verilog      *
 * Version: 1.0 28/06/2021                                       *
 ****************************************************************/

`default_nettype none
`timescale 1ns/10ps

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
    output wire [10:0] VC,
    output wire [1:0] CAB, //ROMBANK SELECTORS

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
    output wire [7:0] COL,
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
                Y129=ROW5; Y78=ROW6; Y91=ROW7; Y80=1'b1; 
            end     
            2'bx0: begin
                Y129=1'b0; Y78=1'b0; Y91=1'b0; Y80=1'b0; 
            end 
        endcase
    end
    */
    wire Y69_X;
    D24_DLY y69 (.A1(ROW5), .A2(AA38), .B1(1'b0), .B2(AA58), .X(Y69_X));
    wire Y129; //Logic Cell V1N
    assign #0.55 Y129 = ~Y69_X;

    wire Y71_X;
    D24_DLY y71 (.A1(ROW6), .A2(AA38), .B1(1'b0), .B2(AA58), .X(Y71_X));
    wire Y78; //Logic Cell V1N
    assign #0.55 Y78 = ~Y71_X;

    wire Y73_X;
    D24_DLY y73 (.A1(ROW7), .A2(AA38), .B1(1'b0), .B2(AA58), .X(Y73_X));
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

    ADRR_SEL ra_0 (.A1(SCROLL_RAM_A0), .A2(MAP_A0), .B1(PXH3F), .B2(MAP_B0), .C(AB[0]),  .SELA(N16_QA_BUF), .SELAn(N16_QA_BUFn), .SELB(N16_QB_BUF), .SELBn(N16_QB_BUFn), .SELC(R113), .SELCn(R117), .RA(RA[0]));
    ADRR_SEL ra_1 (.A1(SCROLL_RAM_A1), .A2(MAP_A1), .B1(PXH4F), .B2(MAP_B1), .C(AB[1]),  .SELA(N16_QA_BUF), .SELAn(N16_QA_BUFn), .SELB(N16_QB_BUF), .SELBn(N16_QB_BUFn), .SELC(R113), .SELCn(R117), .RA(RA[1]));
    ADRR_SEL ra_2 (.A1(SCROLL_RAM_A2), .A2(MAP_A2), .B1(PXH5),  .B2(MAP_B2), .C(AB[2]),  .SELA(N16_QA_BUF), .SELAn(N16_QA_BUFn), .SELB(N16_QB_BUF), .SELBn(N16_QB_BUFn), .SELC(R113), .SELCn(R117), .RA(RA[2]));
    ADRR_SEL ra_3 (.A1(SCROLL_RAM_A3), .A2(MAP_A3), .B1(PXH6),  .B2(MAP_B3), .C(AB[3]),  .SELA(N16_QA_BUF), .SELAn(N16_QA_BUFn), .SELB(N16_QB_BUF), .SELBn(N16_QB_BUFn), .SELC(R113), .SELCn(R117), .RA(RA[3]));
    ADRR_SEL ra_4 (.A1(SCROLL_RAM_A4), .A2(MAP_A4), .B1(PXH7),  .B2(MAP_B4), .C(AB[4]),  .SELA(N16_QA_BUF), .SELAn(N16_QA_BUFn), .SELB(N16_QB_BUF), .SELBn(N16_QB_BUFn), .SELC(R113), .SELCn(R117), .RA(RA[4]));
    ADRR_SEL ra_5 (.A1(SCROLL_RAM_A5), .A2(MAP_A5), .B1(PXH8),  .B2(MAP_B5), .C(AB[5]),  .SELA(N16_QA_BUF), .SELAn(N16_QA_BUFn), .SELB(N16_QB_BUF), .SELBn(N16_QB_BUFn), .SELC(R113), .SELCn(R117), .RA(RA[5]));
    ADRR_SEL ra_6 (.A1(Y129),          .A2(MAP_A6), .B1(ROW3),  .B2(MAP_B6), .C(AB[6]),  .SELA(N16_QA_BUF), .SELAn(N16_QA_BUFn), .SELB(N16_QB_BUF), .SELBn(N16_QB_BUFn), .SELC(R113), .SELCn(R117), .RA(RA[6]));
    //----------------BUF2
    ADRR_SEL ra_7 (.A1(Y78),           .A2(MAP_A7), .B1(ROW4),  .B2(MAP_B7), .C(AB[7]),  .SELA(N16_QA_BUF), .SELAn(N16_QA_BUF2n), .SELB(N16_QB_BUF), .SELBn(N16_QB_BUF2n), .SELC(R113), .SELCn(R117), .RA(RA[7]));
    ADRR_SEL ra_8 (.A1(Y91),           .A2(MAP_A8), .B1(ROW5),  .B2(MAP_B8), .C(AB[8]),  .SELA(N16_QA_BUF), .SELAn(N16_QA_BUF2n), .SELB(N16_QB_BUF), .SELBn(N16_QB_BUF2n), .SELC(R113), .SELCn(R117), .RA(RA[8]));
    ADRR_SEL ra_9 (.A1(Y80),           .A2(MAP_A9), .B1(ROW6),  .B2(MAP_B9), .C(AB[9]),  .SELA(N16_QA_BUF), .SELAn(N16_QA_BUF2n), .SELB(N16_QB_BUF), .SELBn(N16_QB_BUF2n), .SELC(R113), .SELCn(R117), .RA(RA[9]));
    ADRR_SEL ra_A (.A1(1'b0),          .A2(MAP_A10),.B1(ROW7),  .B2(MAP_B10),.C(AB[10]), .SELA(N16_QA_BUF), .SELAn(N16_QA_BUF2n), .SELB(N16_QB_BUF), .SELBn(N16_QB_BUF2n), .SELC(R113), .SELCn(R117), .RA(RA[10]));
    ADRR_SEL ra_B (.A1(1'b1),          .A2(1'b1),   .B1(1'b0),  .B2(1'b0),   .C(AB[11]), .SELA(N16_QA_BUF), .SELAn(N16_QA_BUF2n), .SELB(N16_QB_BUF), .SELBn(N16_QB_BUF2n), .SELC(R113), .SELCn(R117), .RA(RA[11]));
    ADRR_SEL ra_C (.A1(1'b1),          .A2(1'b0),   .B1(1'b0),  .B2(1'b1),   .C(AB[12]), .SELA(N16_QA_BUF), .SELAn(N16_QA_BUF2n), .SELB(N16_QB_BUF), .SELBn(N16_QB_BUF2n), .SELC(R113), .SELCn(R117), .RA(RA[12]));

    ADRR_SEL2 roe_0(.A(RDEN), .B(J140_Qn), .SELC(R113)), .SELCn(R117), .VRAM_OE_CS(ROE[0]));
    ADRR_SEL2 roe_1(.A(RDEN), .B(J151), .SELC(R113)), .SELCn(R117), .VRAM_OE_CS(ROE[1]));
    ADRR_SEL2 roe_2(.A(RDEN), .B(1'b1), .SELC(R113)), .SELCn(R117), .VRAM_OE_CS(ROE[2]));
    ADRR_SEL2 rcs_0(.A(CPU_VRAM_CS0), .B(1'b0), .SELC(R113)), .SELCn(R117), .VRAM_OE_CS(RCS[0]));
    ADRR_SEL2 rcs_1(.A(CPU_VRAM_CS1), .B(1'b0), .SELC(R113)), .SELCn(R117), .VRAM_OE_CS(RCS[1]));
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
    FDO_DLY k130(.D(J94_Qn),.Rn(RES_SYNC3n), .CK(M24), .Q(K123_Q), .Qn(K123_Qn));

    wire K119; //Logic Cell N3N
    assign #0.83 K119 = ~(NRD & K123_Qn & K130_Q);
    
    wire K114; //Logic Cell N3N
    assign #0.83 K114 = ~(NRD & K117 & K123_Qn);

    wire K121; //Logic Cell N2P
    assign #1.41 K121 = (NRD & K123_Q);

    wire [3:0] K77_Q;
    FDR_DLY k77( .D({K121, K114, K119, K117}), .CLn(RES_SYNC3n), .CK(M24), .Q(K77_Q));

    wire K110; //Logic Cell K1B
    assign #1.26 K110 = k77_Q[0];
    assign PQ = K110; //*** OUTPUT SIGNAL PQ ***

    wire K72; //Logic Cell K1B
    assign #1.26 K72 = k77_Q[1];
    assign WRP = K72; //*** OUTPUT SIGNAL WRP ***

    wire K55; //Logic Cell K1B
    assign #1.26 K55 = k77_Q[2];
    assign WREN = K55; //*** OUTPUT SIGNAL WREN ***

    wire K112; //Logic Cell K1B
    assign #1.26 K112 = k77_Q[3];
    assign RDEN = K112; //*** OUTPUT SIGNAL RDEN ***
    //* END Section 2.1. Timings signals *

    //* START Section 2.2. More timings signals *
    wire K141_Q, K141_Qn;
    FDN_DLY k141(.D(K141_Qn), .Sn(RES_SYNC3n), .CK(M24), .Q(K141_Q), .Qn(K141_Qn));

    wire J110; //Logic Cell X2B
    assign #3.50 J110 = K141_Qn ^ J114_Qn;

    wire J114_Q, J114_Qn;
    FDN_DLY j114(.D(J110), .Sn(RES_SYNC3n), .CK(M24), .Q(K141_Q), .Qn(K141_Qn));

    wire M15; //Logic Cell K1B
    assign #1.26 M15 = K141_Q;
    assign M12 = M15; //*** OUTPUT SIGNAL M12 ***

    wire M12n;
    assign M12n = K141_Qn;

    wire J109; //Logic Cell N2N
    assign #0.71 J109 = ~(K141_Qn & J114_Qn);

    wire J121; //Logic Cell KCB
    assign #3.31 J121 = J114_Q; //*** CLOCK TREE J121 ***

    wire J101; //Logic Cell X2B
    assign #3.50 J101 = (J109 ^ J94_Q)

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
    assign #0.55 L82 = ~ L78;

    wire L119; //Logic Cell V1N
    assign #0.55 L119 = ~ CRCS;

    wire L83; //Logic Cell N3P
    assign #1.82 L83 = L78 & L119 & PQ;

    wire C92; //R2N
    assign #0.87 C92 = ~(L83 | €REG1C00_D5);
    
    //----------------------------------------------------------------------
    
    wire J140_Q, J140_Qn;
    FDO_DLY j140(.D(J121), .Rn(RES_SYNC3n), .CK(M12n), .Q(J140_Q), .Qn(J140_Qn));

    wire J151; //Logic Cell N2P
    assign #1.41 J151 = €REG1C00_D5 & J140_Q;

    wire H78; //Logic Cell V1N
    assign #0.55 H78 = ~PQ;

    wire H79_Q;
    FDO_DLY h79(.D(H78), .Rn(J79), .CK(J121), .Q(H79_Q));

    wire E143; //Logic Cell R2P
    assign #1.97 E143 = H79_Q | RMRD;

    assign VDE = E143; //*** OUTPUT SIGNAL VDE ***
    //* END Section 2.2. More timings signals *


    //*** PAGE 3: CPU Stuff ***
    //* START Section 3.1. Reset synchronizer signals *
    wire N122_Q, RES_SYNC3n;
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
    wire [3.0] P51_Q;
    FDR_DLY p51(.D({P51_Q[2],P51_Q[1],P51_Q[0],RES_SYNC3n}), .CLn(RES_SYNC3n), .CK(TRIG_IRQ), .Q(P51_Q));

    wire [3.0] P18_Q;
    FDR_DLY p18(.D({P18_Q[2],P18_Q[1],P18_Q[0],P51_Q[3]}), .CLn(RES_SYNC3n), .CK(TRIG_IRQ), .Q(P18_Q));

    assign RST = P18_Q[3]; //*** OUTPUT SIGNAL RST ***
    //* END Section 3.2. Reset delayed signal *

    //* START Section 3.3. Buffered,inverted and ANDed signals *
    wire AB9n, AB9_BUF; //Logic Cell V1N 0.55//AB9_INV
    wire AB8n, AB8_BUF; //Logic Cell V1N 0.55//AB8_INV
    wire AB7n, AB7_BUF; //Logic Cell V1N 0.55//AB7_INV
    wire RMRDn; //Logic Cell V2B 0.64
    wire RMRD_BUF; //Logic Cell K1B 1.26
    wire AB_18XX; //Logic Cell K3B

    assign #0.55 AB9n = ~AB[9];
    assign #0.55 AB9_BUF = ~AB9n;
    
    assign #0.55 AB8n = ~AB[8];
    assign #0.55 AB8_BUF = ~AB8n;
    
    assign #0.55 AB7n = ~AB[7];
    assign #0.55 AB7_BUF = ~AB7n;

    assign #1.26 RMRDn = ~RMRD;
    assign #0.64 RMRD_BUF = RMRD;

    assign #1.45 AB_18xx = AB[12] & AB[12];
    //* END Section 3.3. Buffered,inverted and ANDed signals *

    //* START Section 3.4. Buffered DB_IN[7:0] signals *
    wire [7:0] DB_IN;
    wire [7:0] DB_BUF;
    generate
        genvar i;
        for(i=0; i < 8; i=i+1) begin
            //Logic Cell K2B
            assign #1.83 DB_BUF[i] = DB_IN[i];
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

    //*** PAGE 4: H/V Counters ***
    //* START Section 4.1. HORIZONTAL COUNTER signals *
    wire H20_Q;
    FDO_DLY k148(.D(PQ),.Rn(RES_SYNC2n), .CK(J121), .Q(H20_Q));

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
                .D({3{1'b0},1'b1}));

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
    assign #3.50 PXH3F = €FLIP_SCREEN ^ N16_QC;

    wire PXH4F; //Logic Cell X2B
    assign #3.50 PXH4F = €FLIP_SCREEN ^ N16_QD;

    wire PXH5; //Logic Cell X2B
    assign #3.50 PXH5 = €FLIP_SCREEN ^ G29_Q[0];

    wire PXH6; //Logic Cell X2B
    assign #3.50 PXH6 = €FLIP_SCREEN ^ G29_Q[1];

    wire PXH7; //Logic Cell X2B
    assign #3.50 PXH7 = €FLIP_SCREEN ^ G29_Q[2];  

    wire PXH8; //Logic Cell X2B
    assign #3.50 PXH8 = €FLIP_SCREEN ^ G29_Q[3];    

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
    assign #1.97 H4 = TESTD15 | G20_Q;

    wire [3:0] J29_Q;
    wire J29_CO;
    C43_DLY j29 (.CK(J121),
    .CLn(RES_SYNC2n),
    .Ln(H3),
    .CI(H8),
    .EN(H6),
    .CO(J29_CO),
    .Q(J29_Q),
    .D({2{1'b1},2{1'b0}}));

    wire [3:0] H29_Q;
    wire H29_CO;
    C43_DLY h29 (.CK(J121),
    .CLn(RES_SYNC2n),
    .Ln(H3),
    .CI(J29_CO),
    .EN(H4),
    .CO(H29_CO),
    .Q(H29_Q),
    .D({1'b0,3{1'b1}}));

    wire H3; //Logic Cell V1N
    assign #0.55 H3 = ~H29_CO;

    wire R10; //Logic Cell BD5
    assign #22.18 R10 = H3; //LOOK DEEPER AT THIS, real delay capture HVOT signal
    wire R19; //Logic Cell K1B
    assign #1.26 R19 = R10;

    assign HVOT = R19; //*** OUTPUT SIGNAL HVOT ***

    //--G20--
    wire ROW0; //Logic Cell X2B
    assign #3.50 ROW0 = €FLIP_SCREEN ^ G20_Q;

    //--J29--
    wire ROW1; //Logic Cell X2B
    assign #3.50 ROW1 = €FLIP_SCREEN ^ J29_Q[0]; //QA

    wire ROW2; //Logic Cell X2B
    assign #3.50 ROW2 = €FLIP_SCREEN ^ J29_Q[1]; //QB

    wire ROW3; //Logic Cell2X2B//QC
    assign #3.50 ROW3 = €FLIP_SCREEN ^ J29_Q[2]; //QC

    wire ROW4; //Logic Cell X2B
    assign #3.50 ROW4 = €FLIP_SCREEN ^ J29_Q[3]; //QD

    //--H29--
    wire ROW5; //Logic Cell X2B
    assign #3.50 ROW5 = €FLIP_SCREEN ^ H29_Q[0]; //QA

    wire ROW6; //Logic Cell X2B
    assign #3.50 ROW6 = €FLIP_SCREEN ^ H29_Q[1]; //QB

    wire ROW7; //Logic Cell X2B
    assign #3.50 ROW7 = €FLIP_SCREEN ^ H29_Q[2; //QC

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
    assign #1.83 AA38 = D39; //SECTION 3.9, PAGE 1 Y69

    wire AA58; //Logic Cell V2B
    assign #0.64 AA58 = ~D39; //SECTION 3.9, PAGE 1 Y69
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
    assign #2.83 D12 = ~(€L15 & AB9_INV & AB[10] & AB7_BUF & AB8_BUF & AB_18XX); //L15 FROM SECTION 3.8

    wire [7:0] REG1D80;
    FDR_DLY a5 (.D(DB_BUF[4:7]), .CLn(RES_SYNCn), .CK(D12), .Q(REG1D80[4:7]));
    FDR_DLY c3 (.D(DB_BUF[0:3]), .CLn(RES_SYNCn), .CK(D12), .Q(REG1D80[0:3]));
    //* END Section 5.2. REGISTER 0x1D80 *

    //* START Section 5.3. REGISTER 0x1D00 *
    wire D18; //Logic Cell N6B
    assign #2.83 D18 = ~(€L15 & AB9_INV & AB[10] & AB7_INV & AB8_BUF & AB_18XX); //L15 FROM SECTION 3.8

    wire [3:0] REG1D00;
    FDR_DLY f51 (.D(DB_BUF[0:3]), .CLn(RES_SYNCn), .CK(D18)3 .Q(REG1D00[0:3]));
    //* END Section 5.3. REGISTER 0x1D00 *

    //* START Section 5.4. REGISTER 0x1C00 *
    wire D23; //Logic Cell N6B
    assign #2.83 D23 = ~(€L15 & AB9_INV & AB[10] & AB7_INV & AB8_INV & AB_18XX); //L15 FROM SECTION 3.8

    wire [7:0] REG1C00;
    FDR_DLY c38 (.D(DB_BUF[4:7]), .CLn(RES_SYNCn), .CK(D23), .Q(REG1C00[4:7]));
    FDR_DLY b77 (.D(DB_BUF[0:3]), .CLn(RES_SYNCn), .CK(D23), .Q(REG1C00[0:3]));
    //* END Section 5.4. REGISTER 0x1C00 *

    //* START Section 5.5. REGISTER 0x1C80 *
    wire D7; //Logic Cell N6B
    assign #2.83 D7 = ~(€L15 & AB9_INV & AB[10] & AB7_BUF & AB8_INV & AB_18XX); //L15 FROM SECTION 3.8

    wire [7:0] REG1C80;
    FDR_DLY e4 (.D(DB_BUF[4:7]), .CLn(RES_SYNCn), .CK(D7), .Q(REG1C80[4:7]));
    FDR_DLY e51 (.D(DB_BUF[0:3]), .CLn(RES_SYNCn), .CK(D7), .Q(REG1C80[0:3]));
    //* END Section 5.5. REGISTER 0x1C80 *

    //* START Section 5.6. REGISTER 0x1F00 *
    wire D33; //Logic Cell N6B
    assign #2.83 D33 = ~(€L15 & AB9_BUF & AB[10] & AB7_INV & AB8_BUF & AB_18XX); //L15 FROM SECTION 3.8

    wire [7:0] REG1F00;
    FDR_DLY a51 (.D(DB_BUF[4:7]), .CLn(RES_SYNCn), .CK(D33), .Q(REG1F00[4:7]));
    FDR_DLY b51 (.D(DB_BUF[0:3]), .CLn(RES_SYNCn), .CK(D33), .Q(REG1F00[0:3]));
    //* END Section 5.6. REGISTER 0x1F00 *

    //* START Section 5.7. REGISTER 0x1E80 *
    wire D2; //Logic Cell N6B
    assign #2.83 D2 = ~(€L15 & AB9_BUF & AB[10] & AB7_BUF & AB8_INV & AB_18XX); //L15 FROM SECTION 3.8
    assign BEN = D2; //*** OUTPUT SIGNAL BEN ***
    
    wire M53_Q;
    FDO_DLY m53 (.D(DB_BUF[0]), .Rn(RES_SYNCn), .CK(BEN), .Q(M53_Q));
    wire FLIP_SCREEN; //Logic Cell K2B
    assign #1.83 FLIP_SCREEN = M53_Q;

    wire FLIP_SCREEN_BUF; //Logic Cell K1B
    assign #1.26 FLIP_SCREEN_BUF = FLIP_SCREEN;
    //* END Section 5.7. REGISTER 0x1E80 *

        //* START Section 5.8. REGISTER 0x1E00 *
    wire reg_1E00_WRn; //Logic Cell N6B
    assign #2.83 reg_1E00_WRn = ~(€L15 & AB9_BUF & AB[10] & AB7_INV & AB8_INV & AB_18XX); //L15 FROM SECTION 3.8
    //* END Section 5.8. REGISTER 0x1E00 *
endmodule