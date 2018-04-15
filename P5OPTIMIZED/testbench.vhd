library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity testbench is
end testbench;

architecture behaviour of testbench is

	component ifprocess IS
	PORT(
		clock: in STD_LOGIC;
		reset: in std_logic;
		stall: in std_logic := '0';
		miss: in std_logic := '0';
		memStall: in std_logic; 
		branAddress: in STD_LOGIC_VECTOR (31 DOWNTO 0);
		takenBranch: in STD_LOGIC := '0';
		nextAddress: out STD_LOGIC_VECTOR (31 DOWNTO 0);
		maxInst: in integer;
		instruction: out std_logic_vector(31 downto 0);	   -- send instruction to ID
		s_addr_inst: out std_logic_vector(31 downto 0);    -- send address to cache
		s_read_inst: out std_logic; 					   		-- send read signal to cache
		s_waitrequest_inst: in std_logic :='0'; 		   	-- get waitrequest signal from cache
		s_readdata_inst: in std_logic_vector(31 downto 0)  -- get instruction from cache
		
	);
	END component;
  
  	component ID is
		GENERIC(
			  register_size: integer:=32
		);
		PORT( 
		  clk: in  std_logic;
		  
		  input_branch: in std_logic;-- from mem
		  inputRegister: in  std_logic_vector(31 downto 0);
		  WBC: in  std_logic_vector(31 downto 0);
		  ExBuffer: in std_logic_vector(10 downto 0);
		  rs:  out std_logic_vector(31 downto 0);
		  rt:  out  std_logic_vector(31 downto 0);  
		  
		  instructionAddress: in  std_logic_vector(31 downto 0);
		  WBR_Address: in  std_Logic_vector(4 downto 0);
		  output_instruction_address: out std_logic_vector(31 downto 0);
		  jump_Address: out std_logic_vector(25 downto 0);
		  destinationAddress: out std_logic_vector(4 downto 0);
		  
		  --Provide info for forward and hazard deecion, other bits fo signals and targe/source
		  controlBuffer_EX: out std_logic_vector(10 downto 0);
		  controlBuffer_MEM: out std_logic_vector(5 downto 0);
		  controlBuffer_WB: out std_logic_vector(5 downto 0);
		  
		  signExtImm: out  std_logic_vector(31 downto 0);
		  insert_stall: out std_logic;
		  funct_out: out std_logic_vector(5 downto 0);
		  opcode_out: out  std_logic_vector(5 downto 0);
		  write_reg_txt: in std_logic:='0';
		  mem_data_stall: in std_logic
		);
	end component;

	component EX is
        
		PORT( 
			  clk: in  std_logic;
			  inputBranch: in std_logic;

			  instructionAddr: in std_logic_vector(31 downto 0);
			  jumpAddr : in std_logic_vector( 25 downto 0);
			  registerSrc:  in std_logic_vector(31 downto 0);
			  registerTarg:  in  std_logic_vector(31 downto 0);  
			  destAddr: in std_logic_vector(4 downto 0);
			  signExtImm: in  std_logic_vector(31 downto 0);
			  exCtlBuff: in std_logic_vector(10 downto 0); 
			  memCtlBuff: in std_logic_vector(5 downto 0);
			  wbCtlBuff: in std_logic_vector(5 downto 0);
			  op: in  std_logic_vector(5 downto 0);
			  functt: in std_logic_vector(5 downto 0) ;
			  
			  memCtlBuffOld: in std_logic_vector(5 downto 0);
			  wbCtlBuffOld: in std_logic_vector(5 downto 0);
			  wbData: in std_logic_vector(31 downto 0);
			  mem_data_stall: in std_logic;
			  branchAddress: out std_logic_vector(31 downto 0);
			  takenBranch: out std_logic;
			  opOut: out std_logic_vector(5 downto 0);
			  destAddrOut: out std_logic_vector(4 downto 0);
			  ALU_result: out std_logic_vector(31 downto 0);
			  rt_data: out std_logic_vector(31 downto 0);
			  memCtlBuffOut: out std_logic_vector(5 downto 0);
			  wbCtlBuffOut: out std_logic_vector(5 downto 0);
			  exCtlBuffOut: out std_logic_vector(10 downto 0)			  
		);
	end component;
		
	component DataMem is
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
	end component;


	component WB is
		PORT( 
			clk: in  std_logic;
			memory_data: in std_logic_vector(31 downto 0);
			ALU_output: in std_logic_vector(31 downto 0);
			opcode : in std_logic_vector(5 downto 0);
			WB_address: in std_logic_vector(4 downto 0);
			
			controlBuffer_WB: in std_logic_vector(5 downto 0);
			output_WB_ControlBuffer: out std_logic_vector(5 downto 0);
			
			WB_OutData: out std_logic_vector(31 downto 0);
			output_WB_address: out std_logic_vector(4 downto 0);
			mem_data_stall: in std_logic
		);
	end component;

	component InstCache is
		generic(
			ram_size : INTEGER := 32768
		);
		port(
			clock : in std_logic;
			reset : in std_logic;
			
			-- Avalon interface --
			s_addr : in std_logic_vector (31 downto 0);
			s_read : in std_logic;
			s_readdata : out std_logic_vector (31 downto 0);
			s_waitrequest : out std_logic; 
			
			m_addr : out integer range 0 to ram_size-1;
			m_read : out std_logic;
			m_readdata : in std_logic_vector (31 downto 0);
			m_write : out std_logic;
			m_writedata : out std_logic_vector (31 downto 0);
			m_waitrequest : in std_logic;
			miss: out std_logic:='0'
		);
	end component;
	
	component DataCache is
		generic(
			ram_size : INTEGER := 32768
		);
		port(
			clock : in std_logic;
			reset : in std_logic;
			
			-- Avalon interface --
			s_addr : in std_logic_vector (31 downto 0);
			s_read : in std_logic;
			s_readdata : out std_logic_vector (31 downto 0);
			s_write : in std_logic;
			s_writedata : in std_logic_vector (31 downto 0);
			s_waitrequest : out std_logic; 
			
			m_addr : out integer range 0 to ram_size-1;
			m_read : out std_logic;
			m_readdata : in std_logic_vector (31 downto 0);
			m_write : out std_logic;
			m_writedata : out std_logic_vector (31 downto 0);
			m_waitrequest : in std_logic

		);
	end component;
	
	component memory is
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
	end component;


---------------------------------------------------------------------------------
	signal clock : std_logic;
	signal programend: std_logic := '0';
	constant clkPeriod: time := 1 ns;
	signal readDone: std_logic := '0';
	signal instAddr : std_logic_vector (31 downto 0):=(others => '0');
	signal inst : std_logic_vector (31 downto 0):=(others => '0');
	signal wbRegAddr: std_Logic_vector(4 downto 0):= (others => '0'); 
	signal wbData: std_logic_vector(31 downto 0):=(others => '0'); 
	signal exCtlBuffer: std_logic_vector(10 downto 0):=(others => '0');
	signal reset : std_logic;
	signal stall : std_logic := '0';
	signal bAddress : std_logic_vector (31 downto 0):=(others => '0');
	signal bTaken : std_logic := '0';
	signal funct_from_id: std_logic_vector(5 downto 0):=(others => '0');
	signal signExtImm: std_logic_vector(31 downto 0):=(others => '0');
	signal opcode_bt_IdnEx: std_logic_vector(5 downto 0):=(others => '0'); 
	signal exCtlBuffId: std_logic_vector(10 downto 0):=(others => '0');
	signal memCtlBuffId: std_logic_vector(5 downto 0):=(others => '0');
	signal wbCtlBuffId: std_logic_vector(5 downto 0):=(others => '0');
	signal jAddr: std_logic_vector (25 downto 0):=(others => '0');
	signal instAddrId : std_logic_vector (31 downto 0):=(others => '0');
	signal rs: std_logic_vector(31 downto 0):=(others => '0');
	signal rt: std_logic_vector(31 downto 0):=(others => '0');
	signal destAddressId: std_logic_vector(4 downto 0):=(others => '0');
	signal bran_taken_from_ex: std_logic:= '0';
	signal bran_addr_from_ex: std_logic_vector(31 downto 0):=(others => '0');
	signal MEM_control_buffer_from_ex: std_logic_vector(5 downto 0):=(others => '0');
	signal WB_control_buffer_from_ex: std_logic_vector(5 downto 0):=(others => '0');
	signal memCtlBuffMem: std_logic_vector(5 downto 0):=(others => '0'); 
	signal wbCtlBuffWb: std_logic_vector(5 downto 0):=(others => '0');
	signal opcode_bt_ExnMem: std_logic_vector(5 downto 0):=(others => '0'); 
	signal ALU_result_from_ex: std_logic_vector(31 downto 0):=(others => '0');
	signal des_addr_from_ex: std_logic_vector(4 downto 0):=(others => '0');
	signal rt_data_from_ex: std_logic_vector(31 downto 0):=(others => '0');
	signal des_addr_from_mem: std_logic_vector(4 downto 0):=(others => '0');
	signal WB_control_buffer_from_mem: std_logic_vector(5 downto 0):=(others => '0');
	signal opcode_bt_MemnWb: std_logic_vector(5 downto 0):=(others => '0') ;
	signal memory_data: std_logic_vector(31 downto 0):=(others => '0');
	signal alu_result_from_mem: std_logic_vector(31 downto 0):=(others => '0');
	
	signal c_wait_request: std_logic;
	signal mem_data_stall: std_logic:= '0';
	signal s_waitrequest_inst: std_logic:= '1';
	signal s_readdata_inst: std_logic_vector(31 downto 0):=(others => '0');
	signal ismiss: std_logic:= '0';
	signal dc_readdata_data: std_logic_vector(31 downto 0):=(others => '0');
	signal dc_s_waitrequest: std_logic := '1';
	signal ic_s_addr: std_logic_vector(31 downto 0):=(others => '0');
	signal ic_s_read: std_logic:= '0';
	signal m_readdata: std_logic_vector(31 downto 0):=(others => '0');
	signal ic_m_waitrequest: std_logic:= '1';
	-- signal into DataCache
	signal dc_s_addr: std_logic_vector(31 downto 0):=(others => '0');
	signal dc_s_read: std_logic:= '0';
	signal dc_s_write: std_logic:= '0';
	signal dc_s_writedata: std_logic_vector(31 downto 0):=(others => '0');
	signal dc_m_waitrequest: std_logic:= '1';
	-- signal into Main Memory 
	 
	signal writedata_instcache:std_logic_vector (31 downto 0):=(others=>'0');
	signal address_instcache: INTEGER := 0;
	signal memwrite_instcache: std_logic := '0';
	signal memread_instcache:std_logic := '0';
	signal writedata_datacache:std_logic_vector (31 downto 0):=(others=>'0');
	signal address_datacache: INTEGER := 0;
	signal memwrite_datacache:std_logic := '0';
	signal memread_datacache:std_logic := '0';
	signal max_inst: integer :=0;
	
	
--------------------------------------------------------------------

begin
  
fetch : ifprocess

port map (

			memStall => mem_data_stall,
			clock => clock,
			reset => reset,
			stall => stall,
			branAddress => bAddress,
			takenBranch => bTaken,
			nextAddress => instAddr,
			instruction =>  inst,	
			s_addr_inst => ic_s_addr,
			s_read_inst => ic_s_read,
			s_waitrequest_inst => s_waitrequest_inst,
			s_readdata_inst => s_readdata_inst,
			maxInst => max_inst,
			miss => ismiss
			
);
    
decode : ID
generic map (
			register_size => 32
) 
port map (

			mem_data_stall => mem_data_stall,
			clk => clock,
			input_branch => bTaken,
			instructionAddress => instAddr,
			inputRegister => inst,
			WBR_Address => wbRegAddr,
			WBC => wbData,
			ExBuffer => exCtlBuffer,
			output_instruction_address => instAddrId,
			jump_Address => jAddr,
			rs => rs,
			rt => rt,
			destinationAddress => destAddressId,
			signExtImm => signExtImm,
			insert_stall => stall,  
			controlBuffer_EX => exCtlBuffId,
			controlBuffer_MEM => memCtlBuffId,
			controlBuffer_WB => wbCtlBuffId,
			funct_out => funct_from_id,
			opcode_out => opcode_bt_IdnEx,
			write_reg_txt => programend
		  
		   
);	
	
execute: EX
port map (
		 
			
			clk => clock,
			mem_data_stall => mem_data_stall,
			inputBranch =>bTaken,
			instructionAddr => instAddrId,
			jumpAddr => jAddr,
			registerSrc => rs,
			registerTarg => rt,
			destAddr => destAddressId,
			signExtImm => signExtImm,
			exCtlBuff => exCtlBuffId,
			memCtlBuff => memCtlBuffId,
			wbCtlBuff => wbCtlBuffId,
			op => opcode_bt_IdnEx,
			functt => funct_from_id,
			memCtlBuffOld => memCtlBuffMem ,
			wbCtlBuffOld => wbCtlBuffWb,
			wbData => wbData,
			branchAddress => bran_addr_from_ex,
			takenBranch => bran_taken_from_ex,
			opOut => opcode_bt_ExnMem,
			destAddrOut => des_addr_from_ex,
			ALU_result => ALU_result_from_ex,
			rt_data => rt_data_from_ex,
			memCtlBuffOut => MEM_control_buffer_from_ex,		
			wbCtlBuffOut => WB_control_buffer_from_ex,				
			exCtlBuffOut => exCtlBuffer	

);

mem: DataMem
port map (
			clock => clock,
			mem_data_stall => mem_data_stall,
			mem_data_stall_in => mem_data_stall,
			opcode => opcode_bt_ExnMem,
			input_destination_address => des_addr_from_ex,
			ALU_result => ALU_result_from_ex,
			rt_Data => rt_data_from_ex,
			branchTaken => bran_taken_from_ex,
			input_branch_address =>  bran_addr_from_ex,
			control_buffer_MEM => MEM_control_buffer_from_ex,
			control_buffer_WB => WB_control_buffer_from_ex,
			write_reg_txt => programend,
			MEM_control_buffer_out => memCtlBuffMem,
			WB_control_buffer_out => WB_control_buffer_from_mem,
			memoryData => memory_data,
			ALU_data => ALU_result_from_mem,
			output_destination_address => des_addr_from_mem,
			branchAddress => bAddress,
			output_branch_taken => bTaken,
			s_addr_data=>dc_s_addr,
			s_read_data=>dc_s_read,
			s_readdata_data=>dc_readdata_data,
			s_write_data=>dc_s_write,
			s_writedata_data=>dc_s_writedata, 
			s_waitrequest_data=>dc_s_waitrequest
			
);
	
writeback: WB
port map (
			mem_data_stall => mem_data_stall,
			clk => clock,
			memory_data => memory_data,
			ALU_output => alu_result_from_mem,
			opcode => opcode_bt_MEmnWb,
			WB_address => des_addr_from_mem,
			controlBuffer_WB => WB_control_buffer_from_mem,
			output_WB_ControlBuffer => wbCtlBuffWb,
			output_WB_address => wbRegAddr,
			WB_outData => wbData
);

iCache: InstCache
port map (
			clock => clock,
			reset => reset,
			s_addr => ic_s_addr,
			s_read => ic_s_read,
			s_readdata => s_readdata_inst,
			s_waitrequest => s_waitrequest_inst,
			m_addr => address_instcache,
			m_read => memread_instcache,
			m_readdata => m_readdata,
			m_write => memwrite_instcache,
			m_writedata => writedata_instcache,
			miss => ismiss,
			m_waitrequest => ic_m_waitrequest

);

dCache: DataCache
port map (
			clock => clock,
			reset => reset,
			s_addr => dc_s_addr,
			s_read => dc_s_read,
			s_readdata => dc_readdata_data,
			s_write => dc_s_write,
			s_writedata => dc_s_writedata,
			s_waitrequest => dc_s_waitrequest,
			m_addr => address_datacache,
			m_read => memread_datacache,
			m_readdata => m_readdata,
			m_write => memwrite_datacache,
			m_writedata => writedata_datacache,
			m_waitrequest => dc_m_waitrequest

);

mainMemory: memory
port map (
			clock => clock,
			inst_write => writedata_instcache,
			inst_add => address_instcache,
			data_write => writedata_datacache,
			data_add => address_datacache,
			inst_write_mem => memwrite_instcache,
			data_write_mem => memwrite_datacache,
			inst_read_mem => memread_instcache,
			data_read_mem => memread_datacache,
			inst_wait => ic_m_waitrequest,
			data_wait => dc_m_waitrequest,
			data_read => m_readdata,
			inst_max => max_inst,
			fin_read => readDone,
			reg_write => programend

);

clk_process : process
begin
	clock <= '0';
	wait for clkPeriod/2;
	clock <= '1';
	wait for clkPeriod/2;
end process;

	
test_process : process
begin
	wait for 10000* clkPeriod;
	programend <= '1';
	wait;
end process;
end behaviour;
