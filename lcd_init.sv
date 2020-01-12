module lcd_init(
  input logic CLK,
  input logic sendText,
  input logic [8 * TEXT_LENGTH : 1] text,  
  output logic [4:0] LCD_D,
  output logic LCD_E,
  output logic sendingDone
);

localparam TEXT_LENGTH = 6'd34;
localparam FREQ = 26'd50000000;

localparam [20:0] t1_uS = FREQ / 20'd1000000;
localparam [20:0] t10us = t1_uS * 4'd10; 
localparam [20:0] t53us = t1_uS * 6'd53;
localparam [20:0] t100us = t1_uS * 7'd100;  
localparam [20:0] t3ms = t1_uS * 13'd3000;
localparam [20:0] t4_1ms = t1_uS * 13'd4100;

localparam [4:0] rs1 = 5'b10000;

logic [4:0] currentCommand = 0;
logic [20:0] currentDelay = 0;

logic isSending = 0;

typedef enum { NOT_INIT, INIT_IN_PROGRESS, DONE } init_state_type;
init_state_type initState = NOT_INIT;

logic[3:0] initStep = 0;

logic [5:0] currentChar = 1;
logic highNibble = 1'b1;

logic getNextCommand = 0;

task getNextInitCommandTask;
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

logic [8:0] lowHalfStartIndex, highHalfStartIndex;
assign lowHalfStartIndex = (TEXT_LENGTH-currentChar) * 4'd8 + 1'b1;
assign highHalfStartIndex = (TEXT_LENGTH-currentChar) * 4'd8 + 4'd5;

logic line = 0;

task getNextTextCommandTask;
begin
  if (text[lowHalfStartIndex +: 8] == "\n" & line == 0)
  begin  http://web.alfredstate.edu/faculty/weimandn/lcd/lcd_addressing/lcd_addressing_index.html
    if (highNibble)        
        currentCommand <= 5'b01000; //set cursor at 1st line beginning
     else
     begin
        currentCommand <= 5'b00000;
        line <= 1;
     end
  end else
  if (text[lowHalfStartIndex +: 8] == "\n" & line == 1)
  begin
    if (highNibble)
        currentCommand <= 5'b01100; //set cursor at 2nd line beginning
    else
        currentCommand <= 5'b00000;
  end else
  if (highNibble)
     currentCommand <= rs1 + text[highHalfStartIndex +:4];
  else
     currentCommand <= rs1 + text[lowHalfStartIndex +:4];
     
   if (highNibble)   
      currentDelay <= t10us;
   else
      currentDelay <= t53us;      
end
endtask


logic takeNewChar, isLastTransfer, isLastInitStep;
assign takeNewChar = ~highNibble & currentChar < TEXT_LENGTH; 
assign isLastTransfer = highNibble == 0 & currentChar == TEXT_LENGTH;
assign isLastInitStep = initStep == 13;

always @(posedge CLK)
begin
  sendCommandReg <= 0;
  getNextInitCommandTask;

  if (sendText)
  begin 
    highNibble <= 1'b1;
    isSending <= 1'b1;
    currentChar <= 1'b1;
    getNextCommand <= 1'b1;
    line <= 0;
    
    if (initState == NOT_INIT)
    begin
       initState <= INIT_IN_PROGRESS;
       initStep <= 0;
    end
  end
    
  if (getNextCommand & isSending)
  begin
     getNextCommand <= 0;
     if (initState == INIT_IN_PROGRESS)
     begin
        getNextInitCommandTask;
     end else
     if (initState == DONE)
     begin
        getNextTextCommandTask;
     end     
     
     sendCommandReg <= 1'b1;
  end

  if (commandDone)
  begin     
     sendCommandReg <= 0;
     if (initState == INIT_IN_PROGRESS)
     begin
        getNextCommand <= 1'b1;
        if (isLastInitStep) 
           initState <= DONE; 
        else
           initStep <= initStep + 1'b1;
     end else     
     if (initState == DONE)
     begin
        highNibble <= ~highNibble;
        getNextCommand <= highNibble | takeNewChar;
        currentChar <= currentChar + takeNewChar;
        isSending <= ~isLastTransfer;
        sendingDone <= isLastTransfer;        
     end
  end  
end

logic commandDone;
logic sendCommandReg = 0;

lcd_transfer lcd(.CLK(CLK), .sendCommand(sendCommandReg), .command(currentCommand), .commandDelay(currentDelay), .commandDone(commandDone), .LCD_D(LCD_D), .LCD_E(LCD_E));
endmodule