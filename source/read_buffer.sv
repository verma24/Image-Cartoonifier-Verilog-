// $Id: $
// File name:   read_buffer.sv
// Created:     4/19/2016
// Author:      Russell Doctor
// Lab Section: 337-05
// Version:     1.0  Initial Design Entry
// Description: Read Buffer

module read_buffer
(
input logic clk,
input logic n_rst,
input logic shift_enable8,
input logic shift_enable24,
input logic load_read_buffer,
input logic [31:0] master_readdata,
input logic master_readdatavalid,
input logic pixel_done,
output logic [215:0] pixelData,
output logic done_shift8,
output logic done_read24,
output logic done_load_read_buffer
);

reg [191:0] line1;
reg [191:0] line2;
reg [191:0] line3;
reg [191:0] buffer;
reg [575:0] line;
reg [2:0] filter_const; 
logic reset_filter_const;
genvar i;

assign pixelData = {line3[191-24*filter_const-:7'd72], line2[191-24*filter_const-:7'd72], line1[191-24*filter_const-:7'd72]};
//assign pixelData = {line[575-24*filter_const-:7'd72], line[383-24*filter_const-:7'd72], line[191-24*filter_const-:7'd72]};

always_ff@(posedge clk, negedge n_rst)
begin
	if (1'b0 == n_rst)
	begin
		buffer[23:0] <= 0;
		line1[23:0] <= 0;
		line2[23:0] <= 0;
		line3[23:0] <= 0;
		//line[23:0] <= 0;
	end
	else if (master_readdatavalid)
	begin
		if (shift_enable24)
		begin
			line1[23:0] <= master_readdata[23:0];
			line2[23:0] <= line1[191-:24];
			line3[23:0] <= line2[191-:24];
			//line[23:0] <= master_readdata[23:0];
		end
		if (load_read_buffer)
			buffer[23:0] <= master_readdata[23:0];
	end
	else if (shift_enable8)
	begin
		buffer[23:0] <= 0;
		line1[23:0] <= buffer[191-:24];
		line2[23:0] <= line1[191-:24];
		line3[23:0] <= line2[191-:24];
		//line[23:0] <= buffer[191-:24];
	end
end

generate
	for (i = 23; i<191; i=i+24)
	//for (i = 23; i < 575; i=i+24)
	always_ff@(posedge clk, negedge n_rst)
	begin
		if (1'b0 == n_rst)
		begin
			line1[i+24-:24] <= 0;
			line2[i+24-:24] <= 0;
			line3[i+24-:24] <= 0;
			//line[i+24-:24] <= 0;
			buffer[i+24-:24] <= 0;
		end	
		else if (master_readdatavalid)
		begin
			if (shift_enable24)
			begin
				line1[i+24-:24] <= line1[i-:24];
				line2[i+24-:24] <= line2[i-:24];
				line3[i+24-:24] <= line3[i-:24];
				//line[i+24-:24] <= line[i-:24];
			end
			if (load_read_buffer)
				buffer[i+24-:24] <= buffer[i-:24];
		end
		else if (shift_enable8)
		begin
			buffer[i+24-:24] <= buffer[i-:24];
			line1[i+24-:24] <= line1[i-:24];
			line2[i+24-:24] <= line2[i-:24];
			line3[i+24-:24] <= line3[i-:24];
			//line[i+24-:24] <= line[i-:24];
		end
	end
endgenerate


flex_counter #(3) count_24
(
	.clk(clk),
	.n_rst(n_rst),
	.clear(done_read24),
	.count_enable(done_load_read_buffer && shift_enable24),
	.rollover_val(3'd3),
	.rollover_flag(done_read24),
	.count_out()
);

flex_counter #(4) count_8
(
	.clk(clk),
	.n_rst(n_rst),
	.clear(done_shift8),
	.count_enable(shift_enable8),
	.rollover_val(4'd8),
	.rollover_flag(done_shift8),
	.count_out()
);

flex_counter #(4) count_load
(
	.clk(clk),
	.n_rst(n_rst),
	.clear(done_load_read_buffer),
	.count_enable((load_read_buffer || shift_enable24) && master_readdatavalid),
	.rollover_val(4'd8),
	.rollover_flag(done_load_read_buffer),
	.count_out()
);

flex_counter #(3) current_filter
(
	.clk(clk),
	.n_rst(n_rst),
	.clear(reset_filter_const),
	.count_enable(pixel_done),
	.rollover_val(3'd5),
	.rollover_flag(reset_filter_const),
	.count_out(filter_const)
);

endmodule