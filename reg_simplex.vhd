LIBRARY ieee;

USE ieee.std_logic_1164.all; 
use ieee.numeric_std.all;

LIBRARY work;

-- (c) Dominic Beesley 2015 - see unlicence.txt
-- Implements a simplex register in a TUBE ULA

entity reg_simplex is
	port (
	
		rst_i		: in std_logic;
	
		clk_in	: in std_logic;
		clk_en_in : in std_logic;
		d_in		: in std_logic_vector(7 downto 0);
		
		full		:	out std_logic;
	
		clk_out	: in std_logic;
		clk_en_out :in std_logic;
		
		q_out		: out std_logic_vector(7 downto 0);
		
		avail		: out std_logic
	);
end;

architecture arch of reg_simplex is

	component flancter is
	port (
		rst_i_async	: in std_logic;
		
		set_i_ck		: in std_logic;
		set_i			: in std_logic;
		
		rst_i_ck		: in std_logic;
		rst_i			: in std_logic;
		
		flag_out		: out std_logic		
	);
	end component;
	
	signal	reg	: std_logic_vector(7 downto 0);
	signal	wr		: std_logic;
	signal	rd		: std_logic;
	signal	fullf : std_logic;
	signal	availf: std_logic;

begin

		wrpr: process (rst_i, clk_en_in, clk_in, d_in, fullf)
		begin
			if (rst_i = '1') then
				reg <= (others => '1'); --"00110101";
			elsif (clk_en_in = '1' and rising_edge(clk_in) and fullf = '0') then
				reg <= d_in;
			end if;			
		end process;
	
--		rdpr: process (rst_i, clk_en_out, clk_out, reg)
--		begin
--			if (rst_i = '1') then
--				q_out <= "11111111"; 
--			elsif (clk_en_out = '1' and rising_edge(clk_out)) then
--				q_out <= reg;
--			end if;
--		end process;
	
		q_out <= reg;
	
		fl: flancter port map(
			rst_i_async	=> rst_i,		
			set_i_ck		=> clk_in,
			set_i			=> wr,
			rst_i_ck		=> clk_out,
			rst_i			=> rd,
			flag_out		=> fullf
		);
	
		av: process (clk_out, fullf, rst_i)
		begin
			-- delay avail until one clock after fullf
			if (rst_i = '1') then
				avail <= '0';
			elsif rising_edge(clk_out) then
				avail <= fullf;
			end if;
		end process;
		
		f: process (clk_in, fullf, rst_i)
		begin
			-- delay full until one clock after fullf
			if (rst_i = '1') then
				full <= '0';
			elsif rising_edge(clk_in) then
				full <= fullf;
			end if;		
		end process;
	
		wr <= clk_en_in and not(fullf);
		rd <= clk_en_out and fullf;
end;