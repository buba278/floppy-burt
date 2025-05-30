-- VHDL code for BCD to 7-Segment conversion for letters
-- LED is active low
library IEEE;
use IEEE.std_logic_1164.all;   

entity bcd_to_sevenseg_char is
     port (bcd_digit 	: in std_logic_vector(3 downto 0);
           sevenseg_out : out std_logic_vector(6 downto 0)
	);
end entity;

architecture arc1 of bcd_to_sevenseg_char  is
begin
     sevenseg_out   <=  "0001000"  when bcd_digit = "0001"  else		-- a
	 					"1000110"  when bcd_digit = "0010"  else		-- c
						"1111010"  when bcd_digit = "0011"  else		-- i
						"1000111"  when bcd_digit = "0100"  else 		-- l
						"0101011"  when bcd_digit = "0101"  else		-- n
						"0001100"  when bcd_digit = "0110"  else		-- p
						"0101111"  when bcd_digit = "0111"  else		-- r
						"0010010"  when bcd_digit = "1000"  else		-- s
						"0000111"  when bcd_digit = "1001"  else		-- t
						"0010001"  when bcd_digit = "1010"  else		-- y
						"1111111";
end architecture arc1; 
