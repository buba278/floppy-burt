libray IEEE;
using IEEE.std_logic_1164.all;
using IEEE.numeric_std.all;

-- Scale clock input of 50 MHz to 1 Hz

entity clock_div is
    port(Clk : in std_logic ; Clk_out : out std_logic);
end entity clock_div;

architecture division of clock_div is
    signal counter : unsigned;
begin
    counter <= (counter + 1) when Clk = '1' else
                counter;

    Clk_out <= 1 when counter = 25000000 else
                0 when counter = 50000000 else
                Clk_out;
end architecture division;