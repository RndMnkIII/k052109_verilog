//Test Bench Usage:
//iverilog -o dff_as_tff_tb.vvp dff_as_tff_tb.v fujitsu_AV_UnitCellLibrary_DLY.v
//vvp dff_as_tff_tb.vvp -lxt2
//gtkwave dff_as_tff_tb.lxt&
`default_nettype none
`timescale 1ns/1ps

module dff_as_tff_tb;
    reg reset;
    reg [7:0] REG1C00;
    reg NRD;
    reg RMRD;
    reg CRCS;
    wire res_sync;

	// Instantiate the Unit Under Test (UUT)
    //Reset synchronizer with DFF
    FDE_DLY bb9 (.D(1'b1), .CLn(reset), .CK(clock), .Q(res_sync));

    //Clock divider using DFF
    wire K141_Q, K141_Qn;
    FDN_DLY k141(.D(K141_Qn), .Sn(res_sync), .CK(clock), .Q(K141_Q), .Qn(K141_Qn));
    wire M15; //Logic Cell K1B
    assign #1.26 M15 = K141_Q;

    wire M12;
    assign M12 = M15; //*** OUTPUT SIGNAL M12 *** TWEAKED VALUE: original should be 0ns delay
    wire M12n;
    assign M12n = K141_Qn;

    //This works as T Flip Flop for clock divide.
    wire J114_Q, J114_Qn;
    FDN_DLY j114(.D(J110), .Sn(res_sync), .CK(clock), .Q(J114_Q), .Qn(J114_Qn));
    wire J110;
    assign #3.50 J110 = K141_Qn ^ J114_Q; //k141_Qn, J114_Qn original values
    wire J121;
    assign #1.20 J121 = J114_Qn; // J114_Q original value, #3.31 tweaked to 1.20ns
    

    wire J109;
    assign #0.71 J109 = ~(K141_Qn & J114_Q); //~(K141_Qn & J114_Qn) original values

    //This works as T Flip Flop for clock divide.
    wire J94_Q, J94_Qn;
    FDN_DLY j94(.D(J101), .Sn(res_sync), .CK(clock), .Q(J94_Q), .Qn(J94_Qn));
    wire J101;
    assign #3.50 J101 = J109 ^ J94_Qn; //FIXED, original was J94_Q

    //??
    wire J78;
    assign #0.55 J78 = ~clock;
    wire J79_Q, J79_Qn;
    FDE_DLY j79 (.D(J94_Q), .CLn(res_sync), .CK(J78), .Q(J79_Q), .Qn(J79_Qn)); //FIXED, original was J94_Qn



    wire K117;
    assign #0.55 K117 = ~ J94_Q; //FIXED, original was J94_Qn
    wire L80; //Logic Cell V2B
    assign #0.64 L80 = ~K117;

    wire L78; //Logic Cell V2B
    assign #0.64 L78 = ~L80;

    wire L82; //Logic Cell V1N
    assign #0.55 L82 = ~L78; //** LATCH VRAM DATA  SC. 3.10 **

    wire L119; //Logic Cell V1N
    assign #0.55 L119 = ~CRCS;

    wire L83; //Logic Cell N3P
    assign #1.82 L83 = L78 & L119 & PQ;

    wire C92; //R2N
    assign #0.87 C92 = ~(L83 | REG1C00[5]);




    wire K123_Q, K123_Qn;
    FDO_DLY k123(.D(J94_Q),.Rn(res_sync), .CK(clock), .Q(K123_Q), .Qn(K123_Qn)); //FIXED, original was j94_Qn

    wire K148_Q;
    wire K148_Qn;
    FDO_DLY k148(.D(K123_Q),.Rn(res_sync), .CK(clock), .Q(K148_Q), .Qn(K148_Qn) ); //K123_Q original value

    wire L120_Q;
    wire L120_Qn;
    FDE_DLY l120 (.D(K148_Q), .CLn(res_sync), .CK(clock), .Q(L120_Q), .Qn(L120_Qn)); //K148_Q original value

    wire M13; //Logic Cell K1B
    wire PE; //PE output signal
    assign #1.26 M13 = L120_Q; //L120_Q original value
    assign PE = M13; //*** OUTPUT SIGNAL PE ***

    wire [3:0] K77_Q;
    FDR_DLY k77( .D({1'b0, 1'b0, 1'b0, K117}), .CLn(res_sync), .CK(clock), .Q(K77_Q));

    wire PQ; //PQ output signal
    wire K110; //Logic Cell K1B
    assign #1.26 K110 = K77_Q[0]; //#1.26
    assign PQ = K110; //*** OUTPUT SIGNAL PQ ***


    wire H78; //Logic Cell V1N
    assign #0.55 H78 = ~PQ;

    wire H79_Q;
    FDO_DLY h79(.D(H78), .Rn(J79_Q), .CK(J121), .Q(H79_Q)); //.Rn(J79_Q) original value

    wire E143; //Logic Cell R2P
    assign #1.97 E143 = H79_Q | RMRD;
    wire VDE; //Output signal
    assign VDE = E143;

    wire J140_Q, J140_Qn;
    FDO_DLY j140(.D(J121), .Rn(res_sync), .CK(M12n), .Q(J140_Q), .Qn(J140_Qn));

    wire J151; //Logic Cell N2P
    assign #1.41 J151 = REG1C00[5] & J140_Q;

    initial begin
		$dumpfile("dff_as_tff_tb.lxt");
		$dumpvars(0,dff_as_tff_tb);
	end

    //Clock
    reg clock=0;
    always #20 clock= ~clock;
    //always #20.833 clock= ~clock; //24Mhz clock

	initial begin
        reset = 0; RMRD=0; CRCS=1; REG1C00 = 8'h00; NRD = 0;
        #30;
        reset = 1;
        #190;
        CRCS=0;

        #270;
        REG1C00[5] = 1'b1; //set bit 5 of Register 1C00.
        #1000;
        $finish;
	end
endmodule