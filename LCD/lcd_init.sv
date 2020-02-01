module lcd_init(
  input logic CLK,
  input logic RESET,
  input logic startInit,
  input logic busy_flag,
  output logic [3:0] LCD_D, 
  output logic LCD_E,
  output logic LCD_RW,
  output logic LCD_RS,
  output logic initDone,
  output logic READ
);

localparam FREQ = 26'd50000000;

localparam [20:0] t1_uS = FREQ / 20'd1000000;
localparam [20:0] t10us = t1_uS * 4'd10; 
localparam [20:0] t53us = t1_uS * 6'd53;
localparam [20:0] t100us = t1_uS * 7'd100;  
localparam [20:0] t3ms = t1_uS * 13'd3000;
localparam [20:0] t4_1ms = t1_uS * 13'd4100;

task getNextInitCommandTask;
begin
  //http://web.alfredstate.edu/faculty/weimandn/lcd/lcd_initialization/lcd_initialization_index.html   
  LCD_RS_next = 1'b0;
  case (initStep_reg)
     0:  begin  currentCommand_next = 4'b0011;  currentDelay_next = t4_1ms; read_busy_next = 1'b1;  end
     1:  begin  currentCommand_next = 4'b0011;  currentDelay_next = t100us; read_busy_next = 1'b1;  end
     2:  begin  currentCommand_next = 4'b0011;  currentDelay_next = t100us; read_busy_next = 1'b1;  end
     3:  begin  currentCommand_next = 4'b0010;  currentDelay_next = t100us; read_busy_next = 1'b1;  end        
     
     4:  begin  currentCommand_next = 4'b0010;  currentDelay_next = t10us; read_busy_next = 1'b0;   end             
     5:  begin  currentCommand_next = 4'b1100;  currentDelay_next = t53us; read_busy_next = 1'b1;   end // function set 
     
     6:  begin  currentCommand_next = 4'b0000;  currentDelay_next = t10us; read_busy_next = 1'b0;   end     
     7:  begin  currentCommand_next = 4'b1000;  currentDelay_next = t53us; read_busy_next = 1'b1;   end // display on off control        
     
     8:  begin  currentCommand_next = 4'b0000;  currentDelay_next = t10us; read_busy_next = 1'b0;   end
     9:  begin  currentCommand_next = 4'b0001;  currentDelay_next = t3ms; read_busy_next = 1'b1;   end // clear display
                
     10: begin  currentCommand_next = 4'b0000;  currentDelay_next = t10us; read_busy_next = 1'b0;   end
     11: begin  currentCommand_next = 4'b0110;  currentDelay_next = t53us; read_busy_next = 1'b1;   end// entry mode sed id and s
        
     12: begin  currentCommand_next = 4'b0000;  currentDelay_next = t10us; read_busy_next = 1'b0;   end
     13: begin  currentCommand_next = 4'b1100;  currentDelay_next = t53us; read_busy_next = 1'b1;   end// set blink cursor display on off control set d=1 b and c           
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
      read_busy_reg <= read_busy_next;
      LCD_RS <= LCD_RS_next;
   end
end

typedef enum bit[4:0] {not_init, send_init_command, init_done, go_line1, go_line2, send_high_nibble, send_low_nibble} state_type;

logic [3:0] currentCommand_reg, currentCommand_next;
logic [20:0] currentDelay_reg, currentDelay_next;
logic sendCommand_tick_reg, sendCommand_tick_next;

logic [5:0] currentChar_reg, currentChar_next;
logic line;
state_type state_reg, state_next;
logic [3:0] initStep_reg, initStep_next;

logic getNextInitStep;
logic initDone_tick;
logic LCD_RS_next;
logic read_busy_reg, read_busy_next;


always_comb
begin
   LCD_RS_next = LCD_RS;
   state_next = state_reg;
   initStep_next = initStep_reg;
  
   currentCommand_next = currentCommand_reg;
   currentDelay_next = currentDelay_reg;

   sendCommand_tick_next = 1'b0;
   initDone_tick = 1'b0;
   read_busy_next = read_busy_reg;
  
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
   .read_busy(read_busy_reg),
   .LCD_D(LCD_D),
   .busy_flag(busy_flag),
   .LCD_E(LCD_E),
   .LCD_RW(LCD_RW),
   .READ(READ));
   
endmodule