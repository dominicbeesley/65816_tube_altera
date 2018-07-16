LIBRARY ieee;

USE ieee.std_logic_1164.all; 
use ieee.numeric_std.all;

LIBRARY work;

-- (c) Dominic Beesley 2015 - see unlicence.txt
-- Implements a simple TUBE ULA replacement using Flancters
-- for cross clock domain signals.
--
-- the register busy/available flags are delayed by one 
-- destination clock to ensure that register data are 
-- ready before the host/client accesses

entity TUBE is
	port (
	
		HOST_nRST			: IN std_logic;
		HOST_nTUBE			: IN std_logic;
		HOST_nIRQ			: OUT std_logic;
		HOST_2MHzE			: IN std_logic;
		HOST_RnW				: IN std_logic;
		HOST_A				: IN std_logic_vector (2 downto 0);
		HOST_DIN				: IN std_logic_vector (7 downto 0);
		HOST_DOUT			: OUT std_logic_vector (7 downto 0);
				
		PAR_nRST				: OUT STD_LOGIC;
		PAR_nTUBE			: IN STD_LOGIC;
		PAR_CLK				: IN STD_LOGIC;
		PAR_RnW				: IN STD_LOGIC;
		PAR_DI				: IN STD_LOGIC_VECTOR(7 downto 0);
		PAR_DO				: OUT STD_LOGIC_VECTOR(7 downto 0);
		PAR_A					: IN STD_LOGIC_VECTOR(2 downto 0);
		PAR_nIRQ				: OUT STD_LOGIC;
		PAR_nNMI				: OUT STD_LOGIC
	);
end;

architecture arch of TUBE is
	
	component reg_duplex is
	port (
	
		rst_i		: in std_logic;
	
		clk_A		: in std_logic;
		rden_A	: in std_logic;
		wren_A	: in std_logic;
		d_in_A	: in std_logic_vector(7 downto 0);
		d_out_A	: out std_logic_vector(7 downto 0);
		
		datardy_A: out std_logic;
		notfull_A: out std_logic;

		clk_B		: in std_logic;
		rden_B	: in std_logic;
		wren_B	: in std_logic;
		d_in_B	: in std_logic_vector(7 downto 0);
		d_out_B	: out std_logic_vector(7 downto 0);
		
		datardy_B: out std_logic;
		notfull_B: out std_logic
		
	);
	end component;
	
	
	signal HOST_rden_reg1 : std_logic;
	signal HOST_wren_reg1 : std_logic;
	signal HOST_rden_reg1_st : std_logic;
	signal HOST_wren_reg1_st : std_logic;
	signal HOST_DOUT_reg1 : std_logic_vector(7 downto 0);
	signal HOST_datardy_reg1 : std_logic;
	signal HOST_notfull_reg1 : std_logic;

	signal HOST_rden_reg2 : std_logic;
	signal HOST_wren_reg2 : std_logic;
	signal HOST_rden_reg2_st : std_logic;
	signal HOST_DOUT_reg2 : std_logic_vector(7 downto 0);
	signal HOST_datardy_reg2 : std_logic;
	signal HOST_notfull_reg2 : std_logic;

	signal HOST_rden_reg3 : std_logic;
	signal HOST_wren_reg3 : std_logic;
	signal HOST_rden_reg3_st : std_logic;
	signal HOST_DOUT_reg3 : std_logic_vector(7 downto 0);
	signal HOST_datardy_reg3 : std_logic;
	signal HOST_notfull_reg3 : std_logic;

	signal HOST_rden_reg4 : std_logic;
	signal HOST_wren_reg4 : std_logic;
	signal HOST_rden_reg4_st : std_logic;
	signal HOST_DOUT_reg4 : std_logic_vector(7 downto 0);
	signal HOST_datardy_reg4 : std_logic;
	signal HOST_notfull_reg4 : std_logic;

	signal PAR_rden_reg1 : std_logic;
	signal PAR_wren_reg1 : std_logic;
	signal PAR_rden_reg1_st : std_logic;
	signal PAR_DOUT_reg1 : std_logic_vector(7 downto 0);
	signal PAR_datardy_reg1 : std_logic;
	signal PAR_notfull_reg1 : std_logic;

	signal PAR_rden_reg2 : std_logic;
	signal PAR_wren_reg2 : std_logic;
	signal PAR_rden_reg2_st : std_logic;
	signal PAR_DOUT_reg2 : std_logic_vector(7 downto 0);
	signal PAR_datardy_reg2 : std_logic;
	signal PAR_notfull_reg2 : std_logic;
	
	signal PAR_rden_reg3 : std_logic;
	signal PAR_wren_reg3 : std_logic;
	signal PAR_rden_reg3_st : std_logic;
	signal PAR_DOUT_reg3 : std_logic_vector(7 downto 0);
	signal PAR_datardy_reg3 : std_logic;
	signal PAR_notfull_reg3 : std_logic;

	signal PAR_rden_reg4 : std_logic;
	signal PAR_wren_reg4 : std_logic;
	signal PAR_rden_reg4_st : std_logic;
	signal PAR_wren_reg4_st : std_logic;
	signal PAR_DOUT_reg4 : std_logic_vector(7 downto 0);
	signal PAR_datardy_reg4 : std_logic;
	signal PAR_notfull_reg4 : std_logic;



	signal flag_T : std_logic;
	signal flag_P : std_logic;
	signal flag_V : std_logic;
	signal flag_M : std_logic;
	signal flag_J : std_logic;
	signal flag_I : std_logic;
	signal flag_Q : std_logic;
	
	signal local_nRST : std_logic;
	signal local_RST : std_logic;

begin

	--local_nRST <= HOST_nRST and not(flag_T); 
	local_nRST <= not(flag_T) and HOST_nRST;
	local_RST <= not(local_nRST);
	par_nRST <= not(flag_P) and HOST_nRST;
	
	--TODO : reset registers on local_nRST

	host_addec : process (HOST_nTUBE, HOST_A, HOST_RnW)
	begin
		HOST_rden_reg1 <= '0';
		HOST_wren_reg1 <= '0';
		HOST_rden_reg1_st <= '0';
		HOST_wren_reg1_st <= '0';

		HOST_rden_reg2 <= '0';
		HOST_wren_reg2 <= '0';
		HOST_rden_reg2_st <= '0';

		HOST_rden_reg3 <= '0';
		HOST_wren_reg3 <= '0';
		HOST_rden_reg3_st <= '0';

		HOST_rden_reg4 <= '0';
		HOST_wren_reg4 <= '0';
		HOST_rden_reg4_st <= '0';

		if (HOST_nTUBE = '0') then
			case HOST_A is
				when "000" => 
					HOST_rden_reg1_st <= HOST_RnW; 
					HOST_wren_reg1_st <= not(HOST_RnW); 
				when "001" => 
					HOST_rden_reg1 <= HOST_RnW; 
					HOST_wren_reg1 <= not(HOST_RnW); 
				when "010" => 
					HOST_rden_reg2_st <= HOST_RnW; 
				when "011" => 
					HOST_rden_reg2 <= HOST_RnW; 
					HOST_wren_reg2 <= not(HOST_RnW); 
				when "100" => 
					HOST_rden_reg3_st <= HOST_RnW; 
				when "101" => 
					HOST_rden_reg3 <= HOST_RnW; 
					HOST_wren_reg3 <= not(HOST_RnW); 
				when "110" => 
					HOST_rden_reg4_st <= HOST_RnW; 
				when "111" => 
					HOST_rden_reg4 <= HOST_RnW; 
					HOST_wren_reg4 <= not(HOST_RnW); 
				when others =>
					null;
			end case;	
		end if;
	end process;

	host_Dmux	: process(
		HOST_rden_reg1, HOST_rden_reg1_st, HOST_DOUT_reg1, HOST_datardy_reg1, HOST_notfull_reg1
		, HOST_rden_reg2, HOST_rden_reg2_st, HOST_DOUT_reg2, HOST_datardy_reg2, HOST_notfull_reg2
		, HOST_rden_reg3, HOST_rden_reg3_st, HOST_DOUT_reg3, HOST_datardy_reg3, HOST_notfull_reg3
		, HOST_rden_reg4, HOST_rden_reg4_st, HOST_DOUT_reg4, HOST_datardy_reg4, HOST_notfull_reg4
		, flag_P, flag_V, flag_M, flag_J, flag_I, flag_Q
	)
	begin
		if (HOST_rden_reg1 = '1') then
			HOST_DOUT <= HOST_DOUT_reg1;
		elsif (HOST_rden_reg1_st = '1') then
			HOST_DOUT <= HOST_datardy_reg1 & HOST_notfull_reg1 & flag_P & flag_V & flag_M & flag_J & flag_I & flag_Q;
		elsif (HOST_rden_reg2 = '1') then
			HOST_DOUT <= HOST_DOUT_reg2;
		elsif (HOST_rden_reg2_st = '1') then
			HOST_DOUT <= HOST_datardy_reg2 & HOST_notfull_reg2 & "000000";
		elsif (HOST_rden_reg3 = '1') then
			HOST_DOUT <= HOST_DOUT_reg3;
		elsif (HOST_rden_reg3_st = '1') then
			HOST_DOUT <= HOST_datardy_reg3 & HOST_notfull_reg3 & "000000";
		elsif (HOST_rden_reg4 = '1') then
			HOST_DOUT <= HOST_DOUT_reg4;
		elsif (HOST_rden_reg4_st = '1') then
			HOST_DOUT <= HOST_datardy_reg4 & HOST_notfull_reg4 & "000000";
		else
			HOST_DOUT <= (others => '1');
		end if;
	end process;
	
	host_wr_reg : process(HOST_wren_reg1_st, HOST_2MHzE, HOST_DIN, HOST_nRST)
	begin
		if (HOST_nRST = '0') then
			flag_T <= '0';
			flag_P <= '0';
			flag_V <= '0';
			flag_M <= '0';
			flag_J <= '0';
			flag_I <= '0';
			flag_Q <= '0';
		elsif (falling_edge(HOST_2MHzE)) then
			if (HOST_wren_reg1_st='1') then
				-- set flags depending on value of S flag D[7]
				if (HOST_DIN(6) = '1') then flag_T <= HOST_DIN(7); end if;
				if (HOST_DIN(5) = '1') then flag_P <= HOST_DIN(7); end if;
				if (HOST_DIN(4) = '1') then flag_V <= HOST_DIN(7); end if;
				if (HOST_DIN(3) = '1') then flag_M <= HOST_DIN(7); end if;
				if (HOST_DIN(2) = '1') then flag_J <= HOST_DIN(7); end if;
				if (HOST_DIN(1) = '1') then flag_I <= HOST_DIN(7); end if;
				if (HOST_DIN(0) = '1') then flag_Q <= HOST_DIN(7); end if;
			end if;
		end if;
	end process;

	host_irq : process (flag_Q, HOST_datardy_reg4)
	begin

		HOST_nIRQ <= not((flag_Q and HOST_datardy_reg4));
	
	end process;

	
	par_irq : process (flag_I, flag_J, PAR_datardy_reg1, PAR_datardy_reg4)
	begin

		PAR_nIRQ <= not((flag_I and PAR_datardy_reg1) or (flag_J and PAR_datardy_reg4));
	
	end process;
	

	par_nmi : process (flag_M, PAR_datardy_reg3)
	begin

		PAR_nNMI <= not(flag_M and (PAR_datardy_reg3 or PAR_notfull_reg3)); --TODO: this par_notfull is not right it should only be when EMPTY
	
	end process;

	par_addec : process (PAR_nTUBE, PAR_A, PAR_RnW)
	begin
		PAR_rden_reg1 <= '0';
		PAR_wren_reg1 <= '0';
		PAR_rden_reg1_st <= '0';

		PAR_rden_reg2 <= '0';
		PAR_wren_reg2 <= '0';
		PAR_rden_reg2_st <= '0';

		PAR_rden_reg3 <= '0';
		PAR_wren_reg3 <= '0';
		PAR_rden_reg3_st <= '0';

		PAR_rden_reg4 <= '0';
		PAR_wren_reg4 <= '0';
		PAR_rden_reg4_st <= '0';

		if (PAR_nTUBE = '0') then
			case PAR_A is
				when "000" => 
					PAR_rden_reg1_st <= PAR_RnW; 
				when "001" => 
					PAR_rden_reg1 <= PAR_RnW; 
					PAR_wren_reg1 <= not(PAR_RnW); 
				when "010" => 
					PAR_rden_reg2_st <= PAR_RnW; 
				when "011" => 
					PAR_rden_reg2 <= PAR_RnW; 
					PAR_wren_reg2 <= not(PAR_RnW); 
				when "100" => 
					PAR_rden_reg3_st <= PAR_RnW; 
				when "101" => 
					PAR_rden_reg3 <= PAR_RnW; 
					PAR_wren_reg3 <= not(PAR_RnW); 
				when "110" => 
					PAR_rden_reg4_st <= PAR_RnW; 
				when "111" => 
					PAR_rden_reg4 <= PAR_RnW; 
					PAR_wren_reg4 <= not(PAR_RnW); 
				when others =>
					null;
			end case;	
		end if;
	end process;

	par_Dmux	: process(
		PAR_rden_reg1, PAR_rden_reg1_st, PAR_DOUT_reg1, PAR_datardy_reg1, PAR_notfull_reg1
		, PAR_rden_reg2, PAR_rden_reg2_st, PAR_DOUT_reg2, PAR_datardy_reg2, PAR_notfull_reg2
		, PAR_rden_reg3, PAR_rden_reg3_st, PAR_DOUT_reg3, PAR_datardy_reg3, PAR_notfull_reg3
		, PAR_rden_reg4, PAR_rden_reg4_st, PAR_DOUT_reg4, PAR_datardy_reg4, PAR_notfull_reg4
		)
	begin
		if (PAR_rden_reg1 = '1') then
			PAR_DO <= PAR_DOUT_reg1;
		elsif (PAR_rden_reg1_st = '1') then
			PAR_DO <= PAR_datardy_reg1 & PAR_notfull_reg1 & "000000";
		elsif (PAR_rden_reg2 = '1') then
			PAR_DO <= PAR_DOUT_reg2;
		elsif (PAR_rden_reg2_st = '1') then
			PAR_DO <= PAR_datardy_reg2 & PAR_notfull_reg2 & "000000";
		elsif (PAR_rden_reg3 = '1') then
			PAR_DO <= PAR_DOUT_reg3;
		elsif (PAR_rden_reg3_st = '1') then
			PAR_DO <= PAR_datardy_reg3 & PAR_notfull_reg3 & "000000";
		elsif (PAR_rden_reg4 = '1') then
			PAR_DO <= PAR_DOUT_reg4;
		elsif (PAR_rden_reg4_st = '1') then
			PAR_DO <= PAR_datardy_reg4 & PAR_notfull_reg4 & "111111";
		else
			PAR_DO <= (others => '0');
		end if;
	end process;

	
	reg_1:	reg_duplex port map (
		rst_i		=> local_rst,
	 
		clk_A		=> HOST_2MHzE,
		rden_A	=> HOST_rden_reg1,
		wren_A	=> HOST_wren_reg1,
		d_in_A	=> HOST_DIN,
		d_out_A	=> HOST_DOUT_reg1,
		
		datardy_A=> HOST_datardy_reg1,
		notfull_A=> HOST_notfull_reg1,

		clk_B		=> PAR_CLK,
		rden_B	=> PAR_rden_reg1,
		wren_B	=> PAR_wren_reg1,
		d_in_B	=> PAR_DI,
		d_out_B	=> PAR_DOUT_reg1,
		
		datardy_B=> PAR_datardy_reg1,
		notfull_B=> PAR_notfull_reg1
	);

	reg_2:	reg_duplex port map (
		rst_i		=> local_rst,
	 
		clk_A		=> HOST_2MHzE,
		rden_A	=> HOST_rden_reg2,
		wren_A	=> HOST_wren_reg2,
		d_in_A	=> HOST_DIN,
		d_out_A	=> HOST_DOUT_reg2,
		
		datardy_A=> HOST_datardy_reg2,
		notfull_A=> HOST_notfull_reg2,

		clk_B		=> PAR_CLK,
		rden_B	=> PAR_rden_reg2,
		wren_B	=> PAR_wren_reg2,
		d_in_B	=> PAR_DI,
		d_out_B	=> PAR_DOUT_reg2,
		
		datardy_B=> PAR_datardy_reg2,
		notfull_B=> PAR_notfull_reg2
	);

	
	reg_3:	reg_duplex port map (
		rst_i		=> local_rst,
	 
		clk_A		=> HOST_2MHzE,
		rden_A	=> HOST_rden_reg3, 
		wren_A	=> HOST_wren_reg3,
		d_in_A	=> HOST_DIN,
		d_out_A	=> HOST_DOUT_reg3,
		
		datardy_A=> HOST_datardy_reg3,
		notfull_A=> HOST_notfull_reg3,

		clk_B		=> PAR_CLK,
		rden_B	=> PAR_rden_reg3,
		wren_B	=> PAR_wren_reg3,
		d_in_B	=> PAR_DI,
		d_out_B	=> PAR_DOUT_reg3,
		
		datardy_B=> PAR_datardy_reg3,
		notfull_B=> PAR_notfull_reg3
	);

	reg_4:	reg_duplex port map (
		rst_i		=> local_rst,
	 
		clk_A		=> HOST_2MHzE,
		rden_A	=> HOST_rden_reg4,
		wren_A	=> HOST_wren_reg4,
		d_in_A	=> HOST_DIN,
		d_out_A	=> HOST_DOUT_reg4,
		
		datardy_A=> HOST_datardy_reg4,
		notfull_A=> HOST_notfull_reg4,

		clk_B		=> PAR_CLK,
		rden_B	=> PAR_rden_reg4,
		wren_B	=> PAR_wren_reg4,
		d_in_B	=> PAR_DI,
		d_out_B	=> PAR_DOUT_reg4,
		
		datardy_B=> PAR_datardy_reg4,
		notfull_B=> PAR_notfull_reg4
	);
	
end;