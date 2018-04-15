LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

entity ifprocess IS
	PORT(
		clock: in STD_LOGIC;
		reset: in std_logic := '0';
		stall: in std_logic := '0';
		miss: in std_logic := '0';
		memStall: in std_logic; 
		branAddress: in STD_LOGIC_VECTOR (31 DOWNTO 0);
		takenBranch: in STD_LOGIC := '0';
		nextAddress: out STD_LOGIC_VECTOR (31 DOWNTO 0);
		maxInst: in integer;
		instruction: out std_logic_vector(31 downto 0);	   -- send instruction to ID
		s_addr_inst: out std_logic_vector(31 downto 0);    -- send address to cache
		s_read_inst: out std_logic; 					   -- send read signal to cache
		s_waitrequest_inst: in std_logic :='0'; 		   -- get waitrequest signal from cache
		s_readdata_inst: in std_logic_vector(31 downto 0)  -- get instruction from cache
		
	);
END ifprocess;

ARCHITECTURE behavioral of ifprocess IS

	signal pc: STD_LOGIC_VECTOR (31 DOWNTO 0):= (others => '0');
	signal pcPlus4: STD_LOGIC_VECTOR (31 DOWNTO 0):= (others => '0');
    signal no_accept: std_logic:='0';
begin

process (pcPlus4,takenBranch)
begin
	if(rising_edge(takenBranch)) and (stall = '0') and (memStall = '0')then
		pc <= branAddress;
	elsif  (stall = '0' and memStall = '0' and pcPlus4'event ) then
		pc <= pcPlus4;               
	end if;
end process;

process(miss,s_waitrequest_inst,clock,takenBranch)
begin
    if(rising_edge(takenBranch) and miss= '1')then 
        no_accept <= '1';
    end if;

	if(stall = '0' and memStall = '0') then
        if(rising_edge(takenBranch)and miss= '0') then
            s_addr_inst <= branAddress; 
        end if;
	    if(rising_edge(clock)) then
	        s_read_inst <= '0';
            if(miss = '0') then 
                s_addr_inst <= pc; -- send address to cache   
            end if;
        end if;
		if(rising_edge(miss)) then
			instruction <= x"00000020"; -- read miss
		elsif(falling_edge(clock) and miss = '1') then
			instruction <= x"00000020"; -- read miss
		elsif(falling_edge(clock) and miss = '0' ) then
			pcPlus4 <= std_logic_vector(to_unsigned( to_integer(unsigned(pc)) + 4,32));
			nextAddress <= pc;
			if( to_integer(unsigned(pc)) < maxInst*4) then 
				s_read_inst <= '1'; -- send read signal
            else        
                instruction <= x"00000020";  
            end if;

		elsif (falling_edge(s_waitrequest_inst)) then
			if( to_integer(unsigned(pc)) > maxInst*4) then         
                instruction <= x"00000020";  
            elsif(no_accept ='1')then 
                instruction <= x"00000020";  
                no_accept<= '0';
            else
                instruction <= s_readdata_inst; -- get instruction from cache
		    end if;	
		end if;
		

end if;

end process;
end behavioral;
