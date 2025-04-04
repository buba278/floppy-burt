library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity bcd_counter is
    port(Clk, Reset, Enable, Direction : in std_logic;
    Q_Out : out std_logic_vector(3 downto 0));
end entity bcd_counter;

architecture behaviour of bcd_counter is
    signal t_Q : std_logic_vector(3 downto 0);
    signal counter : unsigned(3 downto 0) := "0000";
begin

    counter <= "0000" when Reset = '1' and Direction = '1' else
               "1001" when Reset = '1' and Direction = '0' else
               "0000" when counter = "1001" and rising_edge(Clk) and Enable = '1' and Direction = '1' else
               "1001" when counter = "0000" and rising_edge(Clk) and Enable = '1' and Direction = '0' else
               counter + 1 when rising_edge(Clk) and Enable = '1' and Direction = '1' else
               counter - 1 when rising_edge(Clk) and Enable = '1' and Direction = '0' else
               counter;

    t_Q <= std_logic_vector(counter);
    Q_Out <= t_Q;

end architecture behaviour;