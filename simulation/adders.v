`default_nettype none
`timescale 1ns/1ps

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

module A4H_DLY (input [3:0] A,
               input [3:0] B,
               input CI,
               output [3:0] S,
               output CO);   
    wire [3:0] P,G;
    wire [4:0] C;   
        
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
    assign #5.64 CO = C[4];
endmodule