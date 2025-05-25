library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.fsm_states_pkg.all;

entity display_7seg is
    port (
        clk, reset              : in std_logic;
        game_state              : in state_type;
        score_input             : in std_logic_vector(9 downto 0);
        seven_seg_out_0         : out std_logic_vector(6 downto 0);
        seven_seg_out_1         : out std_logic_vector(6 downto 0);
        seven_seg_out_2         : out std_logic_vector(6 downto 0);
        seven_seg_out_3         : out std_logic_vector(6 downto 0);
        seven_seg_out_4         : out std_logic_vector(6 downto 0);
        seven_seg_out_5         : out std_logic_vector(6 downto 0)
    );
end entity display_7seg;

architecture behaviour of display_7seg is

    component bcd_to_sevenseg_digit is
        port (
            bcd_digit   : in std_logic_vector(3 downto 0);
            sevenseg_out: out std_logic_vector(6 downto 0)
        );
    end component;

    component bcd_to_sevenseg_char is
        port (
            bcd_digit   : in std_logic_vector(3 downto 0);
            sevenseg_out: out std_logic_vector(6 downto 0)
        );
    end component;

    signal bcd_value_0       : std_logic_vector(3 downto 0) := "0000";
    signal bcd_value_1       : std_logic_vector(3 downto 0) := "0000";
    signal bcd_value_2       : std_logic_vector(3 downto 0) := "0000";
    signal bcd_value_3       : std_logic_vector(3 downto 0);
    signal bcd_value_4       : std_logic_vector(3 downto 0);
    signal bcd_value_5       : std_logic_vector(3 downto 0);

begin

    -- Display 'SC' as the first two characters

    b5: bcd_to_sevenseg_char
    port map (
        bcd_digit    => bcd_value_5,
        sevenseg_out => seven_seg_out_5
    );

    b4: bcd_to_sevenseg_char
    port map (
        bcd_digit    => bcd_value_4,
        sevenseg_out => seven_seg_out_4
    );

    b3: bcd_to_sevenseg_char
    port map (
        bcd_digit    => bcd_value_3,
        sevenseg_out => seven_seg_out_3
    );

    bcd_value_5 <= "1000"; -- S
    bcd_value_4 <= "0010"; -- C
    bcd_value_3 <= "1111"; -- nothing

    -- Convert the score to BCD values

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

    process(clk)
    begin 
        if (rising_edge(clk)) then
            bcd_value_0 <= std_logic_vector(resize((unsigned(score_input) mod 10), 4));        
            bcd_value_1 <= std_logic_vector(resize((unsigned(score_input) / 10) mod 10, 4));          
            bcd_value_2 <= std_logic_vector(resize((unsigned(score_input) / 100) mod 10, 4));   
        end if;
    end process;

end architecture behaviour;
