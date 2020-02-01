module lcd_send_text(
  input logic CLK,
  input logic RESET,
  input logic sendText,
  input logic [8 * LINE_LENGTH : 1] line1,
  input logic [8 * LINE_LENGTH : 1] line2,
  inout [4:0] LCD_D,
  output logic LCD_E,
  output logic LCD_RW,
  output logic sendingDone
);


localparam LINE_LENGTH = 5'd16;
localparam FREQ = 26'd50000000;


localparam [20:0] t1_uS = FREQ / 20'd1000000;
localparam [20:0] t10us = t1_uS * 4'd10; 
localparam [20:0] t53us = t1_uS * 6'd53;

localparam [4:0] rs1 = 5'b10000;

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
      line_reg <= line_next;
   end
end

typedef enum bit[4:0] {idle, go_line1, go_line2, send_high_nibble, high_nibble_wait, send_low_nibble, low_nibble_wait, next_command } state_type;
state_type state_next, state_reg;


logic [4:0] command_h_reg, command_l_reg, command_h_next, command_l_next, command_reg, command_next;
logic [5:0] charIndex_reg, charIndex_next;
logic sendCommand_reg;


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
   
   case (state_reg)
   idle:
      begin
         if (sendText)
            state_next = go_line1;      
      end
   go_line1:
      begin
         command_h_next = 5'b01000;
         command_l_next = 5'b00000;
         state_next = send_high_nibble;
         line_next = line1_init;
         charIndex_next = 1'b0;
      end
   go_line2:
      begin
        command_h_next = 5'b01100;
        command_l_next = 5'b00000;
        state_next = send_high_nibble;
        line_next = line2_init;
        charIndex_next = 1'b0;
      end
   send_high_nibble:
      begin
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
              command_h_next =  rs1 + line1[highHalfStartIndex +: 4];
              command_l_next =  rs1 + line1[lowHalfStartIndex +: 4];
           end else
           if (line_reg == line2_init)
           begin
              command_h_next = rs1 + line2[highHalfStartIndex +: 4];
              command_l_next = rs1 + line2[lowHalfStartIndex +: 4];
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

logic [20:0] delay;
assign delay = state_reg == send_high_nibble | state_reg == high_nibble_wait ? t10us : 
               state_reg == send_low_nibble  | state_reg == low_nibble_wait  ? t53us : 1'b0;
               
logic sendCommand_tick;

lcd_transfer lcd(.CLK(CLK),
  .sendCommand(sendCommand_reg),
  .command(command_reg),
  .commandDelay(delay),
  .commandDone(commandDone),
  .LCD_D(LCD_D),
  .LCD_E(LCD_E),
  .LCD_RW(LCD_RW));

endmodule