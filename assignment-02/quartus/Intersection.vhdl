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
  
  -- Freeze request as seen by the controller clock.
  signal frozen : std_logic := '0';
  -- Per-colour display enable; used to flash orange in standby.
  signal lightMask : std_logic_vector(2 downto 0);
  -- Time indication shown on LED9.
  signal timeTick : std_logic;
  -- stdby/test as std_logic for the controller ports.
  signal stbyBit, testBit : std_logic;
  
  -- Segment that shows each colour. The DE10-Lite displays are active-low,
  -- bit 0 = top (a), bit 6 = middle (g), bit 3 = bottom (d).
  type segmentTable is array (green to red) of natural range 0 to 7;
  constant segmentOf : segmentTable := (red => 0, orange => 6, green => 3);
  
  function to_std_logic(b : boolean) return std_logic is
  begin
    if b then
      return '1';
    else
      return '0';
    end if;
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
	
  -- Inputs. The push buttons are active-low.
  stdby <= SW(0) = '1';
  test  <= SW(1) = '1';
  stop  <= not KEY(0);
  
  stbyBit <= to_std_logic(stdby);
  testBit <= to_std_logic(test);
  
  -- Clocks: 10 MHz -> PLL (12 kHz) -> 60 Hz for the controller, and
  -- 60 Hz -> 1 Hz and 5 Hz for LED9 and the standby flashing.
  -- There is no reset button, so the dividers' reset inputs are tied low.
  clock60Hz : combinedClockDelay
    generic map (desiredClock => 60)
    port map (clk => ADC_CLK_10, rst => '0', pllClock => trafficPLLClock);
  
  clock1Hz : genericClockDelay
    generic map (desiredClock => 1, inClockFreq => 60)
    port map (clk => trafficPLLClock, rst => '0', outClock => secondsClock);
  
  clock5Hz : genericClockDelay
    generic map (desiredClock => 5, inClockFreq => 60)
    port map (clk => trafficPLLClock, rst => '0', outClock => fiveHzClock);
  
  -- Freeze: tlc has no enable input, so its clock is blocked instead.
  -- frozen only changes while the clock is low, which means blocking or
  -- releasing the clock can never produce a shortened pulse.
  freezeSample : process (trafficPLLClock)
  begin
    if falling_edge(trafficPLLClock) then
      frozen <= stop;
    end if;
  end process;
  
  trafficClock <= '0' when frozen = '1' else trafficPLLClock;
  
  controller : tlc
    port map (clk  => trafficClock,
              stby => stbyBit,
              test => testBit,
              r1 => vk1(red), y1 => vk1(orange), g1 => vk1(green),
              r2 => vk2(red), y2 => vk2(orange), g2 => vk2(green));
  
  -- In standby the controller holds both lights on orange; showing orange
  -- only while the 1 Hz clock is high makes it flash.
  lightMask <= (orange => secondsClock, others => '1') when stdby else
               (others => '1');
  
  -- Light 1 on HEX0, light 2 on HEX1. Unused segments and the decimal
  -- point stay dark.
  displays : process (vk1, vk2, lightMask)
    variable segments1, segments2 : std_logic_vector(7 downto 0);
  begin
    segments1 := (others => '1');
    segments2 := (others => '1');
    for colour in green to red loop
      segments1(segmentOf(colour)) := not (vk1(colour) and lightMask(colour));
      segments2(segmentOf(colour)) := not (vk2(colour) and lightMask(colour));
    end loop;
    HEX0 <= segments1;
    HEX1 <= segments2;
  end process;
  
  -- LED9 blinks at 1 Hz, or at 5 Hz in test mode.
  timeTick <= fiveHzClock when test else secondsClock;
  
  LEDR <= (0 => SW(0),    -- standby
           1 => SW(1),    -- test mode
           2 => stop,     -- freeze
           9 => timeTick,
           others => '0');
  
end architecture;

