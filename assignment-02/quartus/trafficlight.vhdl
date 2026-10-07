-----------------------------------------------------------
--Circuit Design and Simulation with VHDL, 2nd edition
--V. A. Pedroni, MIT Press, 2010
--TLC implemented with a timed state machine
-------------------------------------------------------- 
LIBRARY ieee;  
USE ieee.std_logic_1164.all;
--------------------------------------------------------
ENTITY tlc IS
 GENERIC ( 
   timeRG: POSITIVE := 1800;  --30s with 60Hz clock  
  timeRY: POSITIVE := 300;  --5s with 60Hz clock
  timeGR: POSITIVE := 2700;  --45s with 60Hz clock
  timeYR: POSITIVE := 300;  --5s with 60Hz clock
  timeTEST: POSITIVE := 60;  --1s with 60Hz clock
  timeMAX: POSITIVE := 2700); --max of all above
 PORT (
  clk, stby, test : IN STD_LOGIC;
  r1, r2, y1, y2, g1, g2: OUT STD_LOGIC);
END tlc;
--------------------------------------------------------
ARCHITECTURE fsm OF tlc IS
 TYPE state IS (RG, RY, GR, YR, YY);
 SIGNAL pr_state, nx_state: state;
 SIGNAL timer: INTEGER RANGE 0 TO timeMAX;
BEGIN
 -----Lower section of FSM:------
 PROCESS (clk, stby)
  VARIABLE count : INTEGER RANGE 0 TO timeMAX;
 BEGIN
  IF (stby='1') THEN
   pr_state <= YY;
   count := 0;
  ELSIF (clk'EVENT AND clk='1') THEN
   count := count + 1; 
   IF (count>=timer) THEN 
    pr_state <= nx_state;
    count := 0;
    END IF;
  END IF; 
 END PROCESS;
 -----Upper section of FSM:------
 PROCESS (pr_state, test)
 BEGIN
  CASE pr_state IS
   WHEN RG => 
    r1<='1'; y1<='0'; g1<='0';
    r2<='0'; y2<='0'; g2<='1';
    nx_state <= RY;
    IF (test='0') THEN 
     timer <= timeRG;
    ELSE 
     timer <= timeTEST;
    END IF;
   WHEN RY => 
    r1<='1'; y1<='0'; g1<='0';
    r2<='0'; y2<='1'; g2<='0';
    nx_state <= GR;
    IF (test='0') THEN 
     timer <= timeRY;
    ELSE 
     timer <= timeTEST;
    END IF;
   WHEN GR => 
    r1<='0'; y1<='0'; g1<='1';
    r2<='1'; y2<='0'; g2<='0';
    nx_state <= YR;
    IF (test='0') THEN 
     timer <= timeGR;
    ELSE 
     timer <= timeTEST;
    END IF;
   WHEN YR =>
    r1<='0'; y1<='1'; g1<='0';
    r2<='1'; y2<='0'; g2<='0'; 
    nx_state <= RG;
    IF (test='0') THEN 
     timer <= timeYR;
    ELSE 
     timer <= timeTEST; 
    END IF; 
   WHEN YY => 
    r1<='0'; y1<='1'; g1<='0';
    r2<='0'; y2<='1'; g2<='0';
    timer <= timeTEST; --to avoid latches 
	 
    nx_state <= RY;
  END CASE;
 END PROCESS;
END fsm; 
-------------------------------------------------------- 
