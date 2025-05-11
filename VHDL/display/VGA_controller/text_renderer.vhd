LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE IEEE.STD_LOGIC_ARITH.all;
USE IEEE.STD_LOGIC_UNSIGNED.all;

ENTITY text_renderer IS
	PORT ( 
		clk : IN std_logic;
        char_address                : IN std_logic_vector(5 downto 0);
		current_row, current_col	: IN std_logic_vector(9 DOWNTO 0);
        text_origin_col, text_origin_row : IN std_logic_vector(9 DOWNTO 0);
        text_visible : OUT std_logic;
		red, green, blue : OUT std_logic_vector(3 downto 0)
	);		
END text_renderer;

architecture behavior of text_renderer is

	component char_rom IS
	PORT
	(
		character_address	:	IN STD_LOGIC_VECTOR (5 DOWNTO 0);
		font_row, font_col	:	IN STD_LOGIC_VECTOR (2 DOWNTO 0);

		clock				: 	IN STD_LOGIC ;
		rom_mux_output		:	OUT STD_LOGIC
	);
    END component char_rom;

    -- INTERMEDIARY SIGNALS
    signal s_char_rom_font_row  : std_logic_vector(2 downto 0);
    signal s_char_rom_font_col  : std_logic_vector(2 downto 0);
    signal s_char_pixel_on      : std_logic;

begin

    c1: char_rom
        port map (
            character_address   => char_address,
            font_row            => s_char_rom_font_row,
            font_col            => s_char_rom_font_col,
            clock               => clk,
            rom_mux_output      => s_char_pixel_on
        );

    process (current_row, current_col, s_char_pixel_on)
        variable rel_row_int : integer;
        variable rel_col_int : integer;
    begin
        text_visible <= '0';
        red <= (others => '0');
        green <= (others => '0');
        blue <= (others => '0');
        s_char_rom_font_row <= (others => '0');
        s_char_rom_font_col <= (others => '0');

        if (current_col >= text_origin_col) and (current_col < text_origin_col + 8) and
           (current_row >= text_origin_row) and (current_row < text_origin_row + 8) then

            -- get absolute positions of the pixels
            rel_col_int := conv_integer(current_col - text_origin_col);
            rel_row_int := conv_integer(current_row - text_origin_row);

            -- update where on the char we are
            s_char_rom_font_col <= conv_std_logic_vector(rel_col_int, 3);
            s_char_rom_font_row <= conv_std_logic_vector(rel_row_int, 3);

            -- char_rom spits out on
            if s_char_pixel_on = '1' then
                text_visible <= '1';
                red <= "1111";
                green <= "1111";
                blue <= "1111";
            end if;
        end if;
    end process;

end architecture behavior;