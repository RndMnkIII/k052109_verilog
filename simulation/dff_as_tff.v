//Test Bench Usage:
//iverilog -o dff_as_tff_tb.vvp dff_as_tff_tb.v fujitsu_AV_UnitCellLibrary_DLY.v
//vvp dff_as_tff_tb.vvp -lxt2
//gtkwave dff_as_tff_tb.lxt&
`default_nettype none
`timescale 1ns/1ps

module dff_as_tff_tb;
    reg reset;
    wire res_sync;

	// Instantiate the Unit Under Test (UUT)
    //Reset synchronizer with DFF
    FDE_DLY bb9 (.D(1'b1), .CLn(reset), .CK(clock), .Q(res_sync));

    //Clock divider using DFF
    wire K141_Q, K141_Qn;
    FDN_DLY p4(.D(K141_Qn), .Sn(res_sync), .CK(clock), .Q(K141_Q), .Qn(K141_Qn));

    //This works as T Flip Flop for clock divide.
    wire J114_Q, J114_Qn;
    FDN_DLY j114(.D(J110), .Sn(res_sync), .CK(clock), .Q(J114_Q), .Qn(J114_Qn));
    wire J110;
    assign #3.50 J110 = K141_Qn ^ J114_Qn;

    initial begin
		$dumpfile("dff_as_tff_tb.vcd");
		$dumpvars(0,dff_as_tff_tb);
	end

    //Clock
    reg clock=0;
    always #20 clock= ~clock;

	initial begin
        reset = 0;
        #30;
        reset = 1;
        #1000;
        $finish;
	end
endmodule