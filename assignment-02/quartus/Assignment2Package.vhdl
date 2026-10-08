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
	-- One output period spans inClockFreq/desiredClock input periods. It is
	-- split into a low phase (half, rounded down) followed by a high phase
	-- (the rest), so an odd ratio still gives the right output frequency.
	constant periodLength : natural := inClockFreq/desiredClock;
	constant lowLength    : natural := periodLength/2;
	constant highLength   : natural := periodLength - lowLength;
	
	-- Input periods left in the current phase, and the current output level.
	signal remaining : natural range 0 to highLength := lowLength;
	signal level     : std_logic := '0';
begin

	assert desiredClock > 0 and inClockFreq >= 2*desiredClock
	report "genericClockDelay: desiredClock must be positive and no more than half of inClockFreq"
	severity failure;
	
	assert inClockFreq mod desiredClock = 0
	report "genericClockDelay: inClockFreq/desiredClock is not a whole number, the output frequency is rounded"
	severity warning;
	
	-- Phase timer: count down the current phase; on its last input period
	-- flip the output and load the length of the next phase.
	phaseTimer : process (clk, rst)
	begin
		if rst = '1' then
			level     <= '0';
			remaining <= lowLength;
		elsif rising_edge(clk) then
			if remaining = 1 then
				level <= not level;
				if level = '0' then
					remaining <= highLength;
				else
					remaining <= lowLength;
				end if;
			else
				remaining <= remaining - 1;
			end if;
		end if;
	end process;
	
	-- The output comes straight from a flip-flop, so the derived clock is glitch-free.
	outClock <= level;
	
end architecture;


