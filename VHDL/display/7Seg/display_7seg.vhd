library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity display_7seg is
    port (
        clk_25MHz, reset    : in std_logic;
        mouse_cursor_row    : in std_logic_vector(9 downto 0);
        mouse_cursor_column : in std_logic_vector(9 downto 0);
        mouse_dir_toggle    : in std_logic;
        seven_seg_out       : out std_logic_vector(6 downto 0)
    );
end entity display_7seg;

architecture behaviour of display_7seg is

    component BCD_to_SevenSeg is
        port (
            BCD_digit   : in std_logic_vector(3 downto 0);
            SevenSeg_out: out std_logic_vector(6 downto 0)
        );
    end component;

    signal selected_value   : std_logic_vector(9 downto 0);
    signal integer_value    : integer range 0 to 1023;
    signal bcd_value        : std_logic_vector(3 downto 0);
    
begin

    b1: BCD_to_SevenSeg
    port map (
        BCD_digit    => bcd_value,
        SevenSeg_out => seven_seg_out
    );

    -- Select the value based on mouse direction toggle
    selected_value <= mouse_cursor_row when mouse_dir_toggle = '1' else
                    mouse_cursor_column;

    integer_value <= to_integer(unsigned(selected_value));
    bcd_value <= std_logic_vector(to_unsigned(integer_value, 4));

end architecture behaviour;



    
    

