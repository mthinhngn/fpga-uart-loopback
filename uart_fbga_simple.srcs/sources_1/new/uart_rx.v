`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/20/2025 05:29:35 PM
// Design Name: 
// Module Name: uart_rx
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

// uart_rx.v : 8-N-1 receiver with 16x oversampling
module uart_rx #(
    parameter integer DATA_BITS   = 8,
    parameter integer OVERSAMPLE  = 16
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       sample_tick,   // OVERSAMPLE x baud
    input  wire       rx,            // serial in (idle high)
    output reg [7:0]  data_out,
    output reg        data_valid     // 1-cycle pulse when byte ready
);

    // 2-flop synchronizer for async rx
    reg [1:0] rx_sync;
    always @(posedge clk) rx_sync <= {rx_sync[0], rx};

    localparam IDLE  = 2'd0,
               START = 2'd1,
               DATA  = 2'd2,
               STOP  = 2'd3;

    reg [1:0] state;
    reg [4:0] samp_cnt;             // counts 0..OVERSAMPLE-1
    reg [3:0] bit_idx;
    reg [7:0] shreg;

    always @(posedge clk) begin
        if (rst) begin
            state      <= IDLE;
            samp_cnt   <= 0;
            bit_idx    <= 0;
            shreg      <= 0;
            data_out   <= 0;
            data_valid <= 1'b0;
        end else begin
            data_valid <= 1'b0; // default
            case (state)
                IDLE: begin
                    if (rx_sync[1] == 1'b0) begin // start edge detected
                        samp_cnt <= OVERSAMPLE >> 1; // half bit to mid-start
                        state    <= START;
                    end
                end
                START: begin
                    if (sample_tick) begin
                        if (samp_cnt == 0) begin
                            // sample mid-start; confirm still low
                            if (rx_sync[1] == 1'b0) begin
                                samp_cnt <= OVERSAMPLE-1;
                                bit_idx  <= 0;
                                state    <= DATA;
                            end else begin
                                state <= IDLE; // false start
                            end
                        end else begin
                            samp_cnt <= samp_cnt - 1'b1;
                        end
                    end
                end
                DATA: begin
                    if (sample_tick) begin
                        if (samp_cnt == 0) begin
                            // sample mid-bit
                            shreg <= {rx_sync[1], shreg[7:1]}; // shift in at MSB, LSB-first overall
                            samp_cnt <= OVERSAMPLE-1;
                            if (bit_idx == DATA_BITS-1) begin
                                state <= STOP;
                            end
                            bit_idx <= bit_idx + 1'b1;
                        end else begin
                            samp_cnt <= samp_cnt - 1'b1;
                        end
                    end
                end
                STOP: begin
                    if (sample_tick) begin
                        if (samp_cnt == 0) begin
                            // sample stop bit (should be high)
                            data_out   <= shreg;
                            data_valid <= 1'b1;
                            state      <= IDLE;
                        end else begin
                            samp_cnt <= samp_cnt - 1'b1;
                        end
                    end
                end
            endcase
        end
    end

endmodule



