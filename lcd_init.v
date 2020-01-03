module lcd_init(
  input CLK,
  input sendText,
  reg line,
  input [8*16:1] text,  
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


reg [5:0] currentChar = 0;
reg currentHalf = 1;

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
  endcase
end
endtask


task getNextTextCommandTask;
begin
  if (currentHalf)
  begin
     currentCommand <= rs1 + text[( (16-currentChar-1)*8+5 ) +:4];
     currentDelay <= t10us;
  end else
  begin  
     currentCommand <= rs1 + text[((16-currentChar-1)*8+1) +:4];
     currentDelay <= t53us;
  end  
end
endtask


always @(posedge CLK)
begin
  if (sendText)
  begin 
    currentHalf <= 1;
    isSending <= 1;
    if (initState == NOT_INIT)
    begin
       initState <= INIT_IN_PROGRESS;
       initStep <= 0;       
    end
    getNextCommand <= 1;
  end
    
  if (getNextCommand)
  begin
     if (initState == INIT_IN_PROGRESS)
     begin
        getNextCommandTask;
     end
     if (initState == DONE)
     begin
        getNextTextCommandTask;
     end
     
     getNextCommand <= 0;          
     sendCommandReg <= 1;   
  end
 

  if (commandDone)
  begin     
     sendCommandReg <= 0;
     if (initState <= INIT_IN_PROGRESS)
     begin
        if (initStep == 13) 
        begin
           initState <= DONE; 
        end else
        begin
           initStep <= initStep + 1;          
        end
       getNextCommand <= 1;
     end     
     
     if (initState == DONE)
     begin
        if (currentHalf == 1)
        begin
           getNextCommand <= 1;
           currentHalf <= ~currentHalf;
        end
        if (currentHalf == 0 & currentChar < 16)
        begin
           currentChar <= currentChar + 1;
           getNextCommand <= 1;
           currentHalf <= ~currentHalf;
        end
        if (currentHalf == 0 & currentChar > 16)
        begin
           d0 <= d0 + 1;
           isSending <= 0;
           getNextCommand <= 0;  
           sendingDone <= 1;
        end             
     end
  end
         
  
end

wire commandDone;

wire sendCommandWire;

lcd_transfer lcd(.CLK(CLK), .sendCommand(sendCommandWire), .command(currentCommand), .commandDelay(currentDelay), .commandDone(commandDone), .LCD_D(LCD_D), .LCD_E(LCD_E));
endmodule