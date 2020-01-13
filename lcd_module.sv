module lcd_module(
  input logic CLK,
  input logic RESET,
  input logic sendText,
  input logic [8 * LINE_LENGTH : 1] line1,
  input logic [8 * LINE_LENGTH : 1] line2,
  output logic [4:0] LCD_D,
  output logic LCD_E,
  output logic sendingDone
);

localparam LINE_LENGTH = 6'd16;

always_ff @(posedge CLK, posedge RESET)
begin
   if (RESET)
   begin
      state_reg <= not_init;
   end
   else
   begin
      state_reg <= state_next;
   end
end

typedef enum bit[4:0] {not_init, send_init_command, init_done, send_text, sending_done, idle} state_type;
state_type state_reg, state_next;


always_comb
begin
   state_next = state_reg;
   startInit_tick = 1'b0;
   sendText_tick = 1'b0;

   if (initDone)
   begin
   
   end
   
   case (state_reg)
      not_init:
      begin
        if (sendText)
           state_next = send_init_command;
      end
      send_init_command:
      begin
         startInit_tick = 1'b1;      
         if (initDone)
            state_next = init_done;
      end
      init_done:
      begin
         state_next = send_text;
      end      
      send_text:
      begin
         sendText_tick = 1'b1;
         if (sendingDone)
            state_next = idle;
      end
      idle:
      begin
        if (sendText)
        begin
           state_next = send_text;
        end 
      end
   endcase

end

logic startInit_tick;
logic initDone;

logic [4:0] LCD_D_init;
logic LCD_E_init;

logic [4:0] LCD_D_text;
logic LCD_E_text;

logic notInitialized;
assign notInitialized = state_reg == not_init | state_reg == send_init_command;

assign LCD_D = notInitialized ? LCD_D_init : LCD_D_text;
assign LCD_E = notInitialized ? LCD_E_init : LCD_E_text;


lcd_init_comb lcd_init(.CLK(CLK),
   .RESET(RESET),
   .startInit(startInit_tick),
   .LCD_D(LCD_D_init),
   .LCD_E(LCD_E_init),
   .initDone(initDone));

logic sendText_tick;


lcd_send_text lcd_text(.CLK(CLK),
   .RESET(RESET),
   .sendText(sendText_tick),
   .line1(line1),
   .line2(line2),
   .LCD_D(LCD_D_text),
   .LCD_E(LCD_E_text),
   .sendingDone(sendingDone));
   
   
endmodule