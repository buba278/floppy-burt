library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- galois lfsr
entity lfsr is
    port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        lfsr_out    : out std_logic_vector(9 downto 0)
    );
end entity;

architecture behaviour of lfsr is
    signal lfsr_reg : std_logic_vector(9 downto 0) := "0000000001"; -- seed value

    begin

    lfsr_out <= lfsr_reg;

    process(clk)
    variable feedback : std_logic;
    begin
        if (rising_edge(clk)) then
            feedback := lfsr_reg(2) xor lfsr_reg(9);
            lfsr_reg <= lfsr_reg(9 downto 1) & feedback; -- shift left and insert feedback
        end if;
    end process;

end architecture;
