-- Assignment 2 - unit testbench for genericClockDelay
--
-- Own verification testbench, NOT instructor material.
--
-- For several (desiredClock, inClockFreq) pairs the output is checked
-- after EVERY rising input edge against an exact reference model:
--   divisor = inClockFreq / desiredClock
--   k-th rising edge after reset release -> outClock = '1' iff (k mod divisor) >= divisor/2
-- This fixes the output period at exactly `divisor` input periods.
-- Asynchronous reset is checked by asserting rst between clock edges in the
-- middle of a run: outClock must drop to '0' before the next clock edge, and
-- the sequence must restart from k = 1 after release.

library ieee;
use ieee.std_logic_1164.all;
use work.Assignment2Package.all;

entity tb_genericClockDelay is
end entity;

architecture sim of tb_genericClockDelay is

	constant T_CLK : time := 10 ns;   -- rising edges at 5, 15, 25, ... ns

	type int_array is array (natural range <>) of natural;
	-- index:                          0      1     2     3    4
	constant DESIRED  : int_array := (60,     1,    5,    10,  3);
	constant IN_FREQ  : int_array := (12000,  60,   60,   100, 21);
	-- 0: PLL 12 kHz -> 60 Hz traffic clock (divisor 200)
	-- 1: 60 Hz -> 1 Hz seconds clock       (divisor 60)
	-- 2: 60 Hz -> 5 Hz test-mode clock     (divisor 12)
	-- 3: generic defaults 100 Hz -> 10 Hz  (divisor 10, instantiated WITHOUT generic map)
	-- 4: odd divisor 7                      (3 low + 4 high)

	signal clk  : std_logic := '0';
	signal rst  : std_logic := '1';
	signal outs : std_logic_vector(DESIRED'range);
	signal done : std_logic_vector(DESIRED'range) := (others => '0');
	signal finished : boolean := false;

	-- Reset is released at 22 ns (edge k=1 at 25 ns), asserted again at
	-- 9518 ns (after edge k=950) and released at 10022 ns.
	constant RST_RELEASE_1 : time := 22 ns;
	constant RST_ASSERT_2  : time := 9518 ns;
	constant RST_RELEASE_2 : time := 10022 ns;

begin

	clk <= not clk after T_CLK/2 when not finished;

	rst <= '1', '0' after RST_RELEASE_1, '1' after RST_ASSERT_2, '0' after RST_RELEASE_2;

	gen : for i in DESIRED'range generate

		with_generics : if i /= 3 generate
			dut : genericClockDelay
				generic map (desiredClock => DESIRED(i), inClockFreq => IN_FREQ(i))
				port map (clk => clk, rst => rst, outClock => outs(i));
		end generate;

		defaults : if i = 3 generate
			dut : genericClockDelay
				port map (clk => clk, rst => rst, outClock => outs(i));
		end generate;

		checker : process
			constant d : natural := IN_FREQ(i) / DESIRED(i);
			variable errors : natural := 0;
			variable highSeen : boolean := false;

			procedure run(constant edges : in natural; constant phase : in string) is
				variable expected : std_logic;
			begin
				for k in 1 to edges loop
					wait until rising_edge(clk);
					wait for 1 ns;
					if (k mod d) >= d/2 then expected := '1'; else expected := '0'; end if;
					if expected = '1' then highSeen := true; end if;
					if outs(i) /= expected then
						errors := errors + 1;
						report "FAIL divisor=" & integer'image(d) & " " & phase &
						       " edge k=" & integer'image(k) & " expected " &
						       std_logic'image(expected) & " got " & std_logic'image(outs(i))
						       severity error;
					end if;
				end loop;
			end procedure;

		begin
			-- During the initial reset the output must be '0'.
			wait for 1 ns;
			if outs(i) /= '0' then
				errors := errors + 1;
				report "FAIL divisor=" & integer'image(d) & " output not '0' during reset" severity error;
			end if;

			wait until rst = '0';
			run(4*d + 3, "after first reset");

			-- Asynchronous reset in the middle of a run.
			wait until rst = '1';
			wait for 1 ns;   -- next clock edge is 2 ns later
			if outs(i) /= '0' then
				errors := errors + 1;
				report "FAIL divisor=" & integer'image(d) & " async reset did not clear output" severity error;
			end if;

			wait until rst = '0';
			run(3*d, "after second reset");

			if errors = 0 and highSeen then
				report "genericClockDelay desiredClock=" & integer'image(DESIRED(i)) &
				       " inClockFreq=" & integer'image(IN_FREQ(i)) & " divisor=" &
				       integer'image(d) & ": PASS";
			else
				report "genericClockDelay divisor=" & integer'image(d) & ": FAIL" severity failure;
			end if;
			done(i) <= '1';
			wait;
		end process;

	end generate;

	-- The reference timing above relies on all checkers finishing their
	-- first run before the second reset; verify that and stop the clock.
	supervisor : process
	begin
		wait for RST_ASSERT_2 - 1 ns;
		wait until done = (done'range => '1') for 20 us;
		assert done = (done'range => '1')
			report "tb_genericClockDelay: FAIL (timeout)" severity failure;
		report "tb_genericClockDelay: PASS (all configurations)";
		finished <= true;
		wait;
	end process;

end architecture;
