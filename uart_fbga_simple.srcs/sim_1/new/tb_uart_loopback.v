`timescale 1ns/1ps
module tb_uart_loopback;
    // Parameters
    parameter integer CLK_FREQ_HZ = 50_000_000;
    parameter integer BAUD = 115200;
    parameter integer OVERSAMPLE = 16;
    
    // Clock and reset
    reg clk = 0;
    reg rst = 1;
    
    // Clock generation
    always #(500_000_000 / CLK_FREQ_HZ) clk = ~clk;
    
    // Baud generator
    wire baud_tick, sample_tick;
    baud_gen #(.CLK_FREQ_HZ(CLK_FREQ_HZ), .BAUD(BAUD), .OVERSAMPLE(OVERSAMPLE)) u_baud (
        .clk(clk), .rst(rst), .baud_tick(baud_tick), .sample_tick(sample_tick)
    );

    // TX
    reg send = 0;
    reg [7:0] data_in = 8'h00;
    wire tx;
    wire tx_busy;
    uart_tx u_tx (
        .clk(clk), .rst(rst), .baud_tick(baud_tick), 
        .data_in(data_in), .send(send), .tx(tx), .busy(tx_busy)
    );

    // RX
    wire [7:0] rx_data;
    wire rx_valid;
    uart_rx #(.OVERSAMPLE(OVERSAMPLE)) u_rx (
        .clk(clk), .rst(rst), .sample_tick(sample_tick), .rx(tx),
        .data_out(rx_data), .data_valid(rx_valid)
    );

    // Stimulus
    reg [7:0] vec [0:4];
    integer i;

    initial begin
        // Optional VCD for GTKWave
        $dumpfile("uart_tb.vcd");
        $dumpvars(0, tb_uart_loopback);

        // Test vector
        vec[0] = 8'h55; // 01010101
        vec[1] = 8'hA5; // 10100101
        vec[2] = 8'h00;
        vec[3] = 8'hFF;
        vec[4] = 8'h31; // '1'

        // Reset
        repeat (5) @(posedge clk);
        rst = 0;

        // Send all bytes, check RX
        for (i = 0; i < 5; i = i + 1) begin
            // Launch a byte when TX idle
            @(posedge clk);
            while (tx_busy) @(posedge clk);
            data_in <= vec[i];
            send <= 1'b1;
            @(posedge clk);
            send <= 1'b0;

            // Wait for receive valid
            wait(rx_valid === 1'b1);
            // Check value
            if (rx_data !== vec[i]) begin
                $display("ERROR: got %02x expected %02x", rx_data, vec[i]);
                $fatal(1);
            end else begin
                $display("OK: %02x", rx_data);
            end
            @(posedge clk);
        end

        $display("All bytes looped back correctly.");
        #100000; // a little extra time
        $finish;
    end
endmodule