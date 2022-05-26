module shifter20(
    input clk,
    input nrst,
    input tx_busy,
    input [19:0] data, // 3*8 = 24
    output reg [7:0] tx_data,
    output reg tx_start
);

    localparam LEN = 3;
    wire [LEN*8-1:0] packet_data = {4'b0, data};

    localparam PACKET_LEN = 2+LEN+2;

    wire [PACKET_LEN*8-1:0] packet_init = {8'h55, 8'h77, packet_data, 8'haa, 8'hee};

    reg [PACKET_LEN*8-1:0] packet;

    reg [7:0] i;

    always @(posedge clk) begin
        if (~nrst) begin
            i <= 0;
            tx_data <= 8'b0;
            tx_start <= 1'b0;
            packet <= packet_init;
        end else begin
            if (~tx_busy) begin
                tx_data <= packet[i];
                tx_start <= 1'b1;
                if (i >= PACKET_LEN - 1) begin
                    i <= 0;
                    packet <= packet_init;
                end else begin
                    i <= i+1;
                end
            end else begin
                tx_data <= 8'b0;
                tx_start <= 1'b0;
                if (i == 0) packet <= packet_init;
            end
        end
    end

endmodule