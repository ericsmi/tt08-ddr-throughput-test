
/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype wire

module delaygate(input A, output Z);
 `ifdef COCOTB_SIM
   assign #5 Z = A; 
 `else
    localparam N=4; // must be an even number greater than 2
    wire [N-2:0] X;
    wire [N-1:0] Y;
    sky130_fd_sc_hd__inv_2 [N-1:0] inv(.A({X[N-2:0],A}),.Y(Y[N-1:0]));
    assign Z=Y[N-1];
 `endif
endmodule

module andgate(input A,B, output Y);
  `ifdef COCOTB_SIM
  assign #1 Z = A&B;
  `else
  sky130_fd_sc_hd__and2_2 and2(.A(A),.B(B),.Y(Y));
  `endif
endmodule

module orgate(input A,B, output Y);
  `ifdef COCOTB_SIM
  assign #1 Y = A|B;
  `else
  sky130_fd_sc_hd__or2_2 or2(.A(A),.B(B),.Y(Y));
  `endif
endmodule

module posedge_detector(input A, output Z);
    delaygate dg(.A(A),.Y(Ad));
    andgate ag(.A(A),.B(~Ad),.Y(Z));
endmodule

module clkgen_2x(input clk, output clk2x);
    posedge_detector pdp(.A(clk),.Z(pe));
    posedge_detector pdn(.A(~clk),.Z(ne));
    orgate og(.A(pe),.B(ne),.Z(clk2x));
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

module tt_um_example (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  assign uo_out[7:2] = {clk,clk2x,4'b1100}; 
  assign uio_out = 0;
  assign uio_oe  = 0;

  clkgen_2x clkgen_2x(.clk(clk),.clk2x(clk2x));

  dff d0(.d(ui_in[0]),.rst_n(rst_n),.clk(clk),.q(uo_out[0]));
  dff d1(.d(ui_in[1]),.rst_n(rst_n),.clk(clk2x),.q(uo_out[1]));
    
  // List all unused inputs to prevent warnings
  wire _unused = &{ena, 1'b0};

endmodule
