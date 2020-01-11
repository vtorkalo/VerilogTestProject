//display_decoder decoder(.CLK(CLK), .D0(units), .D1(tens), .D2(hundreds), .D3(thousands), .DIGIT (DIGIT), .SEG(SEG));

module display_decoder(
  input CLK,
  input [3:0] D0,
  input [3:0] D1,
  input [3:0] D2,
  input [3:0] D3,
  output reg [3:0] DIGIT,
  output [7:0] SEG
);

reg [15:0] counter;
reg [3:0] digit = 4'b0001;
reg [3:0] currentNumber;


always @(posedge CLK)
begin
  counter = counter + 1'b1;

  if (counter == 0)
  begin
    if (digit == 4'b1000)
    begin
      digit <= 4'b0001;
    end
    else
    begin
      digit <= digit << 1;
    end    	 	 
  end
  
  	 case (DIGIT)
      4'b1110: currentNumber <= D0;
	   4'b1101: currentNumber <= D1; 
	   4'b1011: currentNumber <= D2;
	   4'b0111: currentNumber <= D3;
    endcase

  DIGIT <= ~(digit);
   
	 
end


decoder_7_seg decoder(.CLK(CLK), .D(currentNumber), .SEG(SEG));  

endmodule