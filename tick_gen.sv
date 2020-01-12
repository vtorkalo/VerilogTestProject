module tick_gen
(
   input logic CLK, reset,
	input logic level,
	output logic tick
);


logic prev_level;

always_ff @(posedge CLK)
begin
  if (tick)
     tick <= 1'b0;

  if (level & ~prev_level)
     tick <= 1'b1;     
  
  prev_level <= level;
end








endmodule