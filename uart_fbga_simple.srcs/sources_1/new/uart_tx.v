module uart_tx #(
    parameter integer DATA_BITS = 8
    )(
    input wire clk,
    input wire rst,
    input wire baud_tick,   // 1 cycle pulse each bit period
    input wire [7:0] data_in,
    input wire send,        // pulse to start a byte
    output reg tx,          //serial out (idle high)
    output reg busy
);
    localparam IDLE  = 2'd0,
               START = 2'd1,
               DATA  = 2'd2,
               STOP  = 2'd3;

    reg [1:0] state;
    reg [3:0] bit_idx;
    reg [7:0] shreg;
    
    always @(posedge clk) begin
        if(rst) begin
            state <= IDLE;
            tx <= 1'b1; //idle is high
            busy <= 1'b0;
            bit_idx <= 4'd0;
            shreg <= 8'h00;
        end
        else begin
            case(state)
                IDLE: begin
                    tx  <= 1'b1;
                    busy<= 1'b0;
                    if(send) begin
                        shreg <= data_in;   //latch
                        busy  <= 1'b1;
                        state <= START;
                    end
                end
                START: begin
                    if(baud_tick) begin
                        tx  <= 1'b0;    // start bit
                        bit_idx <= 4'd0;
                        state <= DATA;
                    end
                end
                DATA: begin
                    if(baud_tick) begin
                        tx  <= shreg[0];    //LSB first
                        shreg <= {1'b0, shreg[7:1]};
                        if (bit_idx == DATA_BITS-1)
                            state <= STOP;
                        bit_idx <= bit_idx + 1'b1;
                    end
                end
                STOP: begin
                    if (baud_tick) begin
                        tx  <= 1'b1;    //stop bit
                        state <= IDLE;
                    end
                end
            endcase
        end
    end
endmodule
                
    
    