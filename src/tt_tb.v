`default_nettype wire

module tb;

reg rst_n,clk,halfclk;
reg [4:0] lfsr;

wire [7:0] uo_out;

initial begin
 clk = 1 ; #10 clk = 0 ; 
 forever #10 clk = ~clk ;
end

always @(posedge clk) begin
  halfclk   <= rst_n ? ~halfclk : 1'b0;
  lfsr[4:0] <= rst_n ? { lfsr[3:0], ~(lfsr[4] ^ lfsr[2]) } : 5'd0; 
end

tt_um_wokwi_407306064811090945 ericsmi_tt_um_ddr_input_test(
    .ui_in({8{lfsr[0]}}),  
    .uo_out(uo_out[7:0]),
    .uio_in(8'd0),
    .uio_out(),
    .uio_oe(),
    .ena(1'b1),
    .clk(halfclk),
    .rst_n(rst_n));

initial  begin
  $dumpfile("tb.vcd");
  $dumpvars(0); 

  rst_n = 0;
  $display ("T\tRn\tL\tUj");
  $display ("------------------------------------------------------");
  @(posedge clk);
  @(posedge clk);
  rst_n = 1;
  $monitor ("%03t\t%d\t%d\t%02x", $time, rst_n, lfsr[0], uo_out[7:0]);
  #200 $finish;
end

endmodule
