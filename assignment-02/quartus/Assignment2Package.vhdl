------- Opdracht 2/ Assignment 2 DSDL practicum
------- Altera DE10-Lite
------- ir drs E.J Boks, HAN Embedded Systems Engineering. https://ese.han.nl  
------- $Id$
------- Bibliotheek met alle componenten die in dit projekt worden gebruikt
------- Library Whiteh all components that are used in this project.

library ieee; 
use ieee.std_logic_1164.all; 

package Assignment2Package is

	component genericClockDelay is

	generic(desiredClock: integer := 10;  -- 10 Hz
           inClockFreq: natural := 100);  -- 100 Hz
			
	port 
	(
		clk,rst  : in  std_logic;
		outClock  : out std_logic
	);
	
	end component;
	
end Assignment2Package;
	

package body Assignment2Package is	

end Assignment2Package;



---------- 


library ieee;
use ieee.std_logic_1164.all;
use work.all;

-- Dit is een generieke klokvertraging module. Zie voorbeeld 6.2 in Pedroni 2e Editie of paragraaf 2.7 en voorbeeld 12.3 in Pedroni 3e Editie.

-- This is a generic clock delay module. See example 6.2 in Pedroni 2nd Edition or paragraph 2.7 and example 12.3 in Pedroni 3rd Edition. 

-- Maak een Test Bench aan om deze module te kunnen verifieeren.
-- Build a Test Bench in order to verify this module.
entity genericClockDelay is

	generic(desiredClock: integer := 10;  -- 10 Hz
           inClockFreq: natural := 100);  -- 100 Hz
			
	port 
	(
		clk,rst  : in  std_logic;
		outClock  : out std_logic
	);
	
end entity;

architecture behaviour of genericClockDelay is
	-- Number of input clock periods per output clock period.
	constant divisor : natural := inClockFreq/desiredClock;
	-- The output is low for the first (divisor/2) input periods and high
	-- for the remaining ones, so an odd divisor still gives the exact
	-- output frequency (only the duty cycle is then slightly off 50%).
	constant lowCount : natural := divisor/2;
	
	signal count : natural range 0 to divisor-1 := 0;
	signal clockOut : std_logic := '0';
begin

	-- Elaboration-time checks of the generics.
	assert desiredClock > 0 and inClockFreq >= 2*desiredClock
	report "genericClockDelay: desiredClock must be > 0 and at most inClockFreq/2"
	severity failure;
	
	assert inClockFreq mod desiredClock = 0
	report "genericClockDelay: inClockFreq is not a multiple of desiredClock, output frequency is approximate"
	severity warning;
	
	process (clk, rst)
		variable nextCount : natural range 0 to divisor-1;
	begin
		if rst = '1' then
			count <= 0;
			clockOut <= '0';
		elsif rising_edge(clk) then
			if count = divisor-1 then
				nextCount := 0;
			else
				nextCount := count+1;
			end if;
			count <= nextCount;
			
			-- Registered output: no combinational glitches on the derived clock.
			if nextCount < lowCount then
				clockOut <= '0';
			else
				clockOut <= '1';
			end if;
		end if;
	end process;
	
	outClock <= clockOut;
	
end architecture;


