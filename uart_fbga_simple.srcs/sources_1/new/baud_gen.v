`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/20/2025 05:45:07 PM
// Design Name: 
// Module Name: baud_gen
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

// baud_gen.v
// Generates: baud_tick @ BAUD, sample_tick @ BAUD*OVERSAMPLE
module baud_gen #(
    parameter integer CLK_FREQ_HZ = 50_000_000,
    parameter integer BAUD = 115200,
    parameter integer OVERSAMPLE = 16
) (
    input wire clk,
    input wire rst,
    output reg baud_tick,
    output reg sample_tick
);

    // Integer divisors (small frequency error is acceptable for UART)
    localparam integer BAUD_DIV = (CLK_FREQ_HZ / BAUD);
    localparam integer SAMPLE_DIV = (CLK_FREQ_HZ / (BAUD * OVERSAMPLE));

    reg [31:0] baud_cnt = 0;
    reg [31:0] sample_cnt = 0;

    always @(posedge clk) begin
        if (rst) begin
            baud_cnt <= 0;
            sample_cnt <= 0;
            baud_tick <= 1'b0;
            sample_tick <= 1'b0;
        end else begin
            // baud_tick generation
            if (baud_cnt == 0) begin
                baud_cnt <= (BAUD_DIV > 0) ? (BAUD_DIV - 1) : 0;
                baud_tick <= 1'b1;
            end else begin
                baud_cnt <= baud_cnt - 1;
                baud_tick <= 1'b0;
            end

            // sample_tick generation (OVERSAMPLE× faster)
            if (sample_cnt == 0) begin
                sample_cnt <= (SAMPLE_DIV > 0) ? (SAMPLE_DIV - 1) : 0;
                sample_tick <= 1'b1;
            end else begin
                sample_cnt <= sample_cnt - 1;
                sample_tick <= 1'b0;
            end
        end
    end

endmodule