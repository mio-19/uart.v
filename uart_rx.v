module uart_rx (
	clk,
	nrst,
	rx_data,
	rx_busy,
	rx_done,
	rx_err,
	rxd
);
	parameter CLK_HZ = 200000000;
	parameter BAUD = 9600;
	parameter [15:0] BAUD_DIVISOR_2 = (CLK_HZ / BAUD) / 2;
	input clk;
	input nrst;
	output reg [7:0] rx_data = 1'sb0;
	output reg rx_busy = 1'b0;
	output reg rx_done;
	output reg rx_err;
	input rxd;
	wire rxd_s;
	delay #(
		.LENGTH(2),
		.WIDTH(1)
	) rxd_synch(
		.clk(clk),
		.nrst(nrst),
		.ena(1'b1),
		.in(rxd),
		.out(rxd_s)
	);
	wire start_bit_strobe;
	edge_detect rxd_fall_detector(
		.clk(clk),
		.nrst(nrst),
		.in(rxd_s),
		.falling(start_bit_strobe)
	);
	reg [15:0] rx_sample_cntr = BAUD_DIVISOR_2 - 1'b1;
	wire rx_do_sample;
	assign rx_do_sample = rx_sample_cntr[15:0] == {16 {1'sb0}};
	reg rx_data_9th_bit = 1'b0;
	always @(posedge clk)
		if (~nrst) begin
			rx_busy <= 1'b0;
			rx_sample_cntr <= BAUD_DIVISOR_2 - 1'b1;
			{rx_data[7:0], rx_data_9th_bit} <= 1'sb0;
		end
		else if (~rx_busy) begin
			if (start_bit_strobe) begin
				rx_sample_cntr[15:0] <= (BAUD_DIVISOR_2 * 3) - 1'b1;
				rx_busy <= 1'b1;
				{rx_data[7:0], rx_data_9th_bit} <= 9'b100000000;
			end
		end
		else begin
			if (rx_sample_cntr[15:0] == {16 {1'sb0}})
				rx_sample_cntr[15:0] <= (BAUD_DIVISOR_2 * 2) - 1'b1;
			else
				rx_sample_cntr[15:0] <= rx_sample_cntr[15:0] - 1'b1;
			if (rx_do_sample)
				if (rx_data_9th_bit == 1'b1)
					rx_busy <= 1'b0;
				else
					{rx_data[7:0], rx_data_9th_bit} <= {rxd_s, rx_data[7:0]};
		end
	always @(*) begin
		rx_done <= (rx_data_9th_bit && rx_do_sample) && rxd_s;
		rx_err <= (rx_data_9th_bit && rx_do_sample) && ~rxd_s;
	end
endmodule
