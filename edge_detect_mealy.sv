module edge_detect_mealy
(
   input logic CLK, reset,
	input logic level,
	output logic tick
);

typedef enum bit[1:0] {zero, one} state_type;

state_type my_reg, state_next;

always_ff @(posedge CLK, posedge reset)
  if (reset)
     my_reg <= zero;
  else
     my_reg <= state_next;
	 
always_comb 
begin
	state_next = my_reg;
	tick = 1'b0;
	case (my_reg)
	   zero:
		   if (level)
			begin
			   state_next = one;
				tick = 1'b1;
			end
		
		one: if (~level)
		        state_next = zero;
		default: state_next = zero;
	endcase
end

endmodule