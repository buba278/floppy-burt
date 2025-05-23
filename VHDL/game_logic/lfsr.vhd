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
    signal lfsr_reg : std_logic_vector(9 downto 0) := "1110000001"; -- seed value
    signal feedback : std_logic;
    signal counter  : integer := 0;

    begin

    lfsr_out <= lfsr_reg;

    process(clk)
    -- to implement reset
    begin

        -- taps at 2 and 9
        if (rising_edge(clk)) then

            if counter = 1023 then
                counter <= 0;
                lfsr_reg <= "1110000001"; -- reset to seed value
            else
                counter <= counter + 1;
            end if;

            feedback <= lfsr_reg(9);

            lfsr_reg(9) <= lfsr_reg(8);
            lfsr_reg(8) <= lfsr_reg(7);
            lfsr_reg(7) <= lfsr_reg(6);
            lfsr_reg(6) <= lfsr_reg(5);
            lfsr_reg(5) <= lfsr_reg(4);
            lfsr_reg(4) <= lfsr_reg(3);
            lfsr_reg(3) <= lfsr_reg(2) xor feedback;
            lfsr_reg(2) <= lfsr_reg(1);
            lfsr_reg(1) <= lfsr_reg(0);
            lfsr_reg(0) <= feedback; 

        end if;
    end process;

end architecture;