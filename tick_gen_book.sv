module tick_gen_book
(
   input logic CLK, reset,
	input logic level,
	output logic tick
);


logic delay_reg;

always_ff @(posedge CLK)
begin
  delay_reg <= level;
end
  
assign tick = ~delay_reg & level;


endmodule