//Test Bench Usage:
//iverilog -o fdo_tb.vvp fdo_tb.v fdos.v
//vvp fdo_tb.vvp -lxt2
//gtkwave fdo_tb.lxt&
`default_nettype none
`timescale 1ns/1ps

module fdo_tb;
  	reg d, rn;
    wire q, qn;

	// Instantiate the Unit Under Test (UUT)
    FDO_DLY uut	(.D(d), .Rn(rn), .CK(clk6), .Q(q), .Qn(qn));

    initial begin
		$dumpfile("fdo_tb.vcd");
		$dumpvars(0,fdo_tb);
	end

    //Clocks
    reg clk3=0;
    always #166.667 clk3= ~clk3;
    reg clk6=0;
    always #83.333 clk6= ~clk6;
    reg clk12=0;
    always #41.667 clk12= ~clk12;
    reg clk24=0;
    always #20.833 clk24= ~clk24;

	initial begin
        //4-bit full adder test
       d=1; rn=0;
       #41.667
       rn=1;
       
		#10.417; x = 4'b0101; y = 4'b0001; cin = 1'b0; // 5+1=6=0110
		#10.417; x = 4'b0101; y = 4'b1110; cin = 1'b1; // 5-1=4=0100
        
        #10.417; x = 4'b1111; y = 4'b0000; cin = 1'b0;
        #10.417; x = 4'b1111; y = 4'b0001; cin = 1'b0;
        #10.417; x = 4'b1111; y = 4'b0010; cin = 1'b0;
        #10.417; x = 4'b1111; y = 4'b0100; cin = 1'b0;
        #10.417; x = 4'b1111; y = 4'b1000; cin = 1'b0;
        
        #10.417; x = 4'b0000; y = 4'b0000; cin = 1'b0;
        #10.417; x = 4'b0000; y = 4'b0001; cin = 1'b0;
        #10.417; x = 4'b0000; y = 4'b0010; cin = 1'b0;
        #10.417; x = 4'b0000; y = 4'b0100; cin = 1'b0;
        #10.417; x = 4'b0000; y = 4'b1000; cin = 1'b0;

        #10.417; x = 4'b0001; y = 4'b0000; cin = 1'b0;
        #10.417; x = 4'b0001; y = 4'b0001; cin = 1'b0;
        #10.417; x = 4'b0001; y = 4'b0010; cin = 1'b0;
        #10.417; x = 4'b0001; y = 4'b0100; cin = 1'b0;
        #10.417; x = 4'b0001; y = 4'b1000; cin = 1'b0;
        
        #10.417; x = 4'b0000; y = 4'b0000; cin = 1'b1;
        #10.417; x = 4'b0000; y = 4'b0001; cin = 1'b1;
        #10.417; x = 4'b0000; y = 4'b0010; cin = 1'b1;
        #10.417; x = 4'b0000; y = 4'b0100; cin = 1'b1;
        #10.417; x = 4'b0000; y = 4'b1000; cin = 1'b1;

        #10.417; x = 4'b0001; y = 4'b0000; cin = 1'b1;
        #10.417; x = 4'b0001; y = 4'b0001; cin = 1'b1;
        #10.417; x = 4'b0001; y = 4'b0010; cin = 1'b1;
        #10.417; x = 4'b0001; y = 4'b0100; cin = 1'b1;
        #10.417; x = 4'b0001; y = 4'b1000; cin = 1'b1;

		#10.417; x = 0; y = 0; cin = 0;
        #20.833;

        //2-bit full adder test
        x2 = 0; y2 = 0; cin = 0;
        #10.417; x2 = 4'b00; y2 = 4'b00; cin = 1'b0;
		#10.417; x2 = 4'b11; y2 = 4'b00; cin = 1'b0;
        #10.417; x2 = 4'b00; y2 = 4'b11; cin = 1'b0;
		#10.417; x2 = 4'b01; y2 = 4'b10; cin = 1'b0;
        #10.417; x2 = 4'b10; y2 = 4'b01; cin = 1'b0;
		#10.417; x2 = 4'b11; y2 = 4'b11; cin = 1'b0;
        #10.417; x2 = 4'b10; y2 = 4'b10; cin = 1'b0;
		#10.417; x2 = 4'b01; y2 = 4'b01; cin = 1'b0;
        
        #10.417; x2 = 4'b00; y2 = 4'b00; cin = 1'b1;
		#10.417; x2 = 4'b11; y2 = 4'b00; cin = 1'b1;
        #10.417; x2 = 4'b00; y2 = 4'b11; cin = 1'b1;
		#10.417; x2 = 4'b01; y2 = 4'b10; cin = 1'b1;
        #10.417; x2 = 4'b10; y2 = 4'b01; cin = 1'b1;
		#10.417; x2 = 4'b11; y2 = 4'b11; cin = 1'b1;
        #10.417; x2 = 4'b10; y2 = 4'b10; cin = 1'b1;
		#10.417; x2 = 4'b01; y2 = 4'b01; cin = 1'b1;
		
        #10.417; x2 = 0; y2 = 0; cin = 0;
        #50;

        //1-bit full adder test
        x1 = 0; y1 = 0; cin = 0;
        #10.417; x1 = 4'b0; y1 = 4'b0; cin = 1'b0;
        #10.417; x1 = 4'b0; y1 = 4'b1; cin = 1'b0;
        #10.417; x1 = 4'b1; y1 = 4'b0; cin = 1'b0;
        #10.417; x1 = 4'b1; y1 = 4'b1; cin = 1'b0;
        
        #10.417; x1 = 4'b0; y1 = 4'b0; cin = 1'b1;
        #10.417; x1 = 4'b0; y1 = 4'b1; cin = 1'b1;
        #10.417; x1 = 4'b1; y1 = 4'b0; cin = 1'b1;
        #10.417; x1 = 4'b1; y1 = 4'b1; cin = 1'b1;
		#10.417; $finish;
	end
endmodule