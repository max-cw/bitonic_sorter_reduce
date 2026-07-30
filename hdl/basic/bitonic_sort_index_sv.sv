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

module bitonic_sort_index_sv #(
	parameter int DATA_WIDTH = 16,	//
	parameter int KEY_WIDTH = DATA_WIDTH,
	parameter bit INDEX_SORT = '0,
	parameter int CHAN_NUM = 8,		//
	parameter int OUT_NUM = CHAN_NUM,// Output needed
	parameter int DIR = 0,			// 0 - ascending, 1 - descending
	parameter int SIGNED = 0,		// 0 - unsigned, 1 - signed
	parameter int PIPE_REG = 1,		// pipeline bypass, enable each N-th out reg
	parameter bit REG_IN = '0,
	parameter bit REG_OUT = '0
)
(
	input logic clk,
	input logic [DATA_WIDTH-1:0]data_in[CHAN_NUM],
	output logic [DATA_WIDTH-1:0]data_out[OUT_NUM],
	output logic [$clog2(CHAN_NUM)-1:0] index_out [OUT_NUM]
);

	typedef struct packed {
		logic [KEY_WIDTH-1:0] key;
		logic [$clog2(CHAN_NUM)-1:0] index;
	} key_t;

	key_t keys [CHAN_NUM];
	for (genvar i=0; i<CHAN_NUM; i++) begin
		assign keys[i].key = data_in[i][DATA_WIDTH-1 -:KEY_WIDTH];
		assign keys[i].index = i;
	end

	localparam int SortKeyWidth = INDEX_SORT ? $bits(key_t) : KEY_WIDTH;
	key_t keys_sorted [OUT_NUM];
	bitonic_sort_sv #(
		.DATA_WIDTH($bits(key_t)),
		.KEY_WIDTH(SortKeyWidth),
		.CHAN_NUM(CHAN_NUM),
		.OUT_NUM(OUT_NUM),
		.DIR(DIR),
		.SIGNED(SIGNED),
		.PIPE_REG(PIPE_REG),
		.REG_IN(REG_IN)
	) bitonic_sort_sv (
		.clk(clk),
		.data_in(keys),
		.data_out(keys_sorted)
	);

	localparam int SorterDepth = $clog2(CHAN_NUM)*($clog2(CHAN_NUM)+1)/2;
	localparam int NReg = (PIPE_REG==0) ? 0 : $floor($itor(SorterDepth)/PIPE_REG) + REG_IN;

	logic [DATA_WIDTH-1:0] data_pipe [CHAN_NUM];
	for (genvar i=0; i<CHAN_NUM; i++) begin : gen_SR_DELAY
		ShiftRegistersGen #(
			.DATA_WIDTH     (DATA_WIDTH),
			.DELAY_CYCLE    (NReg),
			.PLACEMENT_CYCLE(0)
		) shiftRegistersGen (
			.clk     (clk),
			.data_in (data_in[i]),
			.data_out(data_pipe[i])
		);
	end

	for (genvar i=0; i<OUT_NUM; i++) begin : gen_OUTPUT
		if (REG_OUT) begin : gen_REG_OUT
			always_ff @(posedge clk) begin
				data_out[i] <= data_pipe[keys_sorted[i].index];
				index_out[i] <= keys_sorted[i].index;
			end
		end
		else begin : gen_NO_REG_OUT
			assign data_out[i] = data_pipe[keys_sorted[i].index];
			assign index_out[i] = keys_sorted[i].index;
		end
	end

endmodule
