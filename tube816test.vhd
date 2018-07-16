LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

-- (c) Dominic Beesley 2015 - see unlicence.txt
-- implements the DE0 mezzanine board for the 
-- Dossytronics 65816 TUBE board


ENTITY tube816test IS
	PORT(
		CLOCK_50				: IN std_logic;
	
		HOST_nRST			: IN std_logic;
		HOST_nTUBE			: IN std_logic;
		HOST_nIRQ			: INOUT std_logic;
		HOST_2MHzE			: IN std_logic;
		HOST_RnW				: IN std_logic;
		HOST_A				: IN std_logic_vector (2 downto 0);
		HOST_D				: INOUT std_logic_vector (7 downto 0);
		
		
		LED					: OUT std_logic_vector (7 downto 0);
		
		KEY					: IN std_logic_vector (1 downto 0);
		
		GPIO_22				: OUT std_logic;
		
		T_VDA					: IN std_logic;		-- CPU valid addr
		T_VPA					: IN std_logic;		-- CPU valid prog
		T_VPB					: IN std_logic;		-- CPU vector pull
		T_nCSROM				: OUT std_logic;		-- bus ce ROM
		T_nCSRAM0			: OUT std_logic;		-- bus ce RAM0
		T_nCSRAM1			: OUT std_logic;		-- bus ce RAM1
		T_BA17				: OUT std_logic;		-- RAM/ROM A[17]
		T_BA16				: OUT std_logic;		-- RAM/ROM A[16]
		T_phi2				: OUT std_logic;		-- cpu clock
		T_nNMI				: OUT std_logic;		-- cpu NMI
		T_nIRQ				: OUT std_logic;		-- cpu IRQ
		T_nRST				: OUT std_logic;		-- cpu RST
		T_EXTRA				: IN std_logic;		-- EXTRA input (CPU E - emulation mode)
		T_nATOP				: IN std_logic;		-- 0 when cpu A(15 downto 12) = x"F"
		T_D					: INOUT std_logic_vector(7 downto 0); -- cpu databus
		T_A					: IN std_logic_vector(11 downto 0); -- cpu A[11 downto 0]
		T_RnW					: IN std_logic;		-- databus level shifter CE
		T_Ddir				: OUT std_logic		-- databus level shifter direction (alway cpu -> tube on phi2 low, only when cpu write or not ram or rom for read)
	);
END tube816test;

ARCHITECTURE a OF tube816test IS

	COMPONENT PAR_CLK IS
		PORT
		(
			inclk0		: IN STD_LOGIC  := '0';
			c0		: OUT STD_LOGIC 
		);
	END COMPONENT;

	component TUBE is
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
	end component;
	
	signal T_phi2_i		: std_logic;
	signal rst_ctr			: std_LOGIC_VECTOR(7 downto 0) := (others => '1');
	signal nrst_i			: std_logic := '0';
	
	signal	HOST_nIRQ_i		: std_logic;
	signal	HOST_DOUT_i		: std_logic_vector(7 downto 0);

	signal	PAR_nRST			: std_logic;	
	signal	PAR_nTUBE		: std_logic;
	signal	PAR_RnW			: std_logic;
	signal	PAR_DI			: std_logic_vector(7 downto 0);
	signal	PAR_DO			: std_logic_vector(7 downto 0);
	signal	PAR_A				: std_logic_vector(2 downto 0);
	signal	PAR_nIRQ			: std_logic;
	signal	PAR_nNMI			: std_logic;
	signal	PAR_CLK_i		: std_logic;

	signal addr_tube_par		: std_logic;
	signal addr_tube_hos		: std_logic;
	signal boot				: std_logic;
	
	signal ba_i				: std_logic_vector(7 downto 0) := x"00";
	signal prev_ba			: std_logic_vector(7 downto 0) := x"00";
	
	signal dbug_reg		: std_logic_vector(7 downto 0);
	
BEGIN
	HOST_nIRQ <= 'Z';
	HOST_D <= (others => 'Z');
	

	LED(0) <= T_VPB;
	LED(1) <= not T_VPB;
	LED(2) <= T_EXTRA;
	LED(3) <= not T_EXTRA;
	
	GPIO_22 <= dbug_reg(0);
	
	fc50: process(addr_tube_hos, T_D, T_phi2_i)
	begin
		if falling_edge(T_phi2_i) then
			if addr_tube_hos = '1' then
				dbug_reg <= "11111111";
			else
				dbug_reg <= "00000000";
			end if;
		end if;
	end process;
	
	ba_set: process(T_D, T_phi2_i)
	begin
	   if (T_Phi2_i = '0') then
		   ba_i <= T_D;
		else
			ba_i <= prev_ba;
	   end if;
	end process;
	
	ba_prev: process(T_D, T_phi2_i)
	begin
		if rising_edge(T_phi2_i) then
		  prev_ba <= T_D;
		end if;
	end process;
		
	add_dec: process(T_A, T_RnW, T_nATOP, boot, T_VPB, T_EXTRA, ba_i)
	begin
		T_nCSRAM1 <= '1';
		T_nCSRAM0 <= '1';
		addr_tube_par <= '0';
		addr_tube_hos <= '0';
		T_nCSROM <= '1';
		T_BA16 <= '0';
		T_BA17 <= '0';
		
		if ba_i = x"00" and T_nATOP = '0' and T_A(11 downto 4) = x"EF" and T_A(3) = '1' then
			addr_tube_par <= '1';
		elsif ba_i = x"00" and T_nATOP = '0' and T_A(11 downto 4) = x"EF" and T_A(3) = '0' then
			addr_tube_hos <= '1';
		else
			if T_VPB = '0' and boot = '0' and (T_A(7 downto 4) = x"E" or
				(	-- TODO: Make all vectors come from hi bank when ROM is fixed
						T_A(3 downto 0) /= x"A"
				and	T_A(3 downto 0) /= x"B"
				and	T_A(3 downto 0) /= x"C"
				and	T_A(3 downto 0) /= x"D"
				and	T_A(3 downto 0) /= x"E"
				and	T_A(3 downto 0) /= x"F"
				))
				then
				-- vector pull after boot get from ram BA=1
				T_nCSRAM0 <= '0';
				T_BA16 <= '1';
				T_BA17 <= '0';
			else
				if ba_i = x"00" and T_nATOP = '0' and T_A(11 downto 4) /= x"EF" then
					if boot = '1' and T_RnW = '1' then 
						T_nCSROM <= '0';
					else
						T_nCSRAM0 <= '0';			
					end if;
				elsif (ba_i = x"00" or ba_i = x"01") then
					T_nCSRAM0 <= '0';
				elsif (ba_i = x"02" or ba_i = x"03") then
					T_nCSRAM1 <= '0';
				end if;
				T_BA16 <= ba_i(0);
				T_BA17 <= ba_i(1);
			end if;
		end if;
	end process; 
	
	T_nNMI <= PAR_nNMI;
	T_nIRQ <= PAR_nIRQ;
	T_nRST <= nrst_i;
	T_D <= (others => 'Z');
	T_phi2 <= T_phi2_i;
	PAR_RNW <= T_RnW;
	PAR_A <= T_A(2 downto 0);
	PAR_nTUBE <= not addr_tube_par;
	PAR_DI <= T_D;
	
	hirq : process (HOST_nIRQ_i)
	begin
		if (HOST_nIRQ_i = '0') then
			HOST_nIRQ <= '0';
		else
			HOST_nIRQ <= 'Z';
		end if;
	end process;
	
	hdo : process (HOST_DOUT_i, HOST_RnW, HOST_nTUBE, HOST_2MHzE)
	begin
	   if (rising_edge(HOST_2MHzE)) then
			if (HOST_RnW = '1' and HOST_nTUBE = '0') then
				HOST_D <= HOST_DOUT_i;
			else
				HOST_D <= (others => 'Z');
			end if;
		end if;
	end process;
	
	rstctr: process (T_phi2_i, rst_ctr, PAR_nRST)
	begin
		if PAR_nRST = '0' then
			nrst_i <= '0';
			rst_ctr <= (others => '1');
		elsif falling_edge(T_phi2_i) then
			if (rst_ctr = "00000000") then
				nrst_i <= '1';
			else
				rst_ctr <= std_logic_vector(unsigned(rst_ctr) - 1);
			end if;
		end if;
	end process;
	
	dmux: process (addr_tube_par, T_RnW, T_phi2_i, PAR_DO)
	begin
		if T_phi2_i = '1' then
			if (addr_tube_par = '1' and T_RnW = '1') then
				T_ddir <= '1';
				T_D <= PAR_DO;			
			else
				T_ddir <= '0';
				T_D <= (others => 'Z');			
			end if;
		else
			T_ddir <= '0';
			T_D <= (others => 'Z');
		end if;
	end process;

	bootoff: process (nrst_i, boot, addr_tube_par, T_phi2_i)
	begin
		if (nrst_i = '0') then
			boot <= '1';
		elsif (falling_edge(T_phi2_i) and addr_tube_par = '1') then
			boot <= '0';
		end if;
	end process;
	
	
	pc: PAR_CLK 
	PORT MAP
	(
		inclk0		=>	CLOCK_50,
		c0				=> T_phi2_i
	);
	
	
	tubex: TUBE
	port map(
	
		HOST_nRST			=> HOST_nRST,
		HOST_nTUBE			=> HOST_nTUBE,
		HOST_nIRQ			=> HOST_nIRQ_i,
		HOST_2MHzE			=> HOST_2MHzE,
		HOST_RnW				=> HOST_RnW,
		HOST_A				=> HOST_A,
		HOST_DIN				=> HOST_D,
		HOST_DOUT			=> HOST_DOUT_i,
				
		PAR_nRST				=> PAR_nRST,
		PAR_nTUBE			=> PAR_nTUBE,
		PAR_CLK				=> T_phi2_i,
		PAR_RnW				=> PAR_RnW,
		PAR_DI				=> PAR_DI,
		PAR_DO				=> PAR_DO,
		PAR_A					=> PAR_A,
		PAR_nIRQ				=> PAR_nIRQ,
		PAR_nNMI				=> PAR_nNMI
	);

	
END a;