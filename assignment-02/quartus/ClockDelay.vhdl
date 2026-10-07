library ieee;
use ieee.std_logic_1164.all;
use work.Assignment2Package.all;



-- Dit is een gekombineerde generieke+pll gebaseerde klok vertrager 
-- This is a combined generic + pll based clock delay
entity combinedClockDelay is

	generic(desiredClock: integer := 60);  -- 60 Hz
			
	port 
	(
		clk,rst  : in  std_logic;  -- the input clock (10 MHz) and the reset line
		pllClock : buffer std_logic -- this is the buffered output clock that runs with the desired frequency
	);
	
end entity;

architecture behaviour of combinedClockDelay is
	constant pllKlokFreq   : natural := 12000;
	constant clockTopValue : natural := pllKlokFreq/desiredClock;
	signal pllLocked : std_logic;
	signal combinedClockDelayKlok : std_logic;
	
	
	-- De PLL klokvertrager (Altera IP catalog)
	component pllKlok is
	port
	(
		areset		: in std_logic  := '0';
		inclk0		: in std_logic  := '0';
		c0		: out std_logic ;
		locked		: out std_logic 
	);
	end component;
	

begin


-- Dit is een voorbeeld dat de PLL gebruikt om de 10 MHz klok lijn om te zetten in 12 kHz.
-- This is an example that uses the PLL for generating 12 kHz from 10 MHz.

   -- this instance converts 10 MHz ==> 12 kHz */ 
   pll : pllKlok port map(areset=>rst,inclk0=>clk,c0=>combinedClockDelayKlok,
	                       locked=>pllLocked);
	
	-- this instances converts 12 kHz ==> desired clock (generic value 60 Hz)
	vertrager : genericClockDelay generic map(desiredClock=>desiredClock,inClockFreq=>pllKlokFreq) 
	                          port map(clk=>combinedClockDelayKlok,rst=>rst,
									           outClock=>pllClock);
									  
end architecture;
