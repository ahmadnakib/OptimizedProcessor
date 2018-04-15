LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE STD.textio.all;
USE ieee.std_logic_textio.all;

entity DataMem is
    GENERIC(
		ram_size : INTEGER := 32768
	);
    port(
		clock: in std_logic;
		opcode: in std_logic_vector(5 downto 0):=(others => '0');
		ALU_result: in std_logic_vector(31 downto 0):=(others => '0');
		rt_data: in std_logic_vector(31 downto 0):=(others => '0');
		memoryData: out std_logic_vector(31 downto 0):=(others => '0');
		ALU_data: out std_logic_vector(31 downto 0):=(others => '0');
		
		control_buffer_MEM: in std_logic_vector(5 downto 0):=(others => '0');
		control_buffer_WB : in std_logic_vector(5 downto 0):=(others => '0');
		MEM_control_buffer_out: out std_logic_vector(5 downto 0):=(others => '0'); 
		WB_control_buffer_out : out std_logic_vector(5 downto 0):=(others => '0');
		
		branchTaken: in std_logic;  -- from mem
		input_branch_address: in std_logic_vector(31 downto 0):=(others => '0');
		output_destination_address: out std_logic_vector(4 downto 0):=(others => '0');
		input_destination_address: in std_logic_vector(4 downto 0):=(others => '0');
		
	 
		branchAddress: out std_logic_vector(31 downto 0):=(others => '0');
		output_branch_taken: out std_logic:= '0'; 
		write_reg_txt: in std_logic := '0';

		mem_data_stall_in: in std_logic;
		mem_data_stall: out std_logic:='0';

		s_addr_data:out std_logic_vector(31 downto 0):=(others => '0');
		s_read_data: out std_logic:='0';
		s_readdata_data: in std_logic_vector(31 downto 0);
		s_write_data: out std_logic:='0';
		s_writedata_data: out std_logic_vector(31 downto 0):=(others => '0');
		s_waitrequest_data: in std_logic := '0'                			
         );
end DataMem;

architecture behavior of DataMem is
    signal c_work: std_logic := '0';
	signal writing: std_logic := '0';
	signal reading: std_logic := '0';
begin
	MEM_control_buffer_out<= control_buffer_MEM;
 	branchAddress <= input_branch_address;
 
    extra:process(ALU_result)
		begin
			if(mem_data_stall_in  = '0')then 
				s_addr_data <= ALU_result;
			end if;
    end process;
	
    process(clock,s_waitrequest_data)
		begin
			if(rising_edge(clock)) then
				output_destination_address <= input_destination_address;
				output_branch_taken<= branchTaken;
				if(opcode = "101011") then                  		
					if(c_work = '0') then		
						s_writedata_data <= rt_data;
						s_write_data <= '1';
						c_work <= '1';
						writing <= '1';
					end if;
				elsif(opcode = "100011") then     
					if(c_work = '0') then
						s_read_data <= '1';
						c_work <= '1';
						reading <= '1';
					end if;
				else
					ALU_data <= ALU_result;
				end if;			
			elsif(falling_edge(clock))then
				WB_control_buffer_out<= control_buffer_WB;
				s_write_data <= '0';
                s_read_data <= '0';
                if((opcode = "101011" or opcode = "100011") and  s_waitrequest_data = '1') then
                    mem_data_stall <= '1';       
                end if;
			end if;
	 				
			if(falling_edge(s_waitrequest_data))then 
				if( writing = '1') then
                    mem_data_stall <= '0';         
					writing <= '0';
					c_work <= '0';
				elsif(reading = '1') then
                    mem_data_stall <= '0';     
					memoryData <= s_readdata_data;
					c_work <= '0';
					reading <= '0';
				end if;
         end if;
    end process;  	
end behavior;