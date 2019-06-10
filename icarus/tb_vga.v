// tb_tst_6502.v - testbench for test 6502 core
// 02-11-19 E. Brombaugh

`timescale 1ns/1ps
`default_nettype none

module tb_vga;
    reg clk_4x, clk_2x, clk;
    reg reset;
	reg sel_ram;
	reg sel_ctl;
	reg we;
	reg [12:0] addr;
	reg [7:0] din;
	wire [7:0] ram_dout;
	wire [7:0] ctl_dout;
	wire [1:0] vga_r, vga_g, vga_b;
	wire vga_vs, vga_hs;
	
    // 40 MHz clock source
    always
        #12.5 clk_4x = ~clk_4x;
    
	// generate 2x, 1x clocks from 4x clk
	always @(posedge clk_4x)
		{clk,clk_2x} <= {clk,clk_2x} + 2'b01;
	
    // reset
    initial
    begin
`ifdef icarus
  		$dumpfile("tb_vga.vcd");
		$dumpvars;
`endif
        
        // init regs
        clk_4x = 1'b0;
        clk_2x = 1'b0;
        clk = 1'b0;
        reset = 1'b1;
		sel_ram = 1'b0;
		sel_ctl = 1'b0;
		we = 1'b0;
		addr = 13'h0000;
		din = 8'h00;
        
        // release reset
        #60
		@(posedge clk)
        reset = 1'b0;
        
`ifdef icarus
        // stop after 1 sec
		//#40000000 $finish; 	// full frame
		#1000000 $finish;		//quicker for testing
`endif
    end
    
    // Unit under test
	vga uut
	(
		.clk(clk),
		.clk_4x(clk_4x),
		.reset(reset),
		.sel_ram(sel_ram),
		.sel_ctl(sel_ctl),
		.we(we),
		.addr(addr),
		.din(din),
		.ram_dout(ram_dout),
		.ctl_dout(ctl_dout),
		.vga_r(vga_r),
		.vga_g(vga_g),
		.vga_b(vga_b),
		.vga_vs(vga_vs),
		.vga_hs(vga_hs)
	);
endmodule
