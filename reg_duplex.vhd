LIBRARY ieee;

USE ieee.std_logic_1164.all; 
use ieee.numeric_std.all;

LIBRARY work;

-- (c) Dominic Beesley 2015 - see unlicence.txt
-- Implements a duplex register in a TUBE ULA

entity reg_duplex is
	port (
	
		rst_i		: in std_logic;
	
		clk_A		: in std_logic;
		rden_A	: in std_logic;
		wren_A	: in std_logic;
		d_in_A	: in std_logic_vector(7 downto 0);
		d_out_A	: out std_logic_vector(7 downto 0);
		
		datardy_A : out std_logic;
		notfull_A : out std_logic;

		clk_B		: in std_logic;
		rden_B	: in std_logic;
		wren_B	: in std_logic;
		d_in_B	: in std_logic_vector(7 downto 0);
		d_out_B	: out std_logic_vector(7 downto 0);
		
		datardy_B: out std_logic;
		notfull_B: out std_logic		
	);
end;

architecture arch of reg_duplex is

	component reg_simplex is
	port (
	
		rst_i		: in std_logic;
	
		clk_in	: in std_logic;
		clk_en_in: in std_logic;
		d_in		: in std_logic_vector(7 downto 0);
		
		full		: out std_logic;
		
		clk_out	: in std_logic;
		clk_en_out:in std_logic;
		
		q_out		: out std_logic_vector(7 downto 0);
		
		avail		: out std_logic
	);
	end component;

signal	AtoBFull	:std_logic;
signal	BtoAFull	:std_logic;

signal	AtoBAvail:std_logic;
signal	BtoAAvail:std_logic;

signal	clkB_n	:std_logic;
signal	clkA_n	:std_logic;

begin

	clkA_n <= not(clk_A);
	clkB_n <= not(clk_B);

	AtoB : reg_simplex port map (
		rst_i		=> rst_i,
	
		clk_in	=> clkA_n,
		clk_en_in=> wren_A,
		d_in		=> d_in_A,
		
		full		=> AtoBFull,
		
		clk_out	=> clkB_n,
		clk_en_out=>rden_B,
		
		q_out		=> d_out_B,
		
		avail		=> AtoBAvail
	);

	BtoA : reg_simplex port map ( 
		rst_i		=> rst_i,
	
		clk_in	=> clkB_n,
		clk_en_in=> wren_B,
		d_in		=> d_in_B,
		
		full		=> BtoAFull,
		
		clk_out	=> clkA_n,
		clk_en_out=>rden_A,
		
		q_out		=> d_out_A,

		avail		=> BtoAAvail
	);

	datardy_A <= BtoAAvail;
	notfull_A <= not(AtoBFull);
	
	datardy_B <= AtoBAvail;
	notfull_B <= not(BtoAFull);

end;