LIBRARY ieee;
USE ieee.std_logic_1164.all; 
use ieee.numeric_std.all;
USE IEEE.VITAL_timing.ALL;
USE IEEE.VITAL_primitives.ALL;
use std.textio.all;
use ieee.std_logic_textio.all;

LIBRARY work;

-- (c) Dominic Beesley 2015


entity dom6502copro_tb is
end dom6502copro_tb;

architecture test of dom6502copro_tb is

	signal	clock_2  : std_logic;
	signal 	nRST : std_logic;
	signal	HOST_nTUBE : std_logic;	
	signal	HOST_A 	  : std_logic_vector(2 downto 0);
	signal	HOST_D	  : std_logic_vector(7 downto 0);
	signal	cloCK_50	  : std_logic;
		
	shared variable finished : std_logic := '0';
	
	COMPONENT dom6502copro IS
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
		
		KEY					: IN std_logic_vector (1 downto 0)
	);
	END COMPONENT;

	
begin


	main: dom6502copro PORT MAP(
		CLOCK_50				=> clock_50,
		HOST_nRST			=> nRST,
		HOST_nTUBE			=> HOST_nTUBE,
		--HOST_nIRQ			: INOUT std_logic;
		HOST_2MHzE			=> clock_2,
		HOST_RnW				=> '1',
		HOST_A				=> HOST_A,
		HOST_D				=> HOST_D,
--		LED					: OUT std_logic_vector (7 downto 0);		
		KEY					=> "11"
	);

	
	mck: process
	begin
		wait for 1 ns;
		loop 
			if finished = '0' then
				clock_2 <= '0';		
				wait for 500 ns;
				clock_2 <= '1';
				wait for 500 ns;
			else
				wait;
			end if;
		end loop;
	end process;

	
	pck: process
	begin
		wait for 1 ns;
		loop 
			if finished = '0' then
				clock_50 <= '0';		
				wait for 10 ns;
				clock_50 <= '1';
				wait for 10 ns;
			else
				wait;
			end if;
		end loop;
	end process;

	res: process
	begin
		nRST <= '0';
		wait for 2 us;
		nRST <= '1';
		wait;
	end process;
	
	host: process
	variable drdy : std_logic;
	variable line_out : line;
	begin
		
		HOST_nTUBE <= '1';
		HOST_A <= "000";
		
		wait for 100 uS;
		
		drdy := '0';
		
		while drdy = '0' loop

			wait for 20 uS;
		
			wait until clock_2 = '0';
		
			HOST_A <= "000";
			HOST_nTube <= '0';

			wait until clock_2 = '1';
			
			wait until clock_2 = '0';
			if HOST_D(7) = '1' then
				drdy := '1';
			end if;

			HOST_nTube <= '1';

			wait until clock_2 = '1';
			

		end loop;
		
		
		write(line_out, now);
		write(line_out, string'(" got char ready"));
		writeline(output, line_out);

		wait for 10 uS;
		
		wait until clock_2 = '0';
		HOST_A <= "001";
		HOST_nTUBE <= '0';

		wait until clock_2 = '1';
		wait until clock_2 = '0';

		write(line_out, now);
		write(line_out, string'(" data "));
		write(line_out, HOST_D);
		writeline(output, line_out);
		HOST_nTUBE <= '1';

		wait until clock_2 = '1';
		
		wait for 300 uS;
		
	end process;
	
	timeout: process
	begin
		wait for 60000000 ns;
		finished := '1';
		wait;
	end process;
end;
