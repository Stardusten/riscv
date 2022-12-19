`include "define.vh"

module pc(
	input	wire					clk			,
	input	wire					rst			,
	input	wire					stallreq	,
	input	wire					br 			, // 是否跳转
	input	wire	[`RegBus]		bt			, // 跳转目标
	output	reg		[`InstAddrBus]	pc			,
	output	reg						ce	
);

always @(posedge clk) begin

	ce <= ~ rst;

	pc	<=	ce == `Disabled		?	`Zero
	    :	stallreq == `True	?	pc		// 暂停
		:	br == `True			?	bt		// 跳转
		:	pc + 4'h4;						// +4
end

endmodule