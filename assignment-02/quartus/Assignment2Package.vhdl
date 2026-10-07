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
-- Verwijder deze assert bij bewerking code / Remove this message when editing the code.
assert false
report "úBeste student, Dit deel van de hardware ontbreekt/This part of thehardware is missing."ù
severity failure;
begin								  

-- Verwijder deze assert bij bewerking code / Remove this message when editing the code.
assert false
report "úBeste student, Dit deel van de hardware ontbreekt/This part of thehardware is missing."ù
severity failure;
	
end architecture;


