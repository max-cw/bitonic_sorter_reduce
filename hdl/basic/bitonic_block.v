`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Dmitry Matyunin (https://github.com/mcjtag)
// 
// Create Date: 10.02.2018 13:22:07
// Design Name: 
// Module Name: bitonic_block
// Project Name: bitonic_sort
// Target Devices:
// Tool Versions:
// Description:
// Dependencies:
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// License: MIT
//  Copyright (c) 2019 Dmitry Matyunin
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

module bitonic_block #(
	parameter DATA_WIDTH = 16,
	parameter ORDER = 0,
	parameter POLARITY = 0,
	parameter DIR = 0,
	parameter SIGNED = 0,
	parameter PIPE_REG = 1,
	parameter MAXOUT_NUM = 2**(ORDER+1),
	parameter IN_NUM = 2**(ORDER+1) > 2*MAXOUT_NUM ? 2*MAXOUT_NUM : 2**(ORDER+1),
	parameter OUT_NUM = 2**(ORDER+1) > MAXOUT_NUM ? MAXOUT_NUM : 2**(ORDER+1)

)
(
	input wire clk,
	input wire [DATA_WIDTH*IN_NUM-1:0]data_in,
	output wire [DATA_WIDTH*OUT_NUM-1:0]data_out
);

localparam STAGES = ORDER + 1;
localparam STAGE_IN_DATA_WIDTH = DATA_WIDTH*IN_NUM;
localparam STAGE_OUT_DATA_WIDTH = DATA_WIDTH*OUT_NUM;

function integer index(input integer SS, input integer BS);
	integer i, j, ind;
begin
	ind = 0;
	for (i = 0; i < SS; i = i + 1) begin
		for (j = i+1; j < SS+1; j = j + 1) begin
			ind = ind + 1;
		end
	end
	index = ind + BS + 1;
end
endfunction

wire [DATA_WIDTH*2**(ORDER+1)-1:0]stage_data[STAGES:0];

assign stage_data[0] = data_in;
assign data_out = POLARITY==0 ? stage_data[STAGES][0+: DATA_WIDTH*OUT_NUM] : stage_data[STAGES][DATA_WIDTH*IN_NUM-1-: DATA_WIDTH*OUT_NUM];

genvar stage;
genvar node;

generate for (stage = 0; stage < STAGES; stage = stage + 1) begin: BLOCK_STAGE
	localparam NODES_FULL = 2**stage;
	localparam NODE_ORDER = STAGES - stage - 1;
	localparam NODE_OUT_NUM = 2**(NODE_ORDER+1);
	localparam NODES = $rtoi($ceil($itor(OUT_NUM) / NODE_OUT_NUM));
	localparam NODES_REMOVED = NODES_FULL-NODES;
		
	wire [STAGE_IN_DATA_WIDTH-1:0]stage_data_in;
	wire [STAGE_OUT_DATA_WIDTH-1:0]stage_data_out;
		
	assign stage_data_in = stage_data[stage];
	assign stage_data[stage + 1] = 	stage_data_out;
	// assign stage_data_out[BLOCK_DATA_WIDTH*(block)+:BLOCK_DATA_WIDTH] = BLOCK_POLARITY ? {{BLOCK_DATA_WIDTH-BLOCK_IN_DATA_WIDTH{1'b0}}, block_data_out}
	// 																					: {block_data_out, {BLOCK_DATA_WIDTH-BLOCK_IN_DATA_WIDTH{1'b0}}};

	localparam NODES_START	= POLARITY==0 ? 0 : NODES_FULL-1;
	localparam NODES_END	= POLARITY==0 ? NODES : NODES_REMOVED-1;
	for (node = NODES_START; node != NODES_END; node = POLARITY==0 ? node+1 : node-1) begin: NODE
		localparam NODE_DATA_WIDTH = DATA_WIDTH*NODE_OUT_NUM;
		wire [NODE_DATA_WIDTH-1:0]node_data_in;
		wire [NODE_DATA_WIDTH-1:0]node_data_out;
			
		assign node_data_in = stage_data_in[NODE_DATA_WIDTH*(node + 1)-1-:NODE_DATA_WIDTH];

		localparam NODE_COUNT = POLARITY==0 ? node+1 : NODES_FULL - node;
		localparam NODE_OUT_NUM_USE = NODE_COUNT*NODE_OUT_NUM <= OUT_NUM ? NODE_OUT_NUM : NODE_COUNT*NODE_OUT_NUM-OUT_NUM;
		wire [DATA_WIDTH*NODE_OUT_NUM_USE-1:0] node_data_use;
		localparam NODE_OUT_INDEX = POLARITY==0 ? node : node - NODES_REMOVED;
		assign node_data_use = POLARITY==0	? node_data_out[0                +: DATA_WIDTH*NODE_OUT_NUM_USE]
											: node_data_out[NODE_DATA_WIDTH-1-: DATA_WIDTH*NODE_OUT_NUM_USE];
		assign stage_data_out[NODE_DATA_WIDTH*(NODE_OUT_INDEX)+: DATA_WIDTH*NODE_OUT_NUM_USE] = node_data_use;
		// assign stage_data_out[BLOCK_DATA_WIDTH*(block)+:BLOCK_DATA_WIDTH] = BLOCK_POLARITY ? {{BLOCK_DATA_WIDTH-BLOCK_IN_DATA_WIDTH{1'b0}}, block_data_out}
		// 																					: {block_data_out, {BLOCK_DATA_WIDTH-BLOCK_IN_DATA_WIDTH{1'b0}}};
			
		bitonic_node #(
			.DATA_WIDTH(DATA_WIDTH),
			.ORDER(NODE_ORDER),
			.DIR(DIR),
			.SIGNED(SIGNED),
			.PIPE_REG(PIPE_REG),
			.INDEX(index(ORDER, stage))
		) bitonic_node_inst (
			.clk(clk),
			.data_in(node_data_in),
			.data_out(node_data_out)
		);		
	end
end endgenerate

endmodule
