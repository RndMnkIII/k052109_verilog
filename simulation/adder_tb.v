//Test Bench Usage:
//iverilog -o adder_tb.vvp adder_tb.v adders.v
//vvp adder_tb.vvp -lxt2
//gtkwave adder_tb.lxt&
`default_nettype none
`timescale 1ns/1ps

module adder_tb;
  	reg [3:0] x, y;
	reg [1:0] x2, y2;
    reg x1, y1;

    reg cin;

	wire [3:0] z;
    wire [1:0] z2;
    wire z1;

	wire cout,cout2,cout1;

	// Instantiate the Unit Under Test (UUT)
    A4H_DLY UUT4(.A(x), .B(y), .CI(cin), .S(z), .CO(cout));
    A2N_DLY UUT2(.A(x2), .B(y2), .CI(cin), .S(z2), .CO(cout2));
    A1N_DLY UUT1(.A(x1), .B(y1), .CI(cin), .S(z1), .CO(cout1));

    initial begin
		$dumpfile("adder_tb.vcd");
		$dumpvars(0,adder_tb);
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
		x = 0; y = 0; cin = 0;
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