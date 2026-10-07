-- Assignment 2 - integration testbench for the Intersection top level
--
-- Own verification testbench, NOT instructor material (the instructor's
-- Aldec testbench was not available). The generated PLL is replaced by the
-- behavioural 12 kHz model in pllKlok_sim.vhd; everything downstream
-- (combinedClockDelay, genericClockDelay, tlc, Intersection) is the real RTL.
--
-- SSD patterns (active-low, bit 0 = a/top, bit 6 = g/middle, bit 3 = d/bottom):
--   red = FE, orange = BF, green = F7, dark = FF
-- HEX0 shows traffic light 1 (r1/y1/g1), HEX1 shows traffic light 2.
--
-- Scenario (simulated time ~100 s):
--   1. standby (SW0=1): both displays flash orange, 0.5 s on / 0.5 s off
--   2. standby released: YY ~1 s, then a full normal cycle with exact
--      durations RY 5 s, GR 45 s, YR 5 s, RG 30 s
--   3. test mode (SW1=1): every state lasts 1 s
--   4. freeze (KEY0 held): displays frozen 3 s, then resume with the
--      remaining time of the interrupted state
--   5. standby while running (+ freeze, + test): orange flashing immediately
-- (VHDL-2008: uses std.env.finish to end the free-running PLL model clock.)
-- Concurrent monitors check, at every output change:
--   LED9 period (1 s normal / 0.2 s test), LEDR0/1/2 = SW0/SW1/freeze,
--   LEDR8..3 = 0, unused segments and decimal points off, at most one lit
--   segment per light, no red/green in standby, and no conflicting lights.

library ieee;
use ieee.std_logic_1164.all;

entity tb_intersection is
end entity;

architecture sim of tb_intersection is

	subtype ssd is std_logic_vector(7 downto 0);
	constant RED    : ssd := x"FE";
	constant ORANGE : ssd := x"BF";
	constant GREEN  : ssd := x"F7";
	constant DARK   : ssd := x"FF";

	constant TOL  : time := 10 us;          -- timing tolerance for exact edges
	constant TICK : time := 1 sec / 60;     -- one traffic-light clock period

	signal ADC_CLK_10 : std_logic := '0';   -- unused by the PLL model
	signal KEY  : std_logic_vector(1 downto 0) := "11";
	signal SW   : std_logic_vector(9 downto 0) := (others => '0');
	signal HEX0, HEX1 : ssd;
	signal LEDR : std_logic_vector(9 downto 0);

	signal finished : boolean := false;
	-- error/check counters of the concurrent monitors
	signal monErrors, monChecks : natural := 0;
	signal ledErrors, ledChecks : natural := 0;

	function img(v : ssd) return string is
		constant HEX : string(1 to 16) := "0123456789ABCDEF";
		variable hi, lo : natural := 0;
	begin
		for i in 7 downto 4 loop
			hi := hi * 2; if v(i) = '1' then hi := hi + 1; end if;
		end loop;
		for i in 3 downto 0 loop
			lo := lo * 2; if v(i) = '1' then lo := lo + 1; end if;
		end loop;
		return HEX(hi + 1) & HEX(lo + 1);
	end function;

	function lit(v : ssd) return natural is
		variable n : natural := 0;
	begin
		if v(0) = '0' then n := n + 1; end if;
		if v(6) = '0' then n := n + 1; end if;
		if v(3) = '0' then n := n + 1; end if;
		return n;
	end function;

begin

	dut : entity work.Intersection
		port map (ADC_CLK_10 => ADC_CLK_10, KEY => KEY, SW => SW,
		          HEX0 => HEX0, HEX1 => HEX1, LEDR => LEDR);

	---------------------------------------------------------------------------
	-- Invariants on every change of inputs or outputs
	---------------------------------------------------------------------------
	monitor : process
		variable errs, checks : natural := 0;

		procedure check(constant ok : in boolean; constant msg : in string) is
		begin
			checks := checks + 1;
			if not ok then
				errs := errs + 1;
				report "FAIL monitor @" & time'image(now) & ": " & msg &
				       " HEX0=" & img(HEX0) & " HEX1=" & img(HEX1) severity error;
			end if;
		end procedure;

		procedure check_ssd(constant v : in ssd; constant name : in string) is
		begin
			check(v(7) = '1' and v(5) = '1' and v(4) = '1' and v(2) = '1' and v(1) = '1',
			      name & " unused segment or decimal point lit");
			check(lit(v) <= 1, name & " more than one light on");
		end procedure;
	begin
		wait for 1 ms;
		while not finished loop
			wait on HEX0, HEX1, LEDR, SW, KEY, finished for 100 ms;
			wait for 1 us;   -- let the combinational outputs settle
			check(LEDR(8 downto 3) = "000000", "unused LEDR8..3 not off");
			check(LEDR(0) = SW(0), "LEDR0 /= SW0 (standby)");
			check(LEDR(1) = SW(1), "LEDR1 /= SW1 (test)");
			check(LEDR(2) = not KEY(0), "LEDR2 /= freeze (KEY0 pressed)");
			check_ssd(HEX0, "HEX0");
			check_ssd(HEX1, "HEX1");
			if SW(0) = '1' then
				check(HEX0(0) = '1' and HEX0(3) = '1' and HEX1(0) = '1' and HEX1(3) = '1',
				      "red/green lit in standby");
				check(HEX0 = HEX1, "lights differ in standby");
			else
				check(lit(HEX0) = 1 and lit(HEX1) = 1, "a light is dark outside standby");
				-- at least one light red, or both orange (YY just after standby)
				check(HEX0 = RED or HEX1 = RED or (HEX0 = ORANGE and HEX1 = ORANGE),
				      "conflicting lights");
			end if;
		end loop;
		monErrors <= errs;
		monChecks <= checks;
		wait;
	end process;

	---------------------------------------------------------------------------
	-- LED9 period: 1 s in normal mode, 0.2 s in test mode
	---------------------------------------------------------------------------
	led9 : process
		variable errs, checks : natural := 0;
		variable lastRise : time := 0 ns;
		variable valid : natural := 0;      -- rising edges seen since last SW1 change
		variable expected : time;
	begin
		while not finished loop
			wait until rising_edge(LEDR(9)) or SW(1)'event or finished;
			if SW(1)'event then
				valid := 0;                 -- mux switches mid-period: resynchronise
			elsif rising_edge(LEDR(9)) then
				if valid >= 1 then
					if SW(1) = '1' then expected := 200 ms; else expected := 1 sec; end if;
					checks := checks + 1;
					if now - lastRise > expected + TOL or now - lastRise < expected - TOL then
						errs := errs + 1;
						report "FAIL LED9 period " & time'image(now - lastRise) &
						       " expected " & time'image(expected) severity error;
					end if;
				end if;
				lastRise := now;
				valid := valid + 1;
			end if;
		end loop;
		ledErrors <= errs;
		ledChecks <= checks;
		wait;
	end process;

	---------------------------------------------------------------------------
	-- Scenario
	---------------------------------------------------------------------------
	stimulus : process
		variable errs, checks : natural := 0;
		variable lastChange : time;
		variable t0 : time;

		procedure check(constant ok : in boolean; constant msg : in string) is
		begin
			checks := checks + 1;
			if not ok then
				errs := errs + 1;
				report "FAIL @" & time'image(now) & ": " & msg &
				       " (HEX0=" & img(HEX0) & " HEX1=" & img(HEX1) & ")" severity error;
			end if;
		end procedure;

		-- Wait for the next display change and check the new pattern and how
		-- long the previous one lasted (window [minDur, maxDur]).
		procedure expect_next(constant e0, e1 : in ssd;
		                      constant minDur, maxDur : in time;
		                      constant name : in string) is
			variable dur : time;
		begin
			wait on HEX0, HEX1 for maxDur + 1 sec;
			dur := now - lastChange;
			wait for 1 us;
			check(HEX0 = e0 and HEX1 = e1, name & ": expected HEX0=" & img(e0) &
			      " HEX1=" & img(e1));
			check(dur >= minDur and dur <= maxDur, name & ": previous state lasted " &
			      time'image(dur) & ", expected " & time'image(minDur) & " .. " &
			      time'image(maxDur));
			lastChange := now - 1 us;
		end procedure;

		-- Check orange flashing in standby: n half periods of 0.5 s.
		procedure expect_flashing(constant n : in natural; constant name : in string) is
			variable last : time;
		begin
			wait on HEX0 for 2 sec;      -- synchronise to a flash edge
			last := now;
			for i in 1 to n loop
				wait on HEX0 for 2 sec;
				wait for 1 us;
				check(HEX0 = ORANGE or HEX0 = DARK, name & ": not orange/dark");
				check(HEX0 = HEX1, name & ": displays not flashing together");
				check(now - 1 us - last >= 500 ms - TOL and now - 1 us - last <= 500 ms + TOL,
				      name & ": flash half period " & time'image(now - 1 us - last));
				last := now - 1 us;
			end loop;
		end procedure;

	begin
		-- 1. Standby from power-up: orange flashing on both lights.
		SW(0) <= '1';
		wait for 10 ms;
		expect_flashing(4, "standby");

		-- 2. Leave standby: YY steady orange, then a full normal cycle.
		wait until rising_edge(HEX0(6));  -- orange just switched off
		wait for 100 ms;
		SW(0) <= '0';
		lastChange := now;
		wait for 1 us;
		check(HEX0 = ORANGE and HEX1 = ORANGE, "after standby release: expected steady orange (YY)");
		expect_next(RED, ORANGE, 1 sec - 2*TICK, 1 sec + TOL, "YY -> RY");
		expect_next(GREEN, RED,  5 sec - TOL,  5 sec + TOL,  "RY -> GR (RY = 5 s)");
		expect_next(ORANGE, RED, 45 sec - TOL, 45 sec + TOL, "GR -> YR (GR = 45 s)");
		expect_next(RED, GREEN,  5 sec - TOL,  5 sec + TOL,  "YR -> RG (YR = 5 s)");
		expect_next(RED, ORANGE, 30 sec - TOL, 30 sec + TOL, "RG -> RY (RG = 30 s)");

		-- 3. Test mode: every state 1 s.
		wait for 100 ms;
		SW(1) <= '1';
		expect_next(GREEN, RED,  0 ns,            1 sec + TOL, "test: RY -> GR");
		expect_next(ORANGE, RED, 1 sec - TOL,     1 sec + TOL, "test: GR -> YR (1 s)");
		expect_next(RED, GREEN,  1 sec - TOL,     1 sec + TOL, "test: YR -> RG (1 s)");
		expect_next(RED, ORANGE, 1 sec - TOL,     1 sec + TOL, "test: RG -> RY (1 s)");

		-- 4. Freeze 0.3 s into RY for 3 s: nothing may change; afterwards the
		--    remaining 0.7 s of RY elapse, then normal 1 s steps.
		wait for 300 ms;
		KEY(0) <= '0';
		t0 := now;
		wait on HEX0, HEX1 for 3 sec;
		check(now - t0 >= 3 sec, "freeze: display changed while frozen");
		check(HEX0 = RED and HEX1 = ORANGE, "freeze: RY not held");
		KEY(0) <= '1';
		lastChange := now - 300 ms;     -- RY had run for 0.3 s before the freeze
		expect_next(GREEN, RED, 1 sec - 2*TICK, 1 sec + 2*TICK, "after freeze: RY -> GR");
		expect_next(ORANGE, RED, 1 sec - TOL, 1 sec + TOL, "after freeze: GR -> YR (1 s)");

		-- 5. Standby while running (test still on): flashing immediately.
		wait for 400 ms;
		SW(0) <= '1';
		wait for 1 us;
		check((HEX0 = ORANGE or HEX0 = DARK) and HEX1 = HEX0,
		      "standby while running: not orange/dark at once");
		expect_flashing(3, "standby + test");
		-- freeze has no effect on standby flashing
		KEY(0) <= '0';
		expect_flashing(3, "standby + test + freeze");
		KEY(0) <= '1';
		SW(1) <= '0';
		expect_flashing(2, "standby");

		finished <= true;
		wait for 1 ms;   -- monitors publish their counters

		errs := errs + monErrors + ledErrors;
		checks := checks + monChecks + ledChecks;
		report "monitor checks: " & integer'image(monChecks) &
		       ", LED9 period checks: " & integer'image(ledChecks);
		if errs = 0 then
			report "tb_intersection: PASS (" & integer'image(checks) & " checks)";
		else
			report "tb_intersection: FAIL (" & integer'image(errs) & " of " &
			       integer'image(checks) & " checks failed)" severity failure;
		end if;
		-- The PLL model clock runs forever: end the simulation explicitly.
		std.env.finish;
		wait;
	end process;

end architecture;
