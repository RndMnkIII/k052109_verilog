/*****************************************************************
 * Convenient verilog templates of Fujitsu AV Series             *
 * Unit Cell Modules for simulation. For more info see:          *
 * Fujitsu CMOS Channeled Gate Arrays Data Book (1989)           *
 * Author: @RndMnkIII                                            *
 * Repository: https://github.com/RndMnkIII/k052109_verilog      *
 *                                                               *
 * - Version: 1.0 16/06/2021 Initial.                            *
 * - Version: 1.1 28/06/2021 Added VSCode snippets for Logic     *
 *                           Cells and more modules:T5A,T2C,T2B. *
 *                                                               *
 ****************************************************************/

`default_nettype none
`timescale 1ns/1ps

//For more detailed information about Fujitsu AV Series
//Logic Cell Functions, consult:
//"FUJITSU CMOS Channeled Gate Arrays 1989 Data Book"
//Propagation delay calculation is simplified:
//takes the t0 parameter for the worst case (can be for rising edge or for falling edge):
//ignoring the KCL term (usually smaller than t0).

//Cell Name: H6T
//Function: Tri-State Output and Input Buffer (True)
// OT->X  t0: 2.46-6.47
//  C->X  t0: 1.60-5.72 (Z->X, X->Z)
//  X->IN t0:2.06-3.08
//                   
//                   /| 3.08
// IN --------------< |-----|
//                   \|     |
//                |\        |
//                | \       |
// OT ------------|  >------o----- X
//                | / 6.47
//                |/O
//                  |
//                  |  
//                  Cn
module H6T_DLY ( input IN,
                 input Cn,
                 output OT,
                 inout X);
    //assign #6.47 X = Cn ? 1'bZ : OT;
    //assign #3.08 IN = X;
    assign IN = X;
    assign X = (Cn) ? 1'bZ : OT;
endmodule

//Cell Name: BD3
//Function: Buffer Delay Cell 
//to:11.80-11.76ns A->X

//Cell Name: BD5
//Function: Buffer Delay Cell 
//to:22.18-18.78ns A->X

//Cell Name: K2B
//Function: Power Clock Buffer
//to: 1.51-1.83ns A->X

//Cell Name: K1B
//Function: Clock Buffer
//to: 1.20-1.26ns A->X

//Cell Name: V2B 
//Function: Power Inverter
//to: 0.24-0.64ns A->X

//Cell Name: V1N
//Function: Inverter
//to: 0.30-0.55ns A->X

//Cell Name: X1B
//Function: Power Exclusive NOR
//to: 2.41-3.24ns A->X

//Cell Name: X2B
//Function: Power Exclusive OR
//to: 2.34-3.50ns A->X

//Cell Name: N2N
//Function: 2-input NAND
//to: 0.71-0.34ns A->X

//Cell Name: N2P
//Function: POWER 2-input AND
//to: 1.32-1.41ns A->X

//Cell Name: N3N
//Function:  3-input NAND
//to: 0.63-0.83ns A->X

//Cell Name: N4N
//Function:  4-input NAND
//to: 0.96-0.96ns A->X

//Cell Name: N8B
//Function:  POWER 8-input NAND
//to: 2.29-3.09ns A->X

//Cell Name: N3P
//Function: POWER 3-input AND
//to: 1.82-1.61ns A->X

//Cell Name: N4P
//Function: POWER 4-input AND
//to: 2.15-1.72ns A->X

//Cell Name: N2B
//Function: POWER 2-input NAND
//to: 2.03-1.73ns A->X

//Cell Name: N4B
//Function: POWER 4-input NAND
//to: 2.35-2.38ns A->X

//Cell Name: N6B
//Function: POWER 6-input NAND
//to: 2.18-2.83ns A->X

//Cell Name: R2B
//Function: POWER 2-input NOR
//to: 1.08-1.97ns A->X

//Cell Name: R3B
//Function: POWER 3-input NOR
//to: 3.65-1.61ns A->X

//Cell Name: R4B
//Function: POWER 4-input NOR
//to: 4.66-1.61ns A->X

//Cell Name: R6B
//Function: POWER 6-input NOR
//to: 3.80-1.79ns A->X

//Cell Name: R8B
//Function: POWER 8-input NOR
//to: 4.81-1.79ns A->X

//Cell Name: R2P
//Function: POWER 2-input OR
//to: 1.08-1.97ns A->X

//Cell Name: R4P
//Function: POWER 4-input OR
//to: 1.16-4.52ns A->X

//Cell Name: R2N
//Function: 2-input NOR
//to: 0.23-0.87ns A->X

//Cell Name: KCB
//Function: Block Clock Buffer (Non-Inv)
//to: 2.26-3.31ns A->X

//Cell Name: K3B
//Function: Gated Clock Buffer (AND) X = A1 & A2
//to: 1.34-1.45ns A->X

//Cell Name: K4B
//Function: Gated Clock Buffer (OR) X = A1 | A2
//to: 1.39-3.07ns A->X

//Cell Name: C43
//Function: 4-bit Binary Synchronous Up Counter
//CK->CO to=12.44-13.40ns
//CK->Q to=6.67-8.37ns
//CI->CO to=2.94-3.04ns
//CL->Q to=5.54ns
//CL->CO to=9.61ns
module C43_DLY ( input CK,
             input CLn,
             input Ln,
             input CI,
             input EN,
             output CO,
             output reg [3:0] Q,
             input [3:0] D);

    //assign #12.44 CO = ((Q == 4'hf) && (CI == 1'b1)) ? 1'b1 : 1'b0;
    assign #4.07 CO = ((Q == 4'hf) && (CI == 1'b1)) ? 1'b1 : 1'b0;

    always @(posedge CK or negedge CLn)
    begin
        if (CLn == 1'b0)
            Q <= #5.54 4'b0;
        else if (Ln == 1'b0)
            Q <= #8.37 D;
        else if ((CI == 1'b1) && (EN == 1'b1))
            Q <= #8.37 Q + 1;
    end
endmodule

//Cell Name: D24
//Function: 2-wide 2-AND 4-input AND-OR-Inverter
//Propagation delay: A,B -> X to: 0.48-1.66ns
module D24_DLY (input A1, input A2, input B1, input B2, output X);
    assign #1.66 X = ~((A1 & A2) | (B1 & B2));
endmodule

//Cell Name: T24
//Function: Power 2-AND 4-wide Multiplexer
//Propagation delay: A,B -> X to: 3.51-2.10ns
module T24_DLY (input A1, input A2, input B1, input B2, input C1, input C2, input D1, input D2, output X);
    assign #3.51 X = ~((A1 & A2) | (B1 & B2) | (C1 & C2) | (D1 & D2));
endmodule

//Cell Name: T34
//Function: Power 3-AND 4-wide Multiplexer
//Propagation delay: A,B -> X to: 3.25-2.58ns
module T34_DLY (input A1, input A2, input A3, input B1, input B2, input B3, input C1, input C2, input C3, input D1, input D2, input D3, output X);
    assign #3.25 X = ~((A1 & A2 & A3) | (B1 & B2 & B3) | (C1 & C2 & C3) | (D1 & D2 & D3));
endmodule

//Cell Name: FDE
//Function: Positive Edge Clocked Power DFF with CLEAR
//to: 4.44-6.23ns
module FDE_DLY 	( input D,
              input CLn,
              input CK,
              output reg Q,
              output Qn);
	
    //assign #0.55 Qn = ~Q;
    assign Qn = ~Q;

	always @ (posedge CK or negedge CLn) 
        if (!CLn)
            Q <= #5.13 1'b0;
        else
            Q <= #5.13 D;
endmodule

//Cell Name: FDG
//Function: Positive Edge Clocked DFF with CLEAR
//to: 3.79-5.24ns
module FDG_DLY 	( input D,
              input CLn,
              input CK,
              output reg Q,
              output Qn);
	
    //assign #0.55 Qn = ~Q;
    assign Qn = ~Q;

	always @ (posedge CK or negedge CLn) 
        if (!CLn)
            Q <= #5.24 1'b0;
        else
            Q <= #5.24 D;
endmodule

//Cell Name: FDM
//Function: DFF
//to: 5.16-5.96ns
module FDM_DLY 	( input D,
              input CK,
              output reg Q,
              output Qn);
	
    assign Qn = ~Q;

	always @ (posedge CK) 
        Q <= #4.96 D; //5.96
endmodule

//Cell Name: FDN
//Function: DFF with SET
//to: 5.16-6.10ns
module FDN_DLY 	( input D,
              input Sn,
              input CK,
              output reg Q,
              output Qn);
	
    //assign #0.55 Qn = ~Q;
    assign Qn = ~Q;

	always @ (posedge CK or negedge Sn) 
        if (!Sn)
            Q <= #5.16 1'b1;
        else
            Q <= #5.16  D;
endmodule

//Cell Name: FDO
//Function: DFF with RESET
//to: 5.96-5.16ns
module FDO_DLY 	( input D,
              input Rn,
              input CK,
              output reg Q,
              output Qn);
	
    //assign #0.55 Qn = ~Q;
    assign Qn = ~Q;

	always @ (posedge CK or negedge Rn) 
        if (!Rn)
            Q <= #4.71 1'b0; //#2.72
        else
            Q <= #4.71 D;
endmodule

//Cell Name: FDQ
//Function: 4-bit DFF falling edge clock
//to: 8.32-6.58ns
module FDQ_DLY 	( input [3:0] D,
              input CKn,
              output reg [3:0] Q);

	always @ (negedge CKn) 
        Q <= #8.32 D;
endmodule

//Cell Name: FDR
//Function: 4-bit DFF with clear
//to: 8.36-6.68ns CK->Q
//to: 3.52 CL->Q
module FDR_DLY 	( input [3:0] D,
              input CLn,
              input CK,
              output reg [3:0] Q);
	
	always @ (posedge CK or negedge CLn) begin
        if (!CLn)
            Q <= #3.52 4'b0000;
        else
            Q <= #8.36 D;
    end
endmodule

//Cell Name: FDS
//Function: Positive Edge Clocked 4-bit DFF
//to: 5.96-7.66ns
module FDS_DLY 	( input [3:0] D,
              input CK,
              output reg [3:0] Q);

	always @ (posedge CK) 
        Q <= #7.66 D;
endmodule

//Cell Name: LT2
//Function: 1-bit Data Latch
//Gn->Q to: 1.84-3.09ns
//Gn->Qn to: 3.94-2.59ns
//D->Q to: 1.44-3.09ns
//D->Qn to: 3.94-2.19ns

//Function Table:
//   Inputs      Outputs
//-----------------------
//|  D  Gn  |  Q   Qn   | 
//-----------------------
//|  X  H  |  Q0  Qn0   |
//|  D  L  |  D    Dn   |
//-----------------------
module LT2_DLY ( input D,
                 input Gn,
                 output reg Q,
                 output Qn);
      assign Qn = ~Q;

      always @*  
        if (!Gn) begin
            Q <= #3.94 D; 
        end
endmodule

//Cell Name: LT4
//Function: 4-bit Data Latch
//Gn->P to: 6.74-5.00ns
//Gn->N to: 5.80-7.50ns
//D->P to: 1.42-1.63ns
//D->N to: 2.43-2.18ns

//Function Table:
//   Inputs      Outputs
//-----------------------
//|  D  Gn  |  P   N    | 
//-----------------------
//|  X  H  |  P0   N0   |
//|  H  L  |  H    L    |
//|  L  L  |  L    H    |
//-----------------------
module LT4_DLY ( input [3:0] D,
                 input Gn,
                 output reg [3:0] P,
                 output [3:0] N);
      assign N[0] = ~P[0];
      assign N[1] = ~P[1];
      assign N[2] = ~P[2];
      assign N[3] = ~P[3];

      always @*  
        if (!Gn) begin
            //////$display("))) LT4 latched Gn=%b P=%b%b%b%b N=%b%b%b%b((( ", Gn, P[3],P[2],P[1],P[0],  N[3],N[2],N[1],N[0]);
            P <= #7.50 D; 
        end
endmodule

//Cell Name: LTK
//Function: 1-bit Data Latch
//Gn->Q to: 5.35-3.61ns
//Gn->Qn to: 4.41-6.11ns
//D->Q to: 1.42-1.63ns
//D->Qn to: 2.43-2.18ns

//Function Table:
//   Inputs      Outputs
//-----------------------
//|  D  Gn  |  Q   Qn   | 
//-----------------------
//|  X  H  |  Q0  Qn0   |
//|  D  L  |  D    Dn   |
//-----------------------
module LTK_DLY ( input D,
                 input Gn,
                 output reg Q,
                 output Qn);
      assign Qn = ~Q;

      always @*  
        if (!Gn) begin
            Q <= #6.11 D; 
            //////$display("))) LTK latched Gn=%b D=%b ((( ", Gn, D);
        end

endmodule

//Cell Name: LTL
//Function: 1-bit Data Latch with Clear
//CL->Q to: 1.40-2.20ns
//D->Q to: 1.56-1.83ns
//D->Qn to: 2.63-2.32ns
//Gn->Q to: 5.49-3.81ns
//Gn->Qn to: 4.61-6.25ns

//Function Table:
//   Inputs      Outputs
//-------------------------
//| CL  D  G  |  Q   Qn   | 
//-------------------------
//|  L  X  H  |  L   H    |
//|  H  X  H  |  Q0  Qn0  |
//|  H  D  L  |  D   Dn   |
//-------------------------
module LTL_DLY ( input D,
             input Gn,
             input CLn,
             output reg Q,
             output Qn);

      assign Qn = ~Q;

      always @*  
        if (~CLn & Gn)  //The function table states that must be Gn == H and CLn == L to Clear the register
            Q  <= #2.20 0;  
        else if (CLn & ~Gn)
            Q <= #6.25 D;  
endmodule

//Cell Name: T5A
//Function: 4:1 Selector
//A,B->X to: 1.48-1.13ns
//S1-S4->X to: 3.22-1.25ns
//S5-S6->X to: 2.63-0.70ns

//Function Table:
//                   Inputs                 Output
//-------------------------------------------------
//| A1  A2  B1  B2 S1n  S2 S3n  S4 S5n  S6  |  Xn | 
//-------------------------------------------------
//|  X   X   X   X   X   X   X   X   L   L  | Inh |?
//|  X   X   X   X   X   X   X   X   H   H  | Inh |?
//|  H   L           L   L                  | Inh |       
//|  L   H           L   L                  | Inh |       
//|  H   L           H   H                  | Inh |       
//|  L   H           H   H                  | Inh |
//|          L   H           L   L          | Inh |
//|          H   L           L   L          | Inh |
//|          L   H           H   H          | Inh |
//|          H   L           H   H          | Inh |
//| A1   X   X   X   L   H   X   X   L   H  | ~A1 |
//|  X  A2   X   X   H   L   X   X   L   H  | ~A2 |
//|  X   X  B1   X   X   X   L   H   H   L  | ~B1 |
//|  X   X   X  B2   X   X   H   L   H   L  | ~B2 |
//-------------------------------------------------
//(A1 != A2 -> S1 == S2) OR S5==S6 Inhibit
//(B1 != B2 ->S3 == S4) OR S5==S6 Inhibit
//(A1,A2 != B1,B2) OR S5==S6 Inhibit
module T5A_DLY ( input A1,
                 input A2,
                 input B1,
                 input B2,
                 input S1n,
                 input S2,
                 input S3n,
                 input S4,
                 input S5n,
                 input S6,
                 output Xn);
    wire [5:0] sel;
    reg out;

    assign sel = {S6, S5n, S4, S3n, S2, S1n};
    always @ * begin
        casex (sel)
            6'b10xx10: begin 
                ////////$display("<<<T5A CASE ~A1 >>>");
                out = ~A1; 
            end
            6'b10xx01: begin
                ////////$display("<<<T5A CASE ~A2 >>>");
                out = ~A2;
            end
            6'b0110xx: begin
                ////////$display("<<<T5A CASE ~B1 ~>>>");
                out = ~B1;
            end
            6'b0101xx: begin
                ////////$display("<<<T5A CASE ~B2 >>>");
                out = ~B2;
            end
            default: begin
                //////$display("<<<T5A Inhibit?>>>");
                out = 1'bZ; //inhibit?
            end
        endcase
    end
    assign #3.22 Xn = out;
endmodule

//Cell Name: T2B
//Function: 2:1 Selector
//A,B->X to: 0.87-0.62ns
//S1-S2->X to: 1.39-3.09ns

//Function Table:
//      Inputs        Output
//---------------------------
//|  A   B   S1n  S2  |  Xn | 
//---------------------------
//|  A   X    L    H  |  ~A |
//|  X   B    H    L  |  ~B |
//|  L   H    L    L  | Inh |
//|  H   L    L    L  | Inh |
//|  L   H    H    H  | Inh |
//|  H   L    H    H  | Inh |
//---------------------------
module T2B_DLY ( input A,
                 input B,
                 input S1n,
                 input S2,
                 output Xn);
    wire [3:0] sel;
    reg out;

    assign sel = {S2, S1n, B, A};
    always @ * begin
        casex (sel)
            4'b10xx: begin
                ////////$display("<<< T2B CASE ~A >>>");
                out = ~A;
            end
            4'b01xx: begin
                ////////$display("<<< T2B CASE ~B >>>");
                out = ~B;
            end
            4'b0010: begin
                //////$display("<<< T2B Inhibit >>>");
                out = 1'bZ; //inhibit
            end
            4'b0001: begin
                //////$display("<<< T2B Inhibit >>>");
                out = 1'bZ; //inhibit
            end
            4'b1110: begin
                //////$display("<<< T2B Inhibit >>>");
                out = 1'bZ; //inhibit
            end
            4'b1101: begin
                //////$display("<<< T2B Inhibit >>>");
                out = 1'bZ; //inhibit
            end
            default: begin
                //////$display("<<< T2B x? >>>");
                out = 1'bZ; //x??
            end 
        endcase
    end
    assign #3.09 Xn = out;
endmodule

//Cell Name: T2C
//Function: Dual 2:1 Selector
//A,B->X to: 0.87-0.62ns
//S1-S2->X to: 1.39-3.09ns

//Function Table:
//        Inputs             Output
//------------------------------------
//|A1,B1  A2,B2  S1n  S2  |  X0n  X1n| 
//------------------------------------
//|A1,B1    X      L   H  |  ~A1 ~B1 |
//|  X    A2,B2    H   L  |  ~A2 ~B2 |
//|  L      H      L   L  |  Inh Inh |
//|  H      L      L   L  |  Inh Inh |
//|  L      H      H   H  |  Inh Inh |
//|  H      L      H   H  |  Inh Inh |
//------------------------------------
module T2C_DLY ( input A1,
                 input A2,
                 input B1,
                 input B2,
                 input S1n,
                 input S2,
                 output X0n,
                 output X1n);
    wire [1:0] sel;
    reg out0, out1;

    assign sel = {S2, S1n};
    always @ * begin
        casex (sel)
            2'b10: begin
                out0 = ~A1;
                out1 = ~B1;
            end
            2'b01: begin
                out0 = ~A2;
                out1 = ~B2;
            end
            default: begin
                    ////$display("<<<T2C inhibit>>>");
                    out0 = 1'bZ;
                    out1 = 1'bZ;
            end
        endcase
    end
    assign #3.09 X0n = out0;
    assign #3.09 X1n = out1;
endmodule

//Cell Name: A1N
//Function: 1-BIT Full Adder
//A,B->S to: 5.23-2.96ns
//A,B->CO to: 1.85-2.13ns
module A1N_DLY(
    input A,
    input B,
    input CI,
    output S,
    output CO
    );

    assign #5.23 S = A ^ B ^ CI;
    assign #2.13 CO = (A & B) | (CI & (A ^ B));
endmodule

//Cell Name: A2N
//Function: 2-BIT Full Adder
//A,B->S to: 5.23-2.96ns
//A,B->CO to: 4.75-3.83ns
module A2N_DLY(
    input [1:0] A,
    input [1:0] B,
    input CI,
    output [1:0] S,
    output CO
    );
        //implemented as Fujitsu AV CMOS Logic Gate equivalent circuit
        //the propagation delay was added to the final output signals S,CO
        //and not for each logic gate.
        //st1
        wire gxy1; //NAND
        assign gxy1 = ~(A[1] & B[1]);
        wire gxy2; //NOR
        assign gxy2 = ~(A[1] | B[1]);
        wire gxy3; //NAND
        assign gxy3 = ~(A[0] & B[0]);
        wire gxy4; //NOR
        assign gxy4 = ~(A[0] | B[0]);

        //st2
        wire gxx1; //NOT
        assign gxx1 = ~gxy2;
        wire gxx2; //AND
        assign gxx2 = gxy3 & gxx4;
        wire gxx3; //NOT
        assign gxx3 = ~gxy4;
        wire gxx4; //NOT
        assign gxx4 = ~CI;

        //st3
        wire gxz1; //NAND
        assign gxz1 = ~(gxy1 & gxx1);
        wire gxz2; //NOR
        assign gxz2 = ~(gxy4 | gxx2);
        wire gxz3; //NAND
        assign gxz3 = ~(gxy3 & gxx3);

        //st4
        wire gyy1; //NOT
        assign gyy1 = ~gxz2;
        wire gyy2; //NOT
        assign gyy2 = ~gxz1;
        wire gyy3; //NOT
        assign gyy3 = ~gxz3;

        //st5
        wire gyx1; //AND
        assign gyx1 = gxy1 & gyy1;
        wire gyx2; //AND
        assign gyx2 = gxz1 & gyy1;
        wire gyx3; //AND
        assign gyx3 = gyy2 & gxz2;
        wire gyx4; //AND
        assign gyx4 = CI & gyy3;
        wire gyx5; //AND
        assign gyx5 = gxz3 & gxx4;

        //st6
        wire gyz1; //NOR
        assign gyz1 = ~(gyx1 | gxy2);
        assign #4.75 CO = gyz1;

        wire gyz2; //NOR
        assign gyz2 = ~(gyx2 | gyx3);
        assign #5.23 S[1] = gyz2;

        wire gyz3; //NOR
        assign #5.23 gyz3 = ~(gyx4 | gyx5);
        assign S[0] = gyz3;
endmodule

//Cell Name: A4H
//Function: 4-BIT Full Adder
//A,B->S to: 8.13-5.76ns
//A,B->CO to: 5.64-7.19ns
module A4H_DLY (input [3:0] A,
               input [3:0] B,
               input CI,
               output [3:0] S,
               output CO);   
    wire [3:0] P,G;
    wire [4:0] C;   
        
    //Uses CLA (Carry-Lookahead Adder) implementation.
    
    //first level
    assign P = A ^ B;
    assign G = A & B;

    //second level
    assign C[0] = CI;
    assign C[1] = G[0] | (P[0] & CI);
    assign C[2] = G[1] | (P[1] & G[0]) | (P[1] & P[0] & CI);
    assign C[3] = G[2] | (P[2] & G[1]) | (P[2] & P[1] & G[0]) | (P[2] & P[1] & P[0] & CI);
    assign C[4] = G[3] | (P[3] & G[2]) | (P[3] & P[2] & G[1]) | (P[3] & P[2] & P[1] & G[0]) | (P[3] & P[2] & P[1] & P[0] & CI);

    //third level
    assign #8.13 S = P ^ C[3:0];
    assign #7.19 CO = C[4];
endmodule