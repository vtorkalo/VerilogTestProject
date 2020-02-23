module lcd_init(
  input logic CLK,
  input logic RESET,
  input logic startInit,
  output logic initDone,
  
  input logic commandDone,
  output logic [3:0] commandToSend,
  output logic sendCommand_tick,
  output logic mode4bit,
  output logic read_busy
);

assign commandToSend = currentCommand_reg;
assign mode4bit = mode4bit_reg;
assign read_busy = read_busy_reg;
assign sendCommand_tick = sendCommand_tick_reg;

task getNextInitCommandTask;
begin
  //http://web.alfredstate.edu/faculty/weimandn/lcd/lcd_initialization/lcd_initialization_index.html   
  case (initStep_reg)
     0:  begin  currentCommand_next = 4'b0011;   read_busy_next = 1'b1;  mode4bit_next = 1'b0;  end
     1:  begin  currentCommand_next = 4'b0011;   read_busy_next = 1'b1;  mode4bit_next = 1'b0;  end
     2:  begin  currentCommand_next = 4'b0011;   read_busy_next = 1'b1;  mode4bit_next = 1'b0;  end
     3:  begin  currentCommand_next = 4'b0010;   read_busy_next = 1'b1;  mode4bit_next = 1'b1; end        
     
     4:  begin  currentCommand_next = 4'b0010;   read_busy_next = 1'b0;  mode4bit_next = 1'b1;  end             
     5:  begin  currentCommand_next = 4'b1100;   read_busy_next = 1'b1;  mode4bit_next = 1'b1; end // function set 
     
     6:  begin  currentCommand_next = 4'b0000;   read_busy_next = 1'b0;  mode4bit_next = 1'b1; end     
     7:  begin  currentCommand_next = 4'b1000;   read_busy_next = 1'b1;  mode4bit_next = 1'b1; end // display on off control        
     
     8:  begin  currentCommand_next = 4'b0000;   read_busy_next = 1'b0;  mode4bit_next = 1'b1;  end
     9:  begin  currentCommand_next = 4'b0001;   read_busy_next = 1'b1;  mode4bit_next = 1'b1; end // clear display
                
     10: begin  currentCommand_next = 4'b0000;   read_busy_next = 1'b0;  mode4bit_next = 1'b1;  end
     11: begin  currentCommand_next = 4'b0110;   read_busy_next = 1'b1;  mode4bit_next = 1'b1;  end// entry mode sed id and s
        
     12: begin  currentCommand_next = 4'b0000;   read_busy_next = 1'b0;  mode4bit_next = 1'b1; end
     13: begin  currentCommand_next = 4'b1100;   read_busy_next = 1'b1;  mode4bit_next = 1'b1; end// set blink cursor display on off control set d=1 b and c           
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
      sendCommand_tick_reg <= sendCommand_tick_next;
      initDone <= initDone_tick;
      read_busy_reg <= read_busy_next;
      mode4bit_reg <= mode4bit_next;
   end
end

typedef enum bit[4:0] {not_init, send_init_command, init_done, go_line1, go_line2, send_high_nibble, send_low_nibble} state_type;

logic [3:0] currentCommand_reg, currentCommand_next;
logic sendCommand_tick_reg, sendCommand_tick_next;

logic [5:0] currentChar_reg, currentChar_next;
logic line;
state_type state_reg, state_next;
logic [3:0] initStep_reg, initStep_next;

logic getNextInitStep;
logic initDone_tick;
logic read_busy_reg, read_busy_next;


always_comb
begin
   state_next = state_reg;
   initStep_next = initStep_reg;
   mode4bit_next = mode4bit_reg;
  
   currentCommand_next = currentCommand_reg;

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

logic mode4bit_reg, mode4bit_next;
  
endmodule