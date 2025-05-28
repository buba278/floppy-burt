LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;
USE work.fsm_states_pkg.all;

ENTITY text_renderer IS
	PORT ( 
		clk                                 : IN std_logic;
        -- char_count                          : IN integer;
        -- char_address                        : IN std_logic_vector(47 downto 0); -- 8 char length max
		current_row, current_col	        : IN std_logic_vector(9 DOWNTO 0);
        -- text_origin_col, text_origin_row    : IN std_logic_vector(9 DOWNTO 0);
        -- text_scale                          : IN integer;
        game_state                          : in state_type;
        score                               : in std_logic_vector(9 downto 0);

        text_visible                        : OUT std_logic;
		red, green, blue                    : OUT std_logic_vector(3 downto 0)
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
    signal s_char_address_slice : std_logic_vector(5 downto 0);

    signal s_char_count         : integer range 0 to 8;
    signal s_char_address       : std_logic_vector(47 downto 0);
    signal s_text_origin_col    : std_logic_vector(9 downto 0);
    signal s_text_origin_row    : std_logic_vector(9 downto 0);
    signal s_text_scale         : integer range 0 to 4;

    signal s_score_integer      : integer range 0 to 999;
    signal s_score_hundreds     : std_logic_vector(5 downto 0);
    signal s_score_tens         : std_logic_vector(5 downto 0);
    signal s_score_ones         : std_logic_vector(5 downto 0);

    constant char_scoreblank : std_logic_vector(29 downto 0) :=
        ("010011" & "000011" & "001111" & "010010" & "000101");
    constant char_start : std_logic_vector(47 downto 0) :=
        ("010011" & "010100" & "000001" & "010010" & "010100") & ("000000" & "000000" & "000000");  
    constant char_over : std_logic_vector(47 downto 0) :=
        ("000111" & "000001" & "001101" & "000101") & ("001111" & "010110" & "000101" & "010010");
    constant char_easy : std_logic_vector(47 downto 0) :=
        ("000101" & "000001" & "010011" & "011001") & ("000000" & "000000" & "000000" & "000000");
    constant char_medium : std_logic_vector(47 downto 0) := 
        ("001101" & "000101" & "000100" & "001001" & "010101" & "001101" & "000000" & "000000");
    constant char_hard : std_logic_vector(47 downto 0) :=
        ("001000" & "000001" & "010010" & "000100") & ("000000" & "000000" & "000000" & "000000");
    constant char_practice : std_logic_vector(47 downto 0) :=
        ("010000" & "010010" & "000001" & "000011" & "010100" & "001001" & "000011" & "000101");
    constant char_empty : std_logic_vector(47 downto 0) :=
        ("100000" & "100000" & "100000" & "100000") & ("100000" & "100000" & "100000" & "100000");

begin
    c1: char_rom
        port map (
            character_address   => s_char_address_slice,
            font_row            => s_char_rom_font_row,
            font_col            => s_char_rom_font_col,
            clock               => clk,
            rom_mux_output      => s_char_pixel_on
        );

    s_score_integer <= to_integer(unsigned(score));
    s_score_hundreds <= std_logic_vector(to_unsigned((s_score_integer / 100 + 48), 6));
    s_score_tens <= std_logic_vector(to_unsigned(((s_score_integer / 10) mod 10 + 48), 6));
    s_score_ones <= std_logic_vector(to_unsigned((s_score_integer mod 10 + 48), 6));

    process(game_state)
    begin
        case game_state is
            when start =>
                s_char_count <= 5;
                s_char_address <= char_start;
                s_text_origin_col <= std_logic_vector(to_unsigned(240,10));
                s_text_origin_row <= std_logic_vector(to_unsigned(224,10));
                s_text_scale <= 4;             

            when practice =>
                s_char_count <= 8;
                s_char_address <= char_practice;
                s_text_origin_col <= std_logic_vector(to_unsigned(20,10));
                s_text_origin_row <= std_logic_vector(to_unsigned(20,10));
                s_text_scale <= 2;
            
            when easy =>
                s_char_count <= 4;
                s_char_address <= char_easy;
                s_text_origin_col <= std_logic_vector(to_unsigned(20,10));
                s_text_origin_row <= std_logic_vector(to_unsigned(20,10));
                s_text_scale <= 2;

            when medium =>
                s_char_count <= 6;
                s_char_address <= char_medium;
                s_text_origin_col <= std_logic_vector(to_unsigned(20,10));
                s_text_origin_row <= std_logic_vector(to_unsigned(20,10));
                s_text_scale <= 2;

            when hard =>
                s_char_count <= 4;
                s_char_address <= char_hard;
                s_text_origin_col <= std_logic_vector(to_unsigned(20,10));
                s_text_origin_row <= std_logic_vector(to_unsigned(20,10));
                s_text_scale <= 2;

            when game_over =>
                s_char_count <= 8;
                s_char_address <= char_scoreblank & s_score_hundreds & s_score_tens & s_score_ones;
                s_text_origin_col <= std_logic_vector(to_unsigned(236,10));
                s_text_origin_row <= std_logic_vector(to_unsigned(260,10));
                s_text_scale <= 3;                

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
        if (current_col >= s_text_origin_col) and (current_col < std_logic_vector(unsigned(s_text_origin_col) + to_unsigned(8*s_text_scale*s_char_count,10))) and
           (current_row >= s_text_origin_row) and (current_row < std_logic_vector(unsigned(s_text_origin_row) + to_unsigned(8*s_text_scale,10))) then

            -- get absolute positions of the pixels
            v_rel_col_int := (to_integer(unsigned(current_col) - unsigned(s_text_origin_col)) / s_text_scale);
            v_rel_row_int := (to_integer(unsigned(current_row) - unsigned(s_text_origin_row)) / s_text_scale);

            v_char_index := v_rel_col_int / 8; -- tells you index of char
            s_char_address_slice <= s_char_address( (47 - 6*v_char_index) downto (42 - 6*v_char_index) );

            -- update where on the char we are
            v_font_col_within_char := v_rel_col_int mod 8;
            s_char_rom_font_col <= std_logic_vector(to_unsigned(v_font_col_within_char, 3));

            s_char_rom_font_row <= std_logic_vector(to_unsigned(v_rel_row_int, 3));

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