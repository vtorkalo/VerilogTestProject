module lcd_init(
  input CLK,
  input sendText,
  input [8*16:0] text,  
  output [4:0] LCD_D,
  output LCD_E,
  output reg sendingDone,  
  output reg [3:0] d0
);


localparam FREQ = 50000000;
localparam t1_uS = FREQ / 1000000;
localparam t10us = t1_uS * 10;
   
localparam t53us = t1_uS * 53;
localparam t100us = t1_uS * 100;
   
localparam t3ms = t1_uS * 3000;
localparam t4_1ms = t1_uS * 4100;


reg [4:0] currentCommand = 0;
reg [20:0] currentDelay = 0;


reg isSending = 0;

localparam  NOT_INIT = 0, INIT_IN_PROGRESS = 1, DONE = 2;
reg[1:0] initState = NOT_INIT;

reg[4:0] initStep = 0;

reg sendCommandReg = 0;

assign sendCommandWire = sendCommandReg & isSending;
localparam rs1 = 5'b10000;

reg [7:0] x;
initial
begin
   x = "x";
end

reg getNextCommand = 0;

task getNextCommandTask;
begin
  //http://web.alfredstate.edu/faculty/weimandn/lcd/lcd_initialization/lcd_initialization_index.html   
  case (initStep)
     0:  begin  currentCommand <= 5'b00011;  currentDelay <= t4_1ms;  end
     1:  begin  currentCommand <= 5'b00011;  currentDelay <= t100us;  end
     2:  begin  currentCommand <= 5'b00011;  currentDelay <= t100us;  end
     3:  begin  currentCommand <= 5'b00010;  currentDelay <= t100us;  end        
     
     4:  begin  currentCommand <= 5'b00010;  currentDelay <= t10us;   end             
     5:  begin  currentCommand <= 5'b01100;  currentDelay <= t53us;   end // function set 
     
     6:  begin  currentCommand <= 5'b00000;  currentDelay <= t10us;   end     
     7:  begin  currentCommand <= 5'b01000;  currentDelay <= t53us;   end // display on off control        
     
     8:  begin  currentCommand <= 5'b00000;  currentDelay <= t10us;   end
     9:  begin  currentCommand <= 5'b00001;  currentDelay <= t3ms;    end // clear display
                
     10: begin  currentCommand <= 5'b00000;  currentDelay <= t10us;   end
     11: begin  currentCommand <= 5'b00110;  currentDelay <= t53us;   end// entry mode sed id and s
        
     12: begin  currentCommand <= 5'b00000;  currentDelay <= t10us;   end
     13: begin  currentCommand <= 5'b01100;  currentDelay <= t53us;   end// set blink cursor display on off control set d=1 b and c      
     
     14: begin  currentCommand <= rs1 + x[7:4];  currentDelay <= t10us;   end
     15: begin  currentCommand <= rs1 + x[3:0];  currentDelay <= t53us;   end//set blink cursor display on off control set d=1 b and c      
  endcase
end
endtask

always @(posedge CLK)
begin
  if (sendText)
  begin   
    isSending <= 1;
    if (initState == NOT_INIT)
       initState <= INIT_IN_PROGRESS;
       
    initStep <= 0;
    getNextCommand <= 1;
  end
    
  if (initState == INIT_IN_PROGRESS & getNextCommand)
  begin
     getNextCommandTask;
     getNextCommand <= 0;          
     sendCommandReg <= 1;   
  end

  if (commandDone)
  begin     
     sendCommandReg <= 0;
     if (initState <= INIT_IN_PROGRESS)
     begin
        if (initStep == 15) initState <= DONE; else
       begin
          initStep <= initStep + 1;
          getNextCommand <= 1;
       end
     end     
  end
end

wire commandDone;

wire sendCommandWire;

lcd_transfer lcd(.CLK(CLK), .sendCommand(sendCommandWire), .command(currentCommand), .commandDelay(currentDelay), .commandDone(commandDone), .LCD_D(LCD_D), .LCD_E(LCD_E));
endmodule