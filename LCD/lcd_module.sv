module lcd_module(
  input logic CLK,
  input logic RESET,
  input logic sendText,
  input logic [8 * LINE_LENGTH : 1] line1,
  input logic [8 * LINE_LENGTH : 1] line2,
  inout [3:0] LCD_D,
  output logic LCD_RS,
  output logic LCD_E,
  output logic LCD_RW,
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


logic notInitialized;
assign notInitialized = state_reg == not_init | state_reg == send_init_command;
                              
lcd_init lcd_init(.CLK(CLK),
   .RESET(RESET),
   .startInit(startInit_tick),
   .initDone(initDone),
   .commandDone(commandTransferDone),
   .commandToSend(commandToSend_init),
   .read_busy(read_busy_init),
   .mode4bit(mode4bit_init),
   .sendCommand_tick(sendCommand_tick_init)
);
logic commandToSend_init;
logic sendCommand_tick_init;
logic mode4bit_init;
logic sendText_tick;
logic read_busy_init;
logic command_rs_init;

logic commandToSend_text;
lcd_send_text lcd_text(.CLK(CLK),
   .RESET(RESET),
   .sendText(sendText_tick),
   .line1(line1),
   .line2(line2),
   .read_busy(read_busy_text),
   .commandToSend(commandToSend_text),
   .commandToSendRs(command_rs_text),
   .sendingDone(sendingDone),
   .commandDone(commandTransferDone),
   .sendCommand_tick(sendCommand_tick_text)
   
);
logic read_busy_text;
logic sendCommand_tick_text;
logic commandTransferDone;
logic mode4bit;
logic command_rs_text;


assign mode4bit = notInitialized ? mode4bit_init : 1'b0;

logic transferCommand;
assign tranferCommand = notInitialized ? sendCommand_tick_init : sendCommand_tick_text;
logic read_busy;
assign read_busy = notInitialized ? read_busy_init : read_busy_text;

logic commandToTransfer;
assign commandToTransfer = notInitialized ? commandToSend_init : commandToSend_text;
logic transferCommand_tick;
assign transferCommand_tick = notInitialized ? sendCommand_tick_init : sendCommand_tick_text;
logic command_rs_toTransfer;
assign command_rs_toTransfer = notInitialized ? 1'b0 : command_rs_text;
   
lcd_transfer lcd(.CLK(CLK),
   .sendCommand(transferCommand_tick),
   .command(commandToTransfer),
   .commandDone(commandTransferDone),
   .command_rs(command_rs_toTransfer),
   .read_busy(read_busy),
   .LCD_D(LCD_D),
   .mode4bit(mode4bit),   
   .LCD_E(LCD_E),
   .LCD_RW(LCD_RW),
   .LCD_RS(LCD_RS));
   
   
endmodule