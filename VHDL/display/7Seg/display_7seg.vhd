library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity display_7seg is
    port (
        clk_25MHz, reset        : in std_logic;
        mode_select             : in std_logic;
        seven_seg_input         : in std_logic_vector(9 downto 0);
        seven_seg_out_0         : out std_logic_vector(6 downto 0);
        seven_seg_out_1         : out std_logic_vector(6 downto 0);
        seven_seg_out_2         : out std_logic_vector(6 downto 0);
        seven_seg_out_3         : out std_logic_vector(6 downto 0);
        seven_seg_out_4         : out std_logic_vector(6 downto 0);
        seven_seg_out_5         : out std_logic_vector(6 downto 0)
    );
end entity display_7seg;

architecture behaviour of display_7seg is

    component bcd_to_sevenseg_char is
        port (
            bcd_digit   : in std_logic_vector(3 downto 0);
            sevenseg_out: out std_logic_vector(6 downto 0)
        );
    end component;

    component bcd_to_sevenseg_digit is
        port (
            bcd_digit   : in std_logic_vector(3 downto 0);
            sevenseg_out: out std_logic_vector(6 downto 0)
        );
    end component;

    signal bcd_value_0       : std_logic_vector(3 downto 0);
    signal bcd_value_1       : std_logic_vector(3 downto 0);
    signal bcd_value_2       : std_logic_vector(3 downto 0);
    signal bcd_value_3       : std_logic_vector(3 downto 0);
    signal bcd_value_4       : std_logic_vector(3 downto 0);
    signal bcd_value_5       : std_logic_vector(3 downto 0);

begin

    -- b0: bcd_to_sevenseg_char
    -- port map (
    --     bcd_digit    => bcd_value_0,
    --     sevenseg_out => seven_seg_out_0
    -- );

    -- b1: bcd_to_sevenseg_char
    -- port map (
    --     bcd_digit    => bcd_value_1,
    --     sevenseg_out => seven_seg_out_1
    -- );

    -- b2: bcd_to_sevenseg_char
    -- port map (
    --     bcd_digit    => bcd_value_2,
    --     sevenseg_out => seven_seg_out_2
    -- );

    -- b3: bcd_to_sevenseg_char
    -- port map (
    --     bcd_digit    => bcd_value_3,
    --     sevenseg_out => seven_seg_out_3
    -- );

    -- b4: bcd_to_sevenseg_char
    -- port map (
    --     bcd_digit    => bcd_value_4,
    --     sevenseg_out => seven_seg_out_4
    -- );

    -- b5: bcd_to_sevenseg_char
    -- port map (
    --     bcd_digit    => bcd_value_5,
    --     sevenseg_out => seven_seg_out_5
    -- );

    -- -- Select the text to display based on mode
    -- process(mode_select, reset)
    -- begin
    --     if (mode_select = '0') then -- Training Mode
    --         bcd_value_0 <= "0100"; -- Display 'n'
    --         bcd_value_1 <= "0010"; -- Display 'i'
    --         bcd_value_2 <= "0001"; -- Display 'A'
    --         bcd_value_3 <= "0110"; -- Display 'r'
    --         bcd_value_4 <= "0111"; -- Display 't'
    --         bcd_value_5 <= "0000"; -- Display ' '
    --     elsif (mode_select = '1') then -- Play Mode
    --         bcd_value_0 <= "1000"; -- Display 'Y'
    --         bcd_value_1 <= "0001"; -- Display 'A'
    --         bcd_value_2 <= "0011"; -- Display 'L'
    --         bcd_value_3 <= "0101"; -- Display 'P'
    --         bcd_value_4 <= "0000"; -- Display ' '
    --         bcd_value_5 <= "0000"; -- Display ' '
    --     end if;
    -- end process;

    -- Convert the input to BCD values
    
    b0: bcd_to_sevenseg_digit
    port map (
        bcd_digit    => bcd_value_0,
        sevenseg_out => seven_seg_out_0
    );

    b1: bcd_to_sevenseg_digit
    port map (
        bcd_digit    => bcd_value_1,
        sevenseg_out => seven_seg_out_1
    );
    b2: bcd_to_sevenseg_digit
    port map (
        bcd_digit    => bcd_value_2,
        sevenseg_out => seven_seg_out_2
    );
    b3: bcd_to_sevenseg_digit
    port map (
        bcd_digit    => bcd_value_3,
        sevenseg_out => seven_seg_out_3
    );
    b4: bcd_to_sevenseg_digit
    port map (
        bcd_digit    => bcd_value_4,
        sevenseg_out => seven_seg_out_4
    );
    b5: bcd_to_sevenseg_digit
    port map (
        bcd_digit    => bcd_value_5,
        sevenseg_out => seven_seg_out_5
    );

    process(clk_25MHz)
    begin 
        if seven_seg_input(2) = '1' then
            bcd_value_0 <= "0000";
        else 
            bcd_value_0 <= "0001";
        end if;

        if seven_seg_input(3) = '1' then
            bcd_value_1 <= "0000";
        else 
            bcd_value_1 <= "0001";
        end if;

        if seven_seg_input(4) = '1' then
            bcd_value_2 <= "0000";
        else 
            bcd_value_2 <= "0001";
        end if;

        if seven_seg_input(5) = '1' then
            bcd_value_3 <= "0000";
        else 
            bcd_value_3 <= "0001";
        end if;

        if seven_seg_input(6) = '1' then
            bcd_value_4 <= "0000";
        else 
            bcd_value_4 <= "0001";
        end if;

        if seven_seg_input(7) = '1' then
            bcd_value_5 <= "0000";
        else 
            bcd_value_5 <= "0001";
        end if;

        end process;

end architecture behaviour;



    
    

