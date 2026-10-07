-- Assignment 1 - unit testbench for SevenSegmentDriver.integer_to_ssd
--
-- Own verification testbench, NOT the instructor's original TestBench.vhd
-- (which was not available). Expected values are hard-coded tables, not
-- computed with the driver's own reverseVector, so the check is
-- independent of the implementation.
--
-- Encoding: bit 0 = a ... bit 6 = g, bit 7 = dp, active-low ('0' = lit).
-- Normal-mode table taken from the waveform in the assignment PDF.

library ieee;
use ieee.std_logic_1164.all;
use work.SevenSegmentDriver.all;

entity tb_seven_segment_driver is
end entity;

architecture sim of tb_seven_segment_driver is

	type ssd_table is array (0 to 9) of std_logic_vector(7 downto 0);

	-- doReverse = false, doInverse = false
	constant NORMAL : ssd_table := (x"C0", x"F9", x"A4", x"B0", x"99",
	                                x"92", x"82", x"F8", x"80", x"90");
	-- doReverse = true, doInverse = false (all 8 bits mirrored)
	constant REVERSED : ssd_table := (x"03", x"9F", x"25", x"0D", x"99",
	                                  x"49", x"41", x"1F", x"01", x"09");
	-- doReverse = false, doInverse = true (all 8 bits inverted)
	constant INVERTED : ssd_table := (x"3F", x"06", x"5B", x"4F", x"66",
	                                  x"6D", x"7D", x"07", x"7F", x"6F");
	-- doReverse = true, doInverse = true
	constant REV_INV : ssd_table := (x"FC", x"60", x"DA", x"F2", x"66",
	                                 x"B6", x"BE", x"E0", x"FE", x"F6");

	type int_array is array (natural range <>) of integer;
	constant INVALID_INPUTS : int_array := (-1000, -1, 10, 11, 15, 16, 99, 1023,
	                                        integer'low, integer'high);

	signal digit : integer := 0;

	function to_hex(v : std_logic_vector(7 downto 0)) return string is
		constant HEX : string(1 to 16) := "0123456789ABCDEF";
		variable hi, lo : natural := 0;
	begin
		for i in 7 downto 4 loop
			hi := hi * 2;
			if v(i) = '1' then hi := hi + 1; end if;
		end loop;
		for i in 3 downto 0 loop
			lo := lo * 2;
			if v(i) = '1' then lo := lo + 1; end if;
		end loop;
		return HEX(hi + 1) & HEX(lo + 1);
	end function;

begin

	stimulus : process
		variable errors : natural := 0;
		variable checks : natural := 0;
		variable got    : std_logic_vector(7 downto 0);

		procedure check(constant name     : in string;
		                constant rev, inv : in boolean;
		                constant expected : in std_logic_vector(7 downto 0)) is
		begin
			got := integer_to_ssd(digit, rev, inv);
			checks := checks + 1;
			if got /= expected then
				errors := errors + 1;
				report "FAIL " & name & " input=" & integer'image(digit) &
				       " expected=" & to_hex(expected) & " got=" & to_hex(got)
				       severity error;
			end if;
		end procedure;

	begin
		-- Decimal digits 0-9 in all four reverse/inverse combinations
		for d in 0 to 9 loop
			digit <= d;
			wait for 1 ns;
			check("normal",          false, false, NORMAL(d));
			check("reverse",         true,  false, REVERSED(d));
			check("inverse",         false, true,  INVERTED(d));
			check("reverse+inverse", true,  true,  REV_INV(d));
		end loop;

		-- Inputs outside 0-9: base pattern FF (dark) before transformation
		for i in INVALID_INPUTS'range loop
			digit <= INVALID_INPUTS(i);
			wait for 1 ns;
			check("invalid normal",          false, false, x"FF");
			check("invalid reverse",         true,  false, x"FF");
			check("invalid inverse",         false, true,  x"00");
			check("invalid reverse+inverse", true,  true,  x"00");
		end loop;

		if errors = 0 then
			report "tb_seven_segment_driver: PASS (" & integer'image(checks) & " checks)";
		else
			report "tb_seven_segment_driver: FAIL (" & integer'image(errors) & " of " &
			       integer'image(checks) & " checks failed)" severity failure;
		end if;
		wait;
	end process;

end architecture;
