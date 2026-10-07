-- Assignment 1 - integration testbench for the supplied toplevel entity
--
-- Own verification testbench, NOT the instructor's original TestBench.vhd
-- (which was not available).
--
-- 1. The case from the assignment PDF waveform: SW = 0x2F2 (754), no key
--    pressed -> HEX0 = 99, HEX1 = 92, HEX2 = F8, HEX3 = C0.
-- 2. 754 with every KEY combination (KEY is active-low:
--    KEY(0) pressed -> doReverse, KEY(1) pressed -> doInverse).
-- 3. Exhaustive sweep of SW = 0..1023 for all four KEY combinations,
--    checking every display against hard-coded reference tables, and
--    LEDR = SW.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_toplevel is
end entity;

architecture sim of tb_toplevel is

	type ssd_table is array (0 to 9) of std_logic_vector(7 downto 0);
	type mode_table is array (0 to 3) of ssd_table;

	-- Indexed by KEY value: "11" = none pressed, "10" = KEY0 pressed (reverse),
	-- "01" = KEY1 pressed (inverse), "00" = both pressed.
	constant TABLES : mode_table := (
		0 => (x"FC", x"60", x"DA", x"F2", x"66", x"B6", x"BE", x"E0", x"FE", x"F6"), -- KEY="00" reverse+inverse
		1 => (x"3F", x"06", x"5B", x"4F", x"66", x"6D", x"7D", x"07", x"7F", x"6F"), -- KEY="01" inverse
		2 => (x"03", x"9F", x"25", x"0D", x"99", x"49", x"41", x"1F", x"01", x"09"), -- KEY="10" reverse
		3 => (x"C0", x"F9", x"A4", x"B0", x"99", x"92", x"82", x"F8", x"80", x"90")  -- KEY="11" normal
	);

	signal SW   : std_logic_vector(9 downto 0) := (others => '0');
	signal KEY  : std_logic_vector(1 downto 0) := "11";
	signal LEDR : std_logic_vector(9 downto 0);
	signal HEX0, HEX1, HEX2, HEX3 : std_logic_vector(7 downto 0);

	function to_hex(v : std_logic_vector(7 downto 0)) return string is
		constant HEX : string(1 to 16) := "0123456789ABCDEF";
	begin
		return HEX(to_integer(unsigned(v(7 downto 4))) + 1) &
		       HEX(to_integer(unsigned(v(3 downto 0))) + 1);
	end function;

begin

	dut : entity work.toplevel
		port map (SW => SW, KEY => KEY, LEDR => LEDR,
		          HEX0 => HEX0, HEX1 => HEX1, HEX2 => HEX2, HEX3 => HEX3);

	stimulus : process
		variable errors : natural := 0;
		variable checks : natural := 0;

		procedure check(constant name : in string;
		                signal   got  : in std_logic_vector(7 downto 0);
		                constant exp  : in std_logic_vector(7 downto 0)) is
		begin
			checks := checks + 1;
			if got /= exp then
				errors := errors + 1;
				report "FAIL " & name & " SW=" & integer'image(to_integer(unsigned(SW))) &
				       " KEY=" & std_logic'image(KEY(1)) & std_logic'image(KEY(0)) &
				       " expected=" & to_hex(exp) & " got=" & to_hex(got)
				       severity error;
			end if;
		end procedure;

		procedure check_all(constant n : in natural; constant k : in natural) is
		begin
			check("HEX0", HEX0, TABLES(k)(n mod 10));
			check("HEX1", HEX1, TABLES(k)((n / 10) mod 10));
			check("HEX2", HEX2, TABLES(k)((n / 100) mod 10));
			check("HEX3", HEX3, TABLES(k)((n / 1000) mod 10));
			checks := checks + 1;
			if LEDR /= SW then
				errors := errors + 1;
				report "FAIL LEDR /= SW" severity error;
			end if;
		end procedure;

	begin
		-- 1. Waveform case from the assignment PDF
		SW  <= "1011110010"; -- 0x2F2 = 754
		KEY <= "11";
		wait for 1 ns;
		check("PDF case HEX0", HEX0, x"99");
		check("PDF case HEX1", HEX1, x"92");
		check("PDF case HEX2", HEX2, x"F8");
		check("PDF case HEX3", HEX3, x"C0");

		-- 2. 754 with each KEY combination
		for k in 0 to 3 loop
			KEY <= std_logic_vector(to_unsigned(k, 2));
			wait for 1 ns;
			check_all(754, k);
		end loop;

		-- 3. Exhaustive sweep
		for k in 0 to 3 loop
			KEY <= std_logic_vector(to_unsigned(k, 2));
			for n in 0 to 1023 loop
				SW <= std_logic_vector(to_unsigned(n, 10));
				wait for 1 ns;
				check_all(n, k);
			end loop;
		end loop;

		if errors = 0 then
			report "tb_toplevel: PASS (" & integer'image(checks) & " checks)";
		else
			report "tb_toplevel: FAIL (" & integer'image(errors) & " of " &
			       integer'image(checks) & " checks failed)" severity failure;
		end if;
		wait;
	end process;

end architecture;
