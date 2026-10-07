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
	
-- Verwijder deze assert bij bewerking code / Remove this message when editing the code.
assert false
report "Beste student, Dit deel van de hardware ontbreekt/This part of thehardware is missing."ù
severity failure;

begin
 
-- Verwijder deze assert bij bewerking code / Remove this message when editing the code.
assert false
report "Beste student, Dit deel van de hardware ontbreekt/This part of thehardware is missing."
severity failure;
	
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

 
  

