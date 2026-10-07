-- Assignment 2 - SIMULATION-ONLY behavioural stand-in for the generated pllKlok
--
-- NOT the Intel ALTPLL. The real quartus/pllKlok.vhd instantiates altpll from
-- the Intel altera_mf library, which is not available to GHDL. This model has
-- the same entity/ports and produces the PLL's configured output frequency,
-- 10 MHz * 3 / 2500 = 12 kHz (50 % duty), directly from simulation time.
-- inclk0 is ignored, so the testbench does not have to simulate 10 MHz.
-- It is used only by tb/run_ghdl.sh and never by Quartus.

library ieee;
use ieee.std_logic_1164.all;

entity pllKlok is
	port (
		areset : in std_logic := '0';
		inclk0 : in std_logic := '0';
		c0     : out std_logic;
		locked : out std_logic
	);
end entity;

architecture sim_model of pllKlok is
	constant HALF_PERIOD : time := 1 sec / 24000;   -- 12 kHz
	signal clk : std_logic := '0';
begin
	process
	begin
		if areset = '1' then
			clk <= '0';
			wait until areset = '0';
		end if;
		wait for HALF_PERIOD;
		clk <= not clk;
	end process;

	c0     <= clk;
	locked <= not areset;
end architecture;
