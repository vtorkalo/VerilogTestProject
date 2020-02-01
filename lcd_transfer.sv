module lcd_transfer(
  input logic CLK,
  input logic sendCommand,   
  input logic [4:0] command,
  input logic [20:0] commandDelay,
  inout [4:0] LCD_D,
  output logic LCD_RW,
  output logic LCD_E,
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
   end
   state_reg <= state_next;
end


logic [4:0] commandReg;
logic [20:0] commandDelayReg;

logic timer_reset;
logic [20:0] timer_reg;
logic [20:0] timer_next;
assign timer_next = timer_reset ? 1'b0: timer_reg + 1;

typedef enum bit[3:0] {idle, data_raise, clock_e, data_fall, delay, done_tick} state_type;
state_type state_reg, state_next;

logic store_command;

always_comb
begin
   store_command = 1'b0;
   commandDone = 1'b0;
   timer_reset = 1'b0;
   state_next = state_reg;
   LCD_D = 1'b0;
   LCD_E = 1'b0;
      
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
            LCD_D = commandReg;
            if (timer_reg == RAISE_TIME)
            begin
               state_next = clock_e;
               timer_reset = 1'b1;
               LCD_E = 1'b1;
            end
         end
      clock_e:
         begin
            LCD_D = commandReg;
            LCD_E = 1'b1;
            if (timer_reg == E_CLOCK_TIME)
            begin
               state_next = data_fall;
               LCD_E = 1'b0;
               timer_reset = 1'b1;
            end
         end         
       data_fall:
         begin
            LCD_D = commandReg;
            
            if (timer_reg == FALL_TIME)
            begin
               state_next = delay;
               LCD_D = 1'b0;
               timer_reset = 1'b1;
            end
         end        
       delay:
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