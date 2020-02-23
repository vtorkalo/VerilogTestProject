module lcd_transfer(
  input logic CLK,
  input logic sendCommand,   
  input logic [3:0] command,
  input logic command_rs,  
  input logic read_busy,
  input logic mode4bit,
  inout [3:0] LCD_D,
  output logic LCD_RW,  
  output logic LCD_E,
  output logic LCD_RS,
  output logic commandDone
);

localparam FREQ = 50000000;
localparam t1_uS = FREQ / 1000000;

localparam E_CLOCK_TIME = t1_uS * 1;
localparam RAISE_TIME = t1_uS * 2;
localparam FALL_TIME = t1_uS * 2;

logic busy_flag;
assign busy_flag = LCD_D[3];


always_ff @(posedge CLK)
begin
   timer_reg <= timer_next;
   if (store_command)
   begin
      commandReg <= command;
      commandRsReg <= command_rs;
      read_busy_reg <= read_busy;
      mode4bit_reg <= mode4bit;
   end
   state_reg <= state_next;
   LCD_D_reg <= LCD_D_next;
   LCD_E <= LCD_E_next;
   LCD_RS <= LCD_RS_next;
   read_mode_reg <= read_mode_next;   
   busy_reg <= busy_next;
end


logic [3:0] commandReg;
logic commandRsReg;

logic timer_reset;
logic [7:0] timer_reg;
logic [7:0] timer_next;
assign timer_next = timer_reset ? 1'b0: timer_reg + 1'b1;

typedef enum bit[3:0] {idle, data_raise, clock_e, data_fall, read_data_raise, read_data_clock_e, read_data_fall, read_data_raise2, read_data_clock_e2, read_data_fall2,done_tick} state_type;
state_type state_reg, state_next;

logic store_command;

logic [3:0] LCD_D_reg, LCD_D_next;
logic LCD_E_next, LCD_RS_next;

assign LCD_RW = read_mode_reg;
logic read_mode_reg, read_mode_next;
assign LCD_D = read_mode_reg ? 4'bZZZZ : LCD_D_reg;
logic read_busy_reg;
logic busy_reg, busy_next;
logic mode4bit_reg;

always_comb
begin
   store_command = 1'b0;
   commandDone = 1'b0;
   timer_reset = 1'b0;
   state_next = state_reg;
   LCD_E_next = LCD_E;   
   LCD_RS_next = LCD_RS;
   LCD_D_next = LCD_D_reg;
   read_mode_next = read_mode_reg;
   busy_next = busy_reg;
         
   case (state_reg)
      idle:
         begin
            if (sendCommand)
            begin
               busy_next = 1'b1;
               store_command = 1'b1;   
               state_next = data_raise;
               timer_reset = 1'b1;
            end
         end
      data_raise:
         begin
            LCD_D_next = commandReg;
            LCD_RS_next = commandRsReg;
            read_mode_next = 1'b0;
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
               if (read_busy_reg)
               begin
                  state_next = read_data_raise;
                  read_mode_next = 1'b1;
                  LCD_D_next = 1'b0;
                  LCD_RS_next = 1'b0;
                  timer_reset = 1'b1;
               end
               else
               begin
                 state_next = done_tick;
                 read_mode_next = 1'b0;
                 commandDone = 1'b1;               
               end
            end
         end        
       read_data_raise:
         begin
            read_mode_next = 1'b1;
            if (timer_reg == RAISE_TIME)
            begin
               timer_reset = 1'b1;
               LCD_E_next = 1'b1;
               state_next = read_data_clock_e;
            end
         end
        read_data_clock_e:
         begin
            if (timer_reg == E_CLOCK_TIME)
            begin
              LCD_E_next = 1'b0;
              timer_reset = 1'b1;     
              state_next = read_data_fall;
              busy_next = busy_flag;
            end
         end         
       read_data_fall:
       begin
          if (timer_reg == FALL_TIME)
          begin
              timer_reset = 1'b1;
              if (busy_reg)
                 state_next = mode4bit_reg ? read_data_raise2 : read_data_raise;
              else
              begin
                 if (mode4bit_reg)
                    state_next = read_data_raise2;
                 else
                 begin
                    state_next = done_tick;
                    read_mode_next = 1'b0;
                    commandDone = 1'b1;
                 end                    
              end                  
          end
       end
       read_data_raise2:
         begin
            if (timer_reg == RAISE_TIME)
            begin
               timer_reset = 1'b1;
               LCD_E_next = 1'b1;
               state_next = read_data_clock_e2;
            end
         end
       read_data_clock_e2:
         begin
            if (timer_reg == E_CLOCK_TIME)
            begin
                LCD_E_next = 1'b0;
                state_next = read_data_fall2;
                timer_reset = 1'b1;
             end
         end         
       read_data_fall2:
       begin
            if (timer_reg == FALL_TIME)
            begin
              if (!busy_reg)
              begin
                 state_next = done_tick;
                 read_mode_next = 1'b0;
                 commandDone = 1'b1;
              end
              else   
              begin                          
                 state_next = read_data_raise;                 
                 timer_reset = 1'b1;
              end
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