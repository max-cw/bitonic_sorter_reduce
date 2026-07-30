`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Chaowaroj (Max) Wanotayaroj (https://github.com/max-cw)
// 
// Create Date: 03.07.2026
// Design Name: 
// Module Name: bitonic_sort
// Project Name: bitonic_sort
// Target Devices:
// Tool Versions:
// Description: Simple SystemVerilog wrapper to use unpacked array ports
// Dependencies:
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// License: MIT
//  Copyright (c) 2026 Chaowaroj Wanotayaroj
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
// 
//////////////////////////////////////////////////////////////////////////////////

module bitonic_sort_sv #(
	parameter int DATA_WIDTH = 16,	//
	parameter int KEY_WIDTH = DATA_WIDTH,
	parameter int CHAN_NUM = 8,		//
	parameter int OUT_NUM = CHAN_NUM,// Output needed
	parameter int DIR = 0,			// 0 - ascending, 1 - descending
	parameter int SIGNED = 0,		// 0 - unsigned, 1 - signed
	parameter int PIPE_REG = 1,		// pipeline bypass, enable each N-th out reg
	parameter bit REG_IN = '0
)
(
	input logic clk,
	input logic [DATA_WIDTH-1:0]data_in[CHAN_NUM],
	output logic [DATA_WIDTH-1:0]data_out[OUT_NUM]
);

	logic [DATA_WIDTH*CHAN_NUM-1:0]data_in_packed;
	for (genvar i=0; i < CHAN_NUM; i++) begin
		if (REG_IN)
			always_ff @(posedge clk) data_in_packed[DATA_WIDTH*i +: DATA_WIDTH] <= data_in[i];
		else
			assign data_in_packed[DATA_WIDTH*i +: DATA_WIDTH] = data_in[i];
	end
	logic [DATA_WIDTH*OUT_NUM-1:0]data_out_packed;
	for (genvar i=0; i < OUT_NUM; i++) begin
		// if (REG_IN)
		// 	always_ff @(posedge clk) data_out[i] <= data_out_packed[DATA_WIDTH*i +:DATA_WIDTH];
		// else
			assign data_out[i] = data_out_packed[DATA_WIDTH*i +:DATA_WIDTH];
	end

	bitonic_sort #(
		.DATA_WIDTH(DATA_WIDTH),
		.KEY_WIDTH(KEY_WIDTH),
		.CHAN_NUM(CHAN_NUM),
		.OUT_NUM(OUT_NUM),
		.DIR(DIR),
		.SIGNED(SIGNED),
		.PIPE_REG(PIPE_REG)
	) bitonic_sort_inst (
		.clk(clk),
		.data_in(data_in_packed),
		.data_out(data_out_packed)
	);

endmodule
