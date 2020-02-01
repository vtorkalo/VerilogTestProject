module lcd_init(
  input logic CLK,
  input logic RESET,
  input logic startInit,
  inout [4:0] LCD_D,
  output logic LCD_E,
  output logic LCD_RW,
  output logic initDone
);

localparam FREQ = 26'd50000000;

localparam [20:0] t1_uS = FREQ / 20'd1000000;
localparam [20:0] t10us = t1_uS * 4'd10; 
localparam [20:0] t53us = t1_uS * 6'd53;
localparam [20:0] t100us = t1_uS * 7'd100;  
localparam [20:0] t3ms = t1_uS * 13'd3000;
localparam [20:0] t4_1ms = t1_uS * 13'd4100;

localparam [4:0] rs1 = 5'b10000;


task getNextInitCommandTask;
begin
  //http://web.alfredstate.edu/faculty/weimandn/lcd/lcd_initialization/lcd_initialization_index.html   
  case (initStep_reg)
     0:  begin  currentCommand_next = 5'b00011;  currentDelay_next = t4_1ms;  end
     1:  begin  currentCommand_next = 5'b00011;  currentDelay_next = t100us;  end
     2:  begin  currentCommand_next = 5'b00011;  currentDelay_next = t100us;  end
     3:  begin  currentCommand_next = 5'b00010;  currentDelay_next = t100us;  end        
     
     4:  begin  currentCommand_next = 5'b00010;  currentDelay_next = t10us;   end             
     5:  begin  currentCommand_next = 5'b01100;  currentDelay_next = t53us;   end // function set 
     
     6:  begin  currentCommand_next = 5'b00000;  currentDelay_next = t10us;   end     
     7:  begin  currentCommand_next = 5'b01000;  currentDelay_next = t53us;   end // display on off control        
     
     8:  begin  currentCommand_next = 5'b00000;  currentDelay_next = t10us;   end
     9:  begin  currentCommand_next = 5'b00001;  currentDelay_next = t3ms;    end // clear display
                
     10: begin  currentCommand_next = 5'b00000;  currentDelay_next = t10us;   end
     11: begin  currentCommand_next = 5'b00110;  currentDelay_next = t53us;   end// entry mode sed id and s
        
     12: begin  currentCommand_next = 5'b00000;  currentDelay_next = t10us;   end
     13: begin  currentCommand_next = 5'b01100;  currentDelay_next = t53us;   end// set blink cursor display on off control set d=1 b and c           
  endcase
end
endtask

always @(posedge CLK, posedge RESET)
begin
   if (RESET)
   begin
     state_reg <= not_init;
     initStep_reg <= 1'b0;
   end
   else
   begin
      state_reg <= state_next;  
      initStep_reg <= initStep_next;
      
      currentCommand_reg <= currentCommand_next;
      currentDelay_reg <= currentDelay_next;
      sendCommand_tick_reg <= sendCommand_tick_next;
      initDone <= initDone_tick;
   end
end

typedef enum bit[4:0] {not_init, send_init_command, init_done, go_line1, go_line2, send_high_nibble, send_low_nibble} state_type;

logic [4:0] currentCommand_reg, currentCommand_next;
logic [20:0] currentDelay_reg, currentDelay_next;
logic sendCommand_tick_reg, sendCommand_tick_next;

logic [5:0] currentChar_reg, currentChar_next;
logic line;
state_type state_reg, state_next;
logic [3:0] initStep_reg, initStep_next;

logic getNextInitStep;
logic initDone_tick;


always_comb
begin
   state_next = state_reg;
   initStep_next = initStep_reg;
  
   currentCommand_next = currentCommand_reg;
   currentDelay_next = currentDelay_reg;

   sendCommand_tick_next = 1'b0;
   initDone_tick = 1'b0;
  
   case (state_reg)
      not_init:
         begin
            if (startInit)
               state_next = send_init_command;            
         end
      send_init_command: 
         begin
            getNextInitCommandTask;
            sendCommand_tick_next = 1'b1;
            
            if (commandDone)
            begin
               initStep_next = initStep_reg + 1;            
            end
            
            if (initStep_reg == 13 & commandDone)
            begin
               state_next = init_done;
               initDone_tick = 1'b1;
            end
         end
      init_done: 
         begin
            initDone_tick = startInit;
         end
   endcase

end
logic commandDone;
logic sendCommand_tick;

lcd_transfer lcd(.CLK(CLK),
   .sendCommand(sendCommand_tick_reg),
   .command(currentCommand_reg),
   .commandDelay(currentDelay_reg),
   .commandDone(commandDone),
   .LCD_D(LCD_D),
   .LCD_E(LCD_E),
   .LCD_RW(LCD_RW));
   
endmodule