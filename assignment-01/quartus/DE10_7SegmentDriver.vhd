 ------- ESE DSDL practicum
 ------- Altera DE10-Lite
 ------- ir drs E.J Boks, HAN Embedded Systems Engineering. https://ese.han.nl
-------- $Id$ 
 ------- Voltooi alle code hier onder / Complete all code below
 
-- 7 segment decoder  
-- input: 4-bit number 0 to F  
-- output: 7 led segments  
 
LIBRARY ieee; 
use ieee.std_logic_1164.all; 

package SevenSegmentDriver is
	
	-- Input : This is the number that must be converted to std_logic.
	-- doReverse : Do you want the output in normal (Little Endian)  or in reversed order (Big Endian)?	
	-- doInverse : toon de segmenten op bitnivo geinverteerd / show the segments bitwise inverted
	function integer_to_ssd(signal input : integer;
							doReverse : boolean;
							doInverse : boolean) return std_logic_vector;

	function reverseVector(a: in std_logic_vector) return std_logic_vector;
	
end SevenSegmentDriver;
 
 
package body SevenSegmentDriver is
 

 function integer_to_ssd(signal input : integer;
 						 doReverse : boolean;
  						 doInverse : boolean) return std_logic_vector
	is variable output: std_logic_vector(7 downto 0);
	
begin
	-- Segment ordering: output(0) = a, output(1) = b, ... output(6) = g,
	-- output(7) = decimal point. The DE10-Lite displays are active-low:
	-- a '0' lights the segment, a '1' turns it off.
	--
	--      a
	--     ---
	--  f |   | b
	--     -g-
	--  e |   | c
	--     ---  . dp
	--      d
	case input is
		when 0      => output := "11000000"; -- C0 : a b c d e f
		when 1      => output := "11111001"; -- F9 : b c
		when 2      => output := "10100100"; -- A4 : a b d e g
		when 3      => output := "10110000"; -- B0 : a b c d g
		when 4      => output := "10011001"; -- 99 : b c f g
		when 5      => output := "10010010"; -- 92 : a c d f g
		when 6      => output := "10000010"; -- 82 : a c d e f g
		when 7      => output := "11111000"; -- F8 : a b c
		when 8      => output := "10000000"; -- 80 : a b c d e f g
		when 9      => output := "10010000"; -- 90 : a b c d f g
		when others => output := "11111111"; -- FF : not a decimal digit, display dark
	end case;
	
	-- Reverse the bit order of all 8 bits (decimal point included).
	if doReverse then
		output := reverseVector(output);
	end if;
	
	-- Invert all 8 bits (decimal point included).
	if doInverse then
		output := not output;
	end if;
	
	return output;
end integer_to_ssd;


	function reverseVector(a: in std_logic_vector)
		return std_logic_vector is
	variable result: std_logic_vector(a'RANGE);
	alias aa: std_logic_vector(a'REVERSE_RANGE) is a;
begin
  for i in aa'RANGE loop
    result(i) := aa(i);
  end loop;
  return result;
end function; -- function reverse_any_vector


																							  
end SevenSegmentDriver;

-----------------------------------------

 
  

