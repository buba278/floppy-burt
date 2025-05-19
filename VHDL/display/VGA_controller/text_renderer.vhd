LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE IEEE.STD_LOGIC_ARITH.all;
USE IEEE.STD_LOGIC_UNSIGNED.all;
use work.fsm_states_pkg.all;

ENTITY text_renderer IS
	PORT ( 
		clk                                 : IN std_logic;
		current_row, current_col	        : IN std_logic_vector(9 DOWNTO 0);
        game_state                          : IN state_type;
        text_visible                        : OUT std_logic;
		red, green, blue                    : OUT std_logic_vector(3 downto 0)
	);		
END text_renderer;

architecture behaviour of text_renderer is

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
    signal s_char_address_slice : std_logic_vector(5 downto 0);

    signal s_char_count        : integer;
    signal s_char_address      : std_logic_vector(47 downto 0);
    signal s_text_origin_col   : std_logic_vector(9 downto 0);
    signal s_text_origin_row   : std_logic_vector(9 downto 0);
    signal s_text_scale        : integer;

    constant char_scorehash : std_logic_vector(47 downto 0) :=
        ("010011" & "000011" & "001111" & "010010" & "000101" & "100000" & "100011") & ("000000");
    constant char_hello : std_logic_vector(47 downto 0) :=
        ("001000" & "000101" & "001100" & "001100" & "001111") & ("000000" & "000000" & "000000"); 
    constant char_start : std_logic_vector(47 downto 0) :=
        ("010011" & "010100" & "000001" & "010010" & "010100") & ("000000" & "000000" & "000000");  
    constant char_over : std_logic_vector(47 downto 0) :=
        ("001111" & "010101" & "000101" & "010010") & ("000000" & "000000" & "000000" & "000000"); 

begin

    c1: char_rom
        port map (
            character_address   => s_char_address_slice,
            font_row            => s_char_rom_font_row,
            font_col            => s_char_rom_font_col,
            clock               => clk,
            rom_mux_output      => s_char_pixel_on
        );
    
    process(game_state)
    begin
        case game_state is
            when start =>
                s_char_count <= 5;
                s_char_address <= char_start;
                s_text_origin_col <= CONV_STD_LOGIC_VECTOR(320,10);
                s_text_origin_row <= CONV_STD_LOGIC_VECTOR(240,10);
                s_text_scale <= 4;

            when practice | easy | hard =>
                s_char_count <= 7;
                s_char_address <= char_scorehash;
                s_text_origin_col <= CONV_STD_LOGIC_VECTOR(20,10);
                s_text_origin_row <= CONV_STD_LOGIC_VECTOR(20,10);
                s_text_scale <= 1;

            when game_over =>
                s_char_count <= 4;
                s_char_address <= char_over;
                s_text_origin_col <= CONV_STD_LOGIC_VECTOR(320,10);
                s_text_origin_row <= CONV_STD_LOGIC_VECTOR(240,10);
                s_text_scale <= 4;

            when others =>
                null;
        end case;
    end process;

    process (current_row, current_col, s_char_pixel_on, s_char_address_slice)
        variable v_rel_row_int : integer;
        variable v_rel_col_int : integer;

        variable v_char_index : integer;
        variable v_font_col_within_char : integer;
    begin
        text_visible <= '0';
        red <= (others => '0');
        green <= (others => '0');
        blue <= (others => '0');
        s_char_rom_font_row <= (others => '0');
        s_char_rom_font_col <= (others => '0');

        -- scaling of range
        if (current_col >= s_text_origin_col) and (current_col < s_text_origin_col + (8*s_text_scale*s_char_count)) and
           (current_row >= s_text_origin_row) and (current_row < s_text_origin_row + (8*s_text_scale)) then

            -- get absolute positions of the pixels
            v_rel_col_int := (conv_integer(current_col - s_text_origin_col) / s_text_scale);
            v_rel_row_int := (conv_integer(current_row - s_text_origin_row) / s_text_scale);

            v_char_index := v_rel_col_int / 8; -- tells you index of char
            s_char_address_slice <= s_char_address( (47 - 6*v_char_index) downto (42 - 6*v_char_index) );

            -- update where on the char we are
            v_font_col_within_char := v_rel_col_int mod 8;
            s_char_rom_font_col <= conv_std_logic_vector(v_font_col_within_char, 3);

            s_char_rom_font_row <= conv_std_logic_vector(v_rel_row_int, 3);

            -- char_rom spits out on
            if s_char_pixel_on = '1' then
                text_visible <= '1';
                red <= "1111";
                green <= "1111";
                blue <= "1111";
            end if;
        end if;
    end process;

end architecture behaviour;