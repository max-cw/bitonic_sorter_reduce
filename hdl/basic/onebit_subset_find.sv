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
// Description: Special sorter that only use the MSB to find a subset of input
//              that has MSB with HIGH value. I put it here just in case there is
//              a use in the future
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


module onebit_subset_find #(
    parameter int DATA_WIDTH = 1,
    parameter int IN_NUM = 8,
    parameter int OUT_NUM = 4
)
(
    input logic [DATA_WIDTH-1:0] data_in [IN_NUM],
    output logic [DATA_WIDTH-1:0] data_out [OUT_NUM]
);

    ///-----------------------------------------------------------------------------------------
    /// Warning: I (Max) haven't thought about the case where IN_NUM or OUT_NUM is an odd number.
    ///-----------------------------------------------------------------------------------------
    //Special sort. Only a single bit comparison. Can use a simplified sort
    //that I'd say looks like "parallel bubble sort". One example to point out is that
    //if there is only single non-zero hit in the input list at the last index,
    //it only has to "bubble up" to the last output index e.g. i=7 -> i=3.
    //There is no need to make it i=0. This idea helps simplified the sort.
    //Simple example for IN_NUM=4, OUT_NUM=2
    // Stage  0   1   2   3
    //-----------------------------
    //        0   0   0   1
    //          X       X
    //        0   0   1   0
    //              X
    //        0   1   0   0
    //          X
    //        1   0   0   0
    //
    //"X" is the comparator. Bottom-right X isn't need because we only need two outputs
    //Warning: Only works with DIR=1 (descending) for bitonic_comp module
    //         because it use < instead of <= operator. The pair will get swap with DIR=0
    // Number of stages required is either the number of swap so that the no-hit at i=0 needed to
    // "walk" out of the output range, or the hit at i=OUT_NUM-1 needed to "walk" into the output range,
    // whichever is bigger
    localparam int NStages = IN_NUM - OUT_NUM < OUT_NUM ? OUT_NUM : IN_NUM - OUT_NUM;
    logic [DATA_WIDTH-1:0] sort_stage [NStages+1][IN_NUM];
    assign sort_stage[0] = data_in;
    for (genvar i=0; i<NStages; i++) begin : gen_STAGE
        wire [DATA_WIDTH-1:0] sort_stage_in [IN_NUM];
        assign sort_stage_in = sort_stage[i];
        logic [DATA_WIDTH-1:0] sort_stage_out [IN_NUM];
        localparam int OddStage = i % 2; //Shift for odd stage
        localparam int NComp = $rtoi($floor($itor(IN_NUM) / 2)) - OddStage;
        for (genvar j=0; j<NComp; j++) begin : gen_COMP
            localparam int LowerIndex = (j*2)+OddStage;
            //Comparator can be removed if it fall outside of the output range needed. The condition is
            //the the comparator index is more than OUT_NUM AND the last index entry "walked" pass it
            localparam bit CompDisable = LowerIndex > OUT_NUM-1 && LowerIndex > (IN_NUM-i);
            if (!CompDisable) begin : gen_BITONIC_COMP
                bitonic_comp #(
                    .DATA_WIDTH(DATA_WIDTH),
                    .KEY_WIDTH (1),
                    .DIR       (1),
                    .SIGNED    (0),
                    .REGOUT_EN (0)
                ) bitonic_comp (
                    .CLK('0),
                    .A  (sort_stage_in[j*2+OddStage  ]),
                    .B  (sort_stage_in[j*2+OddStage+1]),
                    .H  (sort_stage_out[j*2+OddStage  ]),
                    .L  (sort_stage_out[j*2+OddStage+1])
                );
            end
            else begin : gen_PASSTHROUGH
                assign sort_stage_out[j*2+OddStage] = sort_stage_in[j*2+OddStage];
                assign sort_stage_out[j*2+OddStage+1] = sort_stage_in[j*2+OddStage+1];
            end
        end
        if (OddStage) begin : gen_ODD_EDGE_ASSIGN
            assign sort_stage_out[0] = sort_stage_in[0];
            assign sort_stage_out[IN_NUM-1] = sort_stage_in[IN_NUM-1];
        end

        assign sort_stage[i+1] = sort_stage_out;
    end
    assign data_out = sort_stage[NStages][0:OUT_NUM-1];

endmodule
