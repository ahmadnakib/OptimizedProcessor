--Adapted from Example 12-15 of Quartus Design and Synthesis handbook
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use STD.textio.all;
use ieee.std_logic_textio.all;

entity memory is
	generic(
		ram_size : integer := 32768;
		mem_delay : time := 10 ns;
		clock_period : time := 1 ns
	);
	port (
		clock: in std_logic;

		inst_write: in std_logic_vector (31 downto 0);
		data_write: in std_logic_vector (31 downto 0);
		inst_add: in integer range 0 to 4*ram_size - 4;
		data_add: in integer range 0 to 4*ram_size - 4;
		inst_write_mem: in std_logic;
		data_write_mem: in std_logic;
		inst_read_mem: in std_logic;
		data_read_mem: in std_logic;
		inst_wait: out std_logic;
		data_wait: out std_logic;
		data_read: out std_logic_vector (31 downto 0);
		inst_max: out integer :=0;
		fin_read: in std_logic;
		reg_write: in std_logic

	);
end memory;

architecture rtl of memory is
	type MEM is array(ram_size-1 downto 0) of std_logic_vector(31 downto 0);
	signal ram_block: MEM;
	signal inst_read_wait: std_logic := '1';
	signal data_write_wait: std_logic := '1';
	signal data_read_wait: std_logic := '1';
	signal inst_address: integer range 0 to ram_size-1 :=0;
	signal data_address: integer range 0 to ram_size-1 :=0;
	signal count: integer := 0;
	signal recover_flag: std_logic:='0';
	signal mem_wait: std_logic:= '1';
	signal inst_stall: std_logic := '0';
	signal data_stall: std_logic:='0';        
	signal inst_inline_wait : std_logic:= '0';
	signal data_read_inline_wait : std_logic:= '0';
	signal data_write_inline_wait : std_logic:= '0';
	signal inst_read_re: std_logic := '0';
	signal data_read_re: std_logic := '0';
	signal data_write_re: std_logic := '0';
	signal inst_new:std_logic:= '0';
	signal data_new:std_logic:= '0';
	signal both: std_logic := '0';
	signal test: std_logic_vector(31 downto 0);
	signal ic_r_flag: std_logic := '0';
	signal dc_r_flag: std_logic:='0';
	signal dc_w_flag: std_logic:='0';

        
begin
	inst_address <= inst_add/4;
	data_address <= data_add/4;
    test <= ram_block(1);
    inst_new <= inst_read_mem or inst_read_re;
    data_new <= data_read_mem or data_write_mem or data_read_re or data_write_re;
    both <= inst_new and data_new;

	mem_process: PROCESS (inst_read_mem,data_write_mem,data_read_mem,mem_wait,clock,inst_read_wait,inst_read_re,data_read_re,data_write_re)	
		file program: text;
		variable mem_line: line;
		variable fstatus: file_open_status;
		variable read_data: std_logic_vector(31 downto 0):=(others=>'0');
		variable count: integer := 0;
		begin
			if(now < 1 ps and clock 'event)then  
				for i in 0 to ram_size-1 loop
					ram_block(i) <= std_logic_vector(to_unsigned(i,32));
				end loop;
				file_open(fstatus,program,"program.txt", read_mode);
				while not endfile(program) loop
					readline(program,mem_line);
					read(mem_line,read_data);
					ram_block(count) <= read_data;
					count := count+1;
				end loop;
				file_close(program);
				inst_max <= count;
			end if;
			
			if(both = '1') then 
				data_stall <= '0';
				inst_stall <= '1';
				inst_inline_wait <= '1';
				if  (data_write_re = '1' or data_write_mem = '1') then 
					ram_block(data_address) <= data_write;	              
				elsif (data_read_re = '1' or data_read_mem = '1')then 
					data_read <= ram_block(data_address);	
				end if;
            elsif((falling_edge(data_write_re) or falling_edge(data_write_mem)) and data_stall = '0') then
				ram_block(data_address) <= data_write;	
	        elsif((falling_edge(data_write_re) or falling_edge(data_write_mem)) and data_stall = '1') then
				if(inst_stall = '1') then 
					data_stall <= '0';
					ram_block(data_address) <= data_write;
				else 
					data_write_inline_wait <= '1';
				end if;
			elsif((falling_edge(data_read_re) or falling_edge(data_read_mem))and data_stall = '0') then     
				data_read <= ram_block(data_address);	
            elsif((falling_edge(data_read_re) or falling_edge(data_read_mem))and data_stall = '1') then   
				if(inst_stall = '1') then 
						data_stall <= '0';
						data_read <= ram_block(data_address);	 
				else
						data_read_inline_wait <= '1';
				end if;

			elsif((falling_edge(inst_read_re) or falling_edge(inst_read_mem)) and inst_stall = '0' ) then
		 		data_read <= ram_block(inst_address);
            elsif((falling_edge(inst_read_re) or falling_edge(inst_read_mem)) and inst_stall = '1' ) then
				inst_inline_wait <= '1';
			end if;

            if(falling_edge(mem_wait)) then 
				inst_stall <= '0';
				if(inst_inline_wait = '1')then 
					data_stall <= '1'; 
					inst_read_re<= '1';                           
					inst_inline_wait <='0';
				end if;  
			elsif(rising_edge(mem_wait)) then 
				inst_read_re <= '0';
			elsif(falling_edge(inst_read_wait))then 
				data_stall <='0';
				if(data_write_inline_wait = '1')then 
					inst_stall <= '1'; 
					data_write_re <= '1'; 
					data_write_inline_wait <= '0';
				elsif(data_read_inline_wait = '1')then 
					inst_stall <= '1';
					data_read_re <= '1';  	
					data_read_inline_wait <= '0';
				end if;
			elsif(rising_edge(inst_read_wait))then 
				data_read_re <= '0'; 
				data_write_re <= '0';      
			elsif((rising_edge(data_write_mem)or rising_edge(data_read_mem))and(data_stall = '0')) then                      
				inst_stall <= '1';  
			elsif(rising_edge(inst_read_mem) and inst_stall = '0')then 
				data_stall <= '1';
							   
			end if;
	end process;


	waitreq_w_proc_datacache: process (data_write_mem,recover_flag,data_write_inline_wait)
	begin
        if(falling_edge(recover_flag))then 
			if(dc_w_flag = '1'and data_stall = '0')then 
			   data_write_wait<='1','0' after 9.5*clock_period;
			   dc_w_flag <= '0';
			else
				data_write_wait<='1';
			end if;
		end if;
		if((falling_edge(data_write_inline_wait))or (rising_edge(data_write_mem) ))then
			data_write_wait <= '0' after mem_delay;
            dc_w_flag<= '1';
		end if;
	end process;

	waitreq_r_proc_datacache: process (data_read_mem,recover_flag,data_read_inline_wait)
	begin
        if(falling_edge(recover_flag))then 
			if(dc_r_flag = '1' and data_stall = '0')then 
			   data_read_wait<='1','0' after 9.5*clock_period;
			   dc_r_flag <= '0';
			else
				data_read_wait<='1';
			end if;
		end if;
		if((falling_edge(data_read_inline_wait))or(rising_edge(data_read_mem) ))then
			data_read_wait <= '0' after mem_delay;
            dc_r_flag <= '1';
		end if;
	end process;

	data_wait <= data_write_wait and data_read_wait;
	mem_wait <=  data_write_wait and data_read_wait;
		
	waitreq_r_proc_instcache: process (inst_inline_wait,inst_read_mem,recover_flag)
	begin
        if(falling_edge(recover_flag))then 
			if(ic_r_flag = '1' and inst_stall = '0')then 
			   inst_read_wait<='1','0' after 9.5*clock_period;
			   ic_r_flag <= '0';
			else
				inst_read_wait<='1';
			end if;
		end if;
		if(falling_edge(inst_inline_wait)or (rising_edge(inst_read_mem) and inst_stall = '0' ))THEN
			inst_read_wait <='0' after mem_delay;
            ic_r_flag <= '1';
                        
		end if;
	end process;
      
    recover :process(clock,inst_read_wait,data_write_wait,data_read_wait)
        begin 
            if(falling_edge(inst_read_wait) or falling_edge(data_read_wait) or falling_edge(data_write_wait))then 
                recover_flag <= '1';
            elsif(rising_edge(clock))then 
                recover_flag<= '0';
            end if;
        end process;



	inst_wait <= inst_read_wait;
	


	output: process (reg_write)
		file memoryfile : text;
		variable line_num : line;
		variable fstatus: file_open_status;
        variable reg_value  : std_logic_vector(31 downto 0);
	begin
		if(reg_write = '1') then 
			file_open(fstatus, memoryfile, "memory.txt", write_mode);
			for i in 0 to 32767 loop
				reg_value := ram_block(i);
				write(line_num, reg_value);
				writeline(memoryfile, line_num);
			end loop;
			file_close(memoryfile);
		end if;
		end process;	

END rtl;