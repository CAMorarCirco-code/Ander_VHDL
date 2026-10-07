------- Opdracht 2 / Assignment 2 DSDL practicum
------- Altera DE10-Lite
------- ir drs E.J Boks, HAN Embedded Systems Engineering. https://ese.han.nl
-------- $Id$
------- Top Level bestand/file

-- Pedroni 2e editie voorbeeld 11.7 op bladzijde 303
-- Enigzins aangepast om te koppelen aan HW pinnen van de MAX10 op het DE10-Lite bord.

-- Opdracht / Assignment details : 
-- Koppel standby aan SW0 en LED0
-- Koppel testmode aan SW1 end LED1
-- Koppel tijdverloop aan LED9 	 
-- Koppel LEDs en HEX aan vk signalen
-- Maak de vertragingsklokken voor de LEDs en de verkeerslichten
-- Instantieer de tlc en breng alle signalen samen in deze component

-- Pedroni 2nd edition example 11.7 on page 303
-- Slightly modified to connect to HW pins of the MAX10 on the DE10-Lite board.

-- Assignment details :
-- Connect standby to SW0 and LED0
-- Connect test mode to SW1 and LED1
-- Connect time lapse to LED9
-- Connect LEDs and HEX to vk signals
-- Make the delay clocks for the LEDs and the traffic lights
-- Instantiate the tlc and bring all the signals together in this component	   
	   
library ieee;
use ieee.std_logic_1164.all;
use work.Assignment2Package.all;

entity Intersection is
	
	generic(SimulationMode : boolean := false);
	
    port(ADC_CLK_10 : in std_logic;
       KEY : in std_logic_vector(1 downto 0);
       SW : in STD_LOGIC_VECTOR(9 DOWNTO 0);
       HEX0 : out std_logic_vector(7 downto 0); -- linker licht
       HEX1 : out std_logic_vector(7 downto 0); -- rechter licht
       LEDR : out std_logic_vector(9 downto 0));
  
end entity Intersection;

architecture Intersection_behav of Intersection is

  -- Signals that provide the derived clock signals.
  signal trafficPLLClock, trafficClock : std_logic;
  signal secondsClock,fiveHzClock : std_logic;
  
  constant green : natural  := 0;
  constant orange : natural := green+1;
  constant red : natural   := orange+1;
  
  -- Signals that are linked to buttons/switches etc
  signal stop : std_logic;
  signal stdby : boolean := false;
  signal test : boolean := false;
  
  -- There are two traffic lights.
  signal vk1,vk2 : std_logic_vector(2 downto 0);
  
  --- Clock Delay component  (Generic+PLL clock delay)
  component combinedClockDelay is

    generic(desiredClock: integer := 60);  -- 12 kHz
    
    port 
      (
        clk,rst : in std_logic;
        pllClock : out std_logic
	);

  end component;
  
  -- Traffic Light Controller component
  component tlc IS
    GENERIC ( 
      timeRG: POSITIVE := 1800;  --30s with 60Hz clock  
      timeRY: POSITIVE := 300;  --5s with 60Hz clock
      timeGR: POSITIVE := 2700;  --45s with 60Hz clock
      timeYR: POSITIVE := 300;  --5s with 60Hz clock
      timeTEST: POSITIVE := 60;  --1s with 60Hz clock
      timeMAX: POSITIVE := 2700); --max of all above
    
    PORT (
      clk, stby, test: IN STD_LOGIC;
      r1, r2, y1, y2, g1, g2: OUT STD_LOGIC );
  END component;


begin

  -- koppel eigen namen aan board SSD pinnen, klok en reset pinnen.
  -- Gebruik de componenten om klokvertragers aan te maken: 1 Hz, 5 Hz en 60 Hz.
  -- Gebruik de tlc component om de verkeerslicht toestandmachine te gebruiken.
  -- Koppel de tlc uitgangen aan de juiste 7S leds. 
  -- Gebruik de gewone LEDs om trage klokken zichtbaar te maken.
  -- Schakel de niet gebruikte LEDs en 7S elementen uit.
  
  -- Link signals to buttons/switches/HEX display pins etc. 
  -- Use the components to create clock delays: 1 Hz, 5 Hz and 60 Hz.
  -- Use the tlc component to use the traffic light state machine.
  -- Connect the tlc outputs to the correct 7S LEDs.
  -- Use the regular LEDs to visualize slow clocks.
  -- Turn off the unused LEDs and 7S elements.
	
-- Verwijder deze assert bij bewerking code / Remove this message when editing the code.
assert false
report "Beste student, Dit deel van de hardware ontbreekt/This part of thehardware is missing."ù
severity failure;
  
end architecture;

