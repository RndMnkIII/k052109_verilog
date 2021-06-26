/*****************************************************************
 * Verilog simulation module of the k052109 Tile Layer Generator *
 * Based on @Furrtek schematics on 051962 die tracing:           *
 * https://github.com/furrtek/VGChips/tree/master/Konami/051962  *
 * Author: @RndMnkIII                                            *
 * Repository: https://github.com/RndMnkIII/k052109_verilog      *
 * Version: 1.0 25/06/2021                                       *
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
    assign #3.31 J121 = J114_Q;

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
    FDR_DLY p51(.D({P51_Q[2],P51_Q[1],P51_Q[0],RES_SYNC3n}), .CLn(RES_SYNC3n), .CK(€TRIG_IRQ), .Q(P51_Q));

    wire [3.0] P18_Q;
    FDR_DLY p18(.D({P18_Q[2],P18_Q[1],P18_Q[0],P51_Q[3]}), .CLn(RES_SYNC3n), .CK(€TRIG_IRQ), .Q(P18_Q));

    assign RST = P18_Q[3]; //*** OUTPUT SIGNAL RST ***
    //* END Section 3.2. Reset delayed signal *

    //* START Section 3.3. Buffered,inverted and ANDed signals *
    wire AB9n, AB9_BUF; //Logic Cell V1N 0.55//AB9_INV
    wire AB8n, AB8_BUF; //Logic Cell V1N 0.55//AB8_INV
    wire AB7n, AB7_BUF; //Logic Cell V1N 0.55//AB7_INV
    wire RMRDn; //Logic Cell V2B 0.64
    wire RMRD_BUF; //Logic Cell K1B 1.26
    wire AB_18xx; //Logic Cell K3B

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
    FDN_DLY p4(.D(1'b0), .Sn(€REG1D00_D2), .CK(€TRIG_IRQ), .Q(P4_Q));
    assign IRQ = P4_Q; //*** OUTPUT SIGNAL IRQ ***

    wire F27_Q;
    FDN_DLY f27(.D(1'b0), .Sn(€REG1D00_D1), .CK(€TRIG_FIRQ), .Q(F27_Q));
    assign FIRQ = F27_Q; //*** OUTPUT SIGNAL FIRQ ***

    wire CC52_Q;
    FDN_DLY cc52(.D(1'b0), .Sn(€REG1D00_D0), .CK(€TRIG_NMI), .Q(CC52_Q));
    assign NMI = CC52_Q; //*** OUTPUT SIGNAL NMI ***
    //* END Section 3.5. Interrupt flags signals *

    //*** PAGE 4: H/V Counters ***
    //* START Section 4.1. HORIZONTAL COUNTER signals *
    wire H20_Q;
    FDO_DLY k148(.D(PQ),.Rn(RES_SYNC2n), .CK(J121), .Q(H20_Q));

    wire H15; //Logic Cell R2P
    assign #0.87 H15 = TEST_D15;

    wire PXH0; //Logic Cell K2B
    wire PXH0n; //Logic Cell V1N
    assign #1.83 PXH0 = H20_Q;
    assign #0.55 PXH0n = ~PXH0;

    wire N16_CO;
    wire N16_QD, N16_QC, PXH1, PXH2;
    C43_DLY n16(.CK(J121),
                .CLn(RES_SYNC2n),
                .Ln(LINE_ENDn),
                .CI(H15),
                .EN(H15),
                .CO(N16_CO),
                .Q({N16_QD,N16_QC,PXH2,PXH1}),
                .D({4{1'b0}}));

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

    wire G4_Q;
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
    assign #0.55 LINE_ENDn = 
    //* END Section 4.1. HORIZONTAL COUNTER signals *

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
endmodule