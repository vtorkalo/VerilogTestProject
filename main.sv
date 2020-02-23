module main(
  input logic CLK,
  input logic RESET,
  input logic [3:0] buttons,  
  output logic [3:0] DIGIT,
  output logic [7:0] SEG,
  output logic LED,
  
  inout [3:0] LCD_D,
  input [3:0] LCD_D_LOW,
  output logic LCD_E,
  output logic LCD_RW,
  output logic LCD_RS
);

localparam FREQ = 26'd50000000;
localparam [20:0] t1_uS = FREQ / 20'd1000000;


logic button1Up, button2Up, button3Up, button4Up;


always @(posedge CLK)
begin
//   if (level)
	//   level<=0;
   
   if (button1Up)
   begin 
       
   end   


end

debouncer deb_1 (.CLK(CLK), .switch_input(buttons[0]), .trans_up(button1Up));
debouncer deb_2 (.CLK(CLK), .switch_input(buttons[1]), .trans_up(button2Up));
debouncer deb_3 (.CLK(CLK), .switch_input(buttons[2]), .trans_up(button3Up));
debouncer deb_4 (.CLK(CLK), .switch_input(buttons[3]), .trans_up(button4Up));

logic initDone;

logic [3:0] units, tens, hundreds, thousands;


display_decoder decoder(.CLK(CLK), .D0(units), .D1(tens), .D2(hundreds), .D3(thousands), .DIGIT (DIGIT), .SEG(SEG));

//pwm pwm_module(.pwm_clk(counter[3]), .duty(duty), .PWM_PIN(pwm_wire));
//display_decoder decoder(.CLK(CLK), .D0(d0), .D1(d1), .D2(d2), .D3(d3), .DIGIT (DIGIT), .SEG(SEG));


lcd_module lcd_module(.CLK(CLK),
   .RESET(~RESET),
   .sendText(button1Up),
   
   .line1("abcdefghijklmnop"),   
   .line2("qrstuvwxyz123456"),   
   .LCD_D(LCD_D),
   .LCD_E(LCD_E),
   .LCD_RS(LCD_RS),
   .LCD_RW(LCD_RW),
   .sendingDone(LED));
logic reset;
logic tick;
logic tick2;


//edge_detect_mealy mealy(.CLK(CLK), .reset(~buttons[1]), .level(~buttons[3]), .tick(tick));
//tick_gen tick_g(.CLK(CLK), .reset(~buttons[1]), .level(~buttons[3]), .tick(tick));
//tick_gen_book tick_g_book(.CLK(CLK), .reset(~buttons[1]), .level(~buttons[3]), .tick(tick2));

endmodule