`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/20/2025 05:31:35 PM
// Design Name: 
// Module Name: uart_top
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

// uart_top.v : tie RX->TX when a byte arrives; mirror to LEDs
module uart_top #(
    parameter integer CLK_FREQ_HZ = 100_000_000,
    parameter integer BAUD = 115200,
    parameter integer OVERSAMPLE = 16
)(
    input wire clk,
    input wire rst,
    input wire uart_rx,
    output wire uart_tx,
    output reg [7:0] leds
);
    wire baud_tick, sample_tick;
    baud_gen #(.CLK_FREQ_HZ(CLK_FREQ_HZ), .BAUD(BAUD), .OVERSAMPLE(OVERSAMPLE)) u_baud (
        .clk(clk), .rst(rst), .baud_tick(baud_tick), .sample_tick(sample_tick)
    );

    // RX path
    wire [7:0] rx_data;
    wire rx_valid;
    uart_rx #(.DATA_BITS(8), .OVERSAMPLE(OVERSAMPLE)) u_rx (
        .clk(clk), .rst(rst), .sample_tick(sample_tick), .rx(uart_rx),
        .data_out(rx_data), .data_valid(rx_valid)
    );

    // TX path
    reg send;
    reg [7:0] tx_byte;
    wire tx_busy;
    uart_tx #(.DATA_BITS(8)) u_tx (
        .clk(clk), .rst(rst), .baud_tick(baud_tick),
        .data_in(tx_byte), .send(send), .tx(uart_tx), .busy(tx_busy)
    );

    // Simple loopback: when a byte arrives and TX is idle, send it back
    always @(posedge clk) begin
        if (rst) begin
            send <= 1'b0;
            tx_byte <= 8'h00;
            leds <= 8'h00;
        end else begin
            send <= 1'b0; // default low
            if (rx_valid && !tx_busy) begin
                tx_byte <= rx_data;
                leds <= rx_data; // display last byte
                send <= 1'b1; // 1-cycle pulse
            end
        end
    end
endmodule
