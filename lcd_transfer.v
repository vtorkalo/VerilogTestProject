module lcd_transfer(
  input CLK,
  input sendCommand,   
  input [4:0] command,
  input [20:0] commandDelay,
  output reg [4:0] LCD_D,
  output reg LCD_E,
  output reg commandDone
);

reg [7:0] e_timer;
reg e_timer_en;

reg [20:0] delay_timer;
reg delay_timer_en;

reg [7:0] data_fall_timer;
reg data_fall_timer_en;

reg [7:0] data_raise_timer;
reg data_raise_timer_en;

task data_raise_timer_start;
begin
   data_raise_timer <= 0; 
   data_raise_timer_en <= 1;
end
endtask

task data_raise_timer_stop;
begin
   data_raise_timer <= 0;  
   data_raise_timer_en <= 0;
end
endtask

task delay_timer_start;
begin
   delay_timer_en <= 1;
   delay_timer <= 0;
end
endtask

task delay_timer_stop;
begin
   delay_timer_en <= 0;
   delay_timer <= 0;
end
endtask

task data_fall_timer_start;
begin
   data_fall_timer <= 0;
   data_fall_timer_en <= 1;
end
endtask

task data_fall_timer_stop;
begin
   data_fall_timer <= 0;
   data_fall_timer_en <= 0;
end
endtask

task e_sync_start;
begin
   LCD_E <= 1;
   e_timer <= 0;
   e_timer_en <= 1;
end
endtask

task e_sync_stop;
begin
   LCD_E <= 0;  
   e_timer_en <= 0;
   e_timer <= 0;
end
endtask

task increment_timers;
begin
   if (e_timer_en)
   begin
      e_timer <= e_timer + 1;
   end
   if (delay_timer_en)
   begin
      delay_timer <= delay_timer + 1; 
   end
   if (data_fall_timer_en)
   begin
      data_fall_timer <= data_fall_timer + 1;
   end
   if (data_raise_timer_en)
   begin
      data_raise_timer <= data_raise_timer + 1;
   end
end
endtask

reg currentCommand = 0;
reg isSending = 0;

localparam FREQ = 50000000;
localparam t1_uS = FREQ / 1000000;

localparam E_CLOCK_TIME = t1_uS * 3;
localparam RAISE_TIME = t1_uS * 1;
localparam FALL_TIME = t1_uS * 1;

reg [7:0] index = 0;

  reg [4:0] commandReg;
  reg [20:0] commandDelayReg;
  reg setDataBusFlag = 0;

always @(posedge CLK)
begin
   increment_timers;
   
   if (commandDone)
   begin
      commandDone <= 0;
   end
   
   if (sendCommand & ~isSending)
   begin
      setDataBusFlag <= 1;
      commandReg <= command;
      commandDelayReg <= commandDelay;       
   end    	
   
   if (setDataBusFlag)
   begin
      setDataBusFlag <= 0;
      LCD_D <= commandReg;	       
	   data_raise_timer_start;
      isSending <= 1;          
   end
   
   if (data_fall_timer == FALL_TIME & isSending)
   begin
      LCD_D <= 0;
      data_fall_timer_stop;
      index <= index + 1;
   end
   if (data_raise_timer == RAISE_TIME & isSending)
   begin
      data_raise_timer_stop;      
      e_sync_start;      
   end

	if (e_timer == E_CLOCK_TIME & isSending)
	begin		
      e_sync_stop;   	         
      data_fall_timer_start;                        
      delay_timer_start();                       
   end

   if (delay_timer == commandDelayReg & isSending)
   begin
      commandDone <= 1;  
      isSending <= 0;    
      delay_timer_stop;
   end
end
endmodule