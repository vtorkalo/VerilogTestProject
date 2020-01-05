module main(
  input CLK,
  input [3:0] buttons,
  
  output [3:0] DIGIT,
  output [7:0] SEG,
  output LED,
  
  output [4:0] LCD_D,
  output LCD_E
  
);

wire button1;
assign button1 = buttons[0];

wire button2;
assign button2 = buttons[1];

wire button3;
assign button3 = buttons[2];

wire button4;
assign button = buttons[3];

wire button1Up, button2Up, button3Up, button4Up;

reg sendText_trig = 0;

assign sendTextWire = button1Up;



reg [8 * 34 : 1] text = "\nabcdefghijklmnop\nqrstuvwxyz123456";

reg [27:0] prescaler;
reg textFlag = 0;
reg ledstate = 0;

always @(posedge CLK)
begin
   prescaler <= prescaler + 1;

   if (sendText_trig)
   begin   
   sendText_trig <= 0;
     
   end
   if (button1Up)
   begin      
      textFlag <= ~textFlag;
      if (textFlag)
         text <="\nabcdefghijklmnop\nqrstuvwxyz123456"; else
       text <="\n0123456789123456\n0123456789123456";
   end
   
   if (button2Up)
   begin

   end
   
   if (prescaler == 5000000)
   begin
      prescaler <= 0;
      ledstate <= ~ledstate;
   
   end
      
   
   
     

     
   units <= d0;


end

assign LED = ledstate;


debouncer deb_1 (.CLK(CLK), .switch_input(button1), .trans_up(button1Up));
debouncer deb_2 (.CLK(CLK), .switch_input(button2), .trans_up(button2Up));
debouncer deb_3 (.CLK(CLK), .switch_input(button3), .trans_up(button3Up));
debouncer deb_4 (.CLK(CLK), .switch_input(button4), .trans_up(button4Up));

wire sendingDone;

reg [3:0] units, tens, hundreds, thousands;

wire [3:0] d0;

//lcd_init lcd(.CLK(CLK), .sendCommand(init_trig), .command(currentCommand), .commandDelay(commandDelay), .commandDone(commandDone), .LCD_D(LCD_D), .LCD_E(LCD_E));

display_decoder decoder(.CLK(CLK), .D0(units), .D1(tens), .D2(hundreds), .D3(thousands), .DIGIT (DIGIT), .SEG(SEG));

//pwm pwm_module(.pwm_clk(counter[3]), .duty(duty), .PWM_PIN(pwm_wire));
//display_decoder decoder(.CLK(CLK), .D0(d0), .D1(d1), .D2(d2), .D3(d3), .DIGIT (DIGIT), .SEG(SEG));

wire sendTextWire;

lcd_init lcd_init(.CLK(CLK), 
   .sendText(sendTextWire),
   .text(text),   
   .LCD_D(LCD_D),
   .LCD_E(LCD_E),
   .sendingDone(sendingDone));

endmodule