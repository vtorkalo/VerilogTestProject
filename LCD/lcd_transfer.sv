module lcd_transfer(
  input logic CLK,
  input logic sendCommand,   
  input logic [3:0] command,
  input logic command_rs,
  input logic [20:0] commandDelay,
  inout [3:0] LCD_D,
  output logic LCD_RW,  
  output logic LCD_E,
  output logic LCD_RS,
  output logic commandDone
);

localparam FREQ = 50000000;
localparam t1_uS = FREQ / 1000000;

localparam E_CLOCK_TIME = t1_uS * 3;
localparam RAISE_TIME = t1_uS * 1;
localparam FALL_TIME = t1_uS * 1;


always_ff @(posedge CLK)
begin
   timer_reg <= timer_next;
   if (store_command)
   begin
      commandReg <= command;
      commandDelayReg <= commandDelay;
      commandRsReg <= command_rs;
   end
   state_reg <= state_next;
   LCD_D_reg <= LCD_D_next;
   LCD_E <= LCD_E_next;
   LCD_RS <= LCD_RS_next;
end


logic [3:0] commandReg;
logic commandRsReg;
logic [20:0] commandDelayReg;

logic timer_reset;
logic [20:0] timer_reg;
logic [20:0] timer_next;
assign timer_next = timer_reset ? 1'b0: timer_reg + 1'b1;

typedef enum bit[3:0] {idle, data_raise, clock_e, data_fall, busy, done_tick} state_type;
state_type state_reg, state_next;

logic store_command;

logic [3:0] LCD_D_reg, LCD_D_next;
logic LCD_E_next, LCD_RS_next;

logic read_mode;
assign LCD_D = read_mode ? 5'bZ : LCD_D_reg;

always_comb
begin
   read_mode = 1'b0;
   store_command = 1'b0;
   commandDone = 1'b0;
   timer_reset = 1'b0;
   state_next = state_reg;
   LCD_D_next = LCD_D_reg;
   LCD_E_next = LCD_E;   
   LCD_RS_next = LCD_RS;
   LCD_D_next = LCD_D_reg;
      
   case (state_reg)
      idle:
         begin
            if (sendCommand)
            begin
               store_command = 1'b1;   
               state_next = data_raise;
               timer_reset = 1'b1;
            end
         end
      data_raise:
         begin
            LCD_D_next = commandReg;
            LCD_RS_next = commandRsReg;
            if (timer_reg == RAISE_TIME)
            begin
               state_next = clock_e;
               timer_reset = 1'b1;
               LCD_E_next = 1'b1;
            end
         end
      clock_e:
         begin
            LCD_D_next = commandReg;
            LCD_E_next = 1'b1;
            if (timer_reg == E_CLOCK_TIME)
            begin
               state_next = data_fall;
               LCD_E_next = 1'b0;
               timer_reset = 1'b1;
            end
         end         
       data_fall:
         begin
            LCD_D_next = commandReg;
            
            if (timer_reg == FALL_TIME)
            begin
               state_next = busy;
               //read_mode = 1'b1;
               LCD_D_next = 1'b0;
               LCD_RS_next = 1'b0;
               timer_reset = 1'b1;
            end
         end        
       busy:
         begin
            if (timer_reg == commandDelayReg)
            begin
               state_next = done_tick;
               commandDone = 1'b1;
               timer_reset = 1'b1;
            end
         end
       done_tick:
         begin
            commandDone = 1'b0;
            state_next = idle;
         end
   endcase
end


endmodule