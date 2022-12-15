`include "define.vh"

module pc(
	input	wire					clk	,
	input	wire					rst	,
	output	reg		[`InstAddrBus]	pc	,
	output	reg						ce	
);

always @(posedge clk) begin
	if (rst == `Enabled) begin
		ce <= `Disabled;
	end else begin
		ce <= `Enabled;
	end

	if (ce == `Disabled) begin
		pc <= `Zero;
	end else begin
		pc <= pc + 4'h4;
	end
end

endmodule