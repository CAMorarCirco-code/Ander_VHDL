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
  
  -- std_logic versions of stdby/test for the tlc ports.
  signal stbyLogic, testLogic : std_logic;
  -- freeze request, sampled on the falling edge of the 60 Hz clock
  signal stopSync : std_logic := '0';
  -- reset line of the clock delays
  signal reset : std_logic;
  -- orange segments enabled (flashes at 1 Hz in standby)
  signal orangeEnable : std_logic;
  
  -- Convert one traffic light (indexed by green/orange/red) to an
  -- active-low DE10-Lite SSD pattern:
  --   top segment (a, bit 0)    = red
  --   middle segment (g, bit 6) = orange
  --   lower segment (d, bit 3)  = green
  -- all other segments and the decimal point are off.
  function lightToSSD(light : std_logic_vector(2 downto 0);
                      orangeOn : std_logic) return std_logic_vector is
    variable segments : std_logic_vector(7 downto 0) := (others => '1');
  begin
    segments(0) := not light(red);
    segments(6) := not (light(orange) and orangeOn);
    segments(3) := not light(green);
    return segments;
  end function;
  
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
	
  -- The assignment defines no reset button: the clock delays are never reset.
  reset <= '0';
  
  -- Switches and button.
  stdby <= SW(0) = '1';           -- SW0: standby
  test  <= SW(1) = '1';           -- SW1: test mode
  stop  <= not KEY(0);            -- KEY0 (active-low) held down: freeze
  
  stbyLogic <= '1' when stdby else '0';
  testLogic <= '1' when test else '0';
  
  -- Clock delays:
  -- 10 MHz --(pllKlok)--> 12 kHz --(genericClockDelay)--> 60 Hz
  trafficDelay : combinedClockDelay
    generic map (desiredClock => 60)
    port map (clk => ADC_CLK_10, rst => reset, pllClock => trafficPLLClock);
  
  -- 60 Hz --> 1 Hz (time progression, normal mode / standby flashing)
  secondsDelay : genericClockDelay
    generic map (desiredClock => 1, inClockFreq => 60)
    port map (clk => trafficPLLClock, rst => reset, outClock => secondsClock);
  
  -- 60 Hz --> 5 Hz (time progression, test mode)
  fiveHzDelay : genericClockDelay
    generic map (desiredClock => 5, inClockFreq => 60)
    port map (clk => trafficPLLClock, rst => reset, outClock => fiveHzClock);
  
  -- Freeze: stop the clock of the traffic light controller. The request is
  -- sampled while the clock is low, so gating cannot create a short pulse.
  process (trafficPLLClock)
  begin
    if falling_edge(trafficPLLClock) then
      stopSync <= stop;
    end if;
  end process;
  
  trafficClock <= trafficPLLClock and not stopSync;
  
  -- Traffic light controller (Pedroni).
  controller : tlc
    port map (clk => trafficClock, stby => stbyLogic, test => testLogic,
              r1 => vk1(red), y1 => vk1(orange), g1 => vk1(green),
              r2 => vk2(red), y2 => vk2(orange), g2 => vk2(green));
  
  -- Orange flashes in standby, otherwise it follows the controller.
  orangeEnable <= secondsClock when stdby else '1';
  
  HEX0 <= lightToSSD(vk1, orangeEnable);
  HEX1 <= lightToSSD(vk2, orangeEnable);
  
  -- LEDs.
  LEDR(0) <= stbyLogic;
  LEDR(1) <= testLogic;
  LEDR(2) <= stop;
  LEDR(8 downto 3) <= (others => '0');
  LEDR(9) <= fiveHzClock when test else secondsClock;
  
end architecture;

