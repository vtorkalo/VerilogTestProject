module lcd_send_text(
  input logic CLK,
  input logic RESET,
  input logic sendText,
  input logic [8 * LINE_LENGTH : 1] line1,
  input logic [8 * LINE_LENGTH : 1] line2,
  input logic busy_flag,
  output logic [3:0] LCD_D, 
  output logic LCD_E,
  output logic LCD_RW,
  output logic LCD_RS,
  output logic sendingDone,
  output logic READ
);


localparam LINE_LENGTH = 5'd16;
always_ff @(posedge CLK, posedge RESET)
begin
   if (RESET)
   begin
      state_reg <= idle;
      line_reg <= line1_not_init;
      charIndex_reg <= 1'b0;
   end
   else
   begin
      state_reg <= state_next;
      charIndex_reg <= charIndex_next;
      
      sendCommand_reg <= sendCommand_tick;      
      command_h_reg <= command_h_next;
      command_l_reg <= command_l_next;
      command_reg <= command_next;
      command_rs_reg <= command_rs_next;
      line_reg <= line_next;
      read_busy_reg <= read_busy_next;
   end
end

typedef enum bit[4:0] {idle, go_line1, go_line2, send_high_nibble, high_nibble_wait, send_low_nibble, low_nibble_wait, next_command } state_type;
state_type state_next, state_reg;


logic [3:0] command_h_reg, command_l_reg, command_h_next, command_l_next, command_reg, command_next;
logic command_rs_reg, command_rs_next;
logic [5:0] charIndex_reg, charIndex_next;
logic sendCommand_reg;
logic LCD_RS_next;
logic read_busy_next, read_busy_reg;



typedef enum bit[1:0] {line1_not_init, line1_init, line2_not_init, line2_init } line_state_type;
line_state_type line_reg, line_next;


logic [8:0] lowHalfStartIndex, highHalfStartIndex;
assign lowHalfStartIndex = (LINE_LENGTH-charIndex_reg-1) * 4'd8 + 1'b1;
assign highHalfStartIndex = (LINE_LENGTH-charIndex_reg-1) * 4'd8 + 4'd5;


always_comb
begin
   state_next = state_reg;
   command_h_next = command_h_reg;
   command_l_next = command_l_reg;
   charIndex_next = charIndex_reg;
   sendCommand_tick = 1'b0;
   line_next = line_reg;
   sendingDone = 1'b0;
   command_next = command_reg;
   command_rs_next = command_rs_reg;
   read_busy_next = read_busy_reg;
   
   case (state_reg)
   idle:
      begin
         if (sendText)
            state_next = go_line1;      
      end
   go_line1:
      begin         
         command_rs_next = 1'b0;
         command_h_next = 4'b1000;
         command_l_next = 4'b0000;
         state_next = send_high_nibble;
         line_next = line1_init;
         charIndex_next = 1'b0;
      end
   go_line2:
      begin
        command_rs_next = 1'b0;
        command_h_next = 4'b1100;
        command_l_next = 4'b0000;
        state_next = send_high_nibble;
        line_next = line2_init;
        charIndex_next = 1'b0;
      end
   send_high_nibble:
      begin
         read_busy_next = 1'b0;
         command_next = command_h_reg;
         sendCommand_tick = 1'b1;
         state_next = high_nibble_wait;
      end
   high_nibble_wait:
      begin
        if (commandDone)
         begin
            state_next = send_low_nibble;
         end        
      end   
   send_low_nibble:
      begin
         read_busy_next = 1'b1;   
         command_next = command_l_reg;
         sendCommand_tick = 1'b1;
         state_next = low_nibble_wait;
      end
   low_nibble_wait:
      begin
         if (commandDone)
         begin
            state_next = next_command;
         end
      end
   next_command:
      begin
        if (line_reg == line1_not_init)
        begin
           state_next = go_line1;
        end else
        if (line_reg == line2_not_init)
        begin
           state_next = go_line2;
        end else
        if (charIndex_reg < LINE_LENGTH)
        begin
           charIndex_next = charIndex_reg + 1;
           state_next = send_high_nibble;
           if (line_reg == line1_init)
           begin
              command_rs_next = 1'b1;
              command_h_next = line1[highHalfStartIndex +: 4];
              command_l_next = line1[lowHalfStartIndex +: 4];
           end else
           if (line_reg == line2_init)
           begin
              command_rs_next = 1'b1;
              command_h_next = line2[highHalfStartIndex +: 4];
              command_l_next = line2[lowHalfStartIndex +: 4];
           end
        end else
        begin
           if (line_reg == line2_init)
           begin
              state_next = idle;
              sendingDone = 1'b1;
           end else
           if (line_reg == line1_init)
           begin
              line_next = line2_not_init;
           end
        end        
        
      end
    endcase
end

              
logic sendCommand_tick;

lcd_transfer lcd(.CLK(CLK),
  .sendCommand(sendCommand_reg),
  .command(command_reg),
  .command_rs(command_rs_reg),
  .commandDone(commandDone),
  .LCD_D(LCD_D),
  .read_busy(read_busy_reg),
  .busy_flag(busy_flag),
  .LCD_E(LCD_E),  
  .mode4bit(1'b1),
  .LCD_RS(LCD_RS),
  .LCD_RW(LCD_RW),
  .READ(READ));

endmodule