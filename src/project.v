
/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype wire

module invgate(input A, output Y);
 `ifdef COCOTB_SIM
    assign #1 Y = ~A;
 `else
    sky130_fd_sc_hd__inv_2 inv(.A(A),.Y(Y));
 `endif
endmodule

module delaygate #(parameter N=4) (input A, output Z);
    // N must be an odd number greater than 1
    wire [N-1:0] X;
    wire [N:0] Y;
    invgate inv[N:0](.A({X[N-1:0],A}),.Y(Y[N:0]));
    assign X[N-1:0]=Y[N-1:0];
    assign Z=Y[N];
endmodule

module andgate(input A,B, output Y);
  `ifdef COCOTB_SIM
  assign #1 Y = A&B;
  `else
  sky130_fd_sc_hd__and2_2 and2(.A(A),.B(B),.X(Y));
  `endif
endmodule

module orgate(input A,B, output Y);
  `ifdef COCOTB_SIM
  assign #1 Y = A|B;
  `else
  sky130_fd_sc_hd__or2_2 or2(.A(A),.B(B),.X(Y));
  `endif
endmodule

module posedge_detector #(parameter N=4) (input A, output Z);
    delaygate #(.N(N)) dg(.A(A),.Z(Ad));
    andgate ag(.A(A),.B(~Ad),.Y(Z));
endmodule

module clkgen_2x #(parameter N=4) (input clk, output clk2x);
    posedge_detector #(.N(N)) pdp(.A(clk),.Z(pe));
    posedge_detector #(.N(N)) pdn(.A(~clk),.Z(ne));
    orgate og(.A(pe),.B(ne),.Y(clk2x));
endmodule

module dff(input d,rst_n,clk, output q);
  `ifdef COCOTB_SIM
    reg q;
    always @(posedge clk or negedge rst_n)
        if(!rst_n) 
            q<=0;
        else
            q<=d;
  `else
    sky130_fd_sc_hd__dfrtp_4 dfrtp(
        .D(d),
        .RESET_B(rst_n),
        .CLK(clk),
        .Q(q)
    );
  `endif
endmodule

module ddr_input #(parameter N=4) (input rst_n, clk, d, output q);

  clkgen_2x #(.N(N)) clkgen_2x(.clk(clk),.clk2x(clk2x));
  dff                dff(
     .rst_n(rst_n),
     .d(d),
     .clk(clk2x),
     .q(q));

endmodule

module tt_um_ericsmi_ddr_input_test (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  assign uo_out[7:5] = {clk,2'b11}; 
  assign uio_out = 0;
  assign uio_oe  = 0;

  dff d0(.d(ui_in[4]),.rst_n(rst_n),.clk(clk),.q(uo_out[4]));

  ddr_input #(.N(1)) ddr_input1( .rst_n(rst_n), .d(ui_in[0]), .clk(clk), .q(uo_out[0]) );
  ddr_input #(.N(3)) ddr_input3( .rst_n(rst_n), .d(ui_in[1]), .clk(clk), .q(uo_out[1]) );
  ddr_input #(.N(5)) ddr_input5( .rst_n(rst_n), .d(ui_in[2]), .clk(clk), .q(uo_out[2]) );
  ddr_input #(.N(7)) ddr_input7( .rst_n(rst_n), .d(ui_in[3]), .clk(clk), .q(uo_out[3]) );
    
  // List all unused inputs to prevent warnings
  wire _unused = &{ena, 1'b0};

endmodule
