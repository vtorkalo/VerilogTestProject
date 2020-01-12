module edge_detect_moore
(
   input logic CLK, reset,
	input logic level,
	output logic tick
);

typedef enum bit[1:0] {zero, edg, one} state_type;

state_type state_reg, state_next;

always_ff @(posedge CLK, posedge reset)
  if (reset)
     state_reg <= zero;
  else
     state_reg <= state_next;
	 
always_comb 
begin
	state_next = state_reg;
	tick = 1'b0;
	case (state_reg)
	   zero:
		   if (level)
			   state_next = edg;
		edg:
		   begin
			   tick = 1'b1;
				if (level)
				   state_next = one;
			   else
				   state_next = zero;		
		   end
		one: if (~level)
		        state_next = zero;
		default: state_next = zero;
	endcase
end

endmodule