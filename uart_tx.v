module uart_tx (
	clk,
	nrst,
	tx_data,
	tx_start,
	tx_busy,
	txd
);
	parameter CLK_HZ = 200000000;
	parameter BAUD = 9600;
	parameter [15:0] BAUD_DIVISOR = CLK_HZ / BAUD;
	input clk;
	input nrst;
	input [7:0] tx_data;
	input tx_start;
	output reg tx_busy = 1'b0;
	output reg txd = 1'b1;
	reg [9:0] tx_shifter = 1'sb0;
	reg [15:0] tx_sample_cntr = 1'sb0;
	always @(posedge clk)
		if (~nrst || (tx_sample_cntr[15:0] == {16 {1'sb0}}))
			tx_sample_cntr[15:0] <= BAUD_DIVISOR - 1'b1;
		else
			tx_sample_cntr[15:0] <= tx_sample_cntr[15:0] - 1'b1;
	wire tx_do_sample;
	assign tx_do_sample = tx_sample_cntr[15:0] == {16 {1'sb0}};
	always @(posedge clk)
		if (~nrst) begin
			tx_busy <= 1'b0;
			tx_shifter[9:0] <= 1'sb0;
			txd <= 1'b1;
		end
		else if (~tx_busy) begin
			if (tx_start) begin
				tx_shifter[9:0] <= {1'b1, tx_data[7:0], 1'b0};
				tx_busy <= 1'b1;
			end
		end
		else if (tx_do_sample) begin
			{tx_shifter[9:0], txd} <= {tx_shifter[9:0], txd} >> 1;
			if (~|tx_shifter[9:1])
				tx_busy <= 1'b0;
		end
endmodule
