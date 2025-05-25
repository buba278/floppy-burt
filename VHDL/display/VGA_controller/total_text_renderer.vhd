LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE IEEE.STD_LOGIC_ARITH.all;
USE IEEE.STD_LOGIC_UNSIGNED.all;
use work.fsm_states_pkg.all;

entity total_text_renderer is
    port (
        clk                                 : in std_logic;
        current_row, current_col            : in std_logic_vector(9 downto 0);
        game_state                          : in state_type;
        text_visible                        : out std_logic;
        red, green, blue                    : out std_logic_vector(3 downto 0)
    );
end total_text_renderer;

architecture behaviour of total_text_renderer is

    component text_renderer is
        port (
            clk                                 : IN std_logic;
            char_count                          : IN integer;
            char_address                        : IN std_logic_vector(47 downto 0); -- 8 char length max
            current_row, current_col	        : IN std_logic_vector(9 DOWNTO 0);
            text_origin_col, text_origin_row    : IN std_logic_vector(9 DOWNTO 0);
            text_scale                          : IN integer;

            text_visible                        : OUT std_logic;
            red, green, blue                    : OUT std_logic_vector(3 downto 0)
        );
    end component text_renderer;

    signal s_char_count_1        : integer;
    signal s_char_address_1      : std_logic_vector(47 downto 0);
    signal s_text_origin_col_1   : std_logic_vector(9 downto 0);
    signal s_text_origin_row_1   : std_logic_vector(9 downto 0);
    signal s_text_scale_1        : integer;
    signal s_text_visible_1       : std_logic;
    signal s_red_1            : std_logic_vector(3 downto 0);
    signal s_green_1          : std_logic_vector(3 downto 0);
    signal s_blue_1           : std_logic_vector(3 downto 0);

    signal s_char_count_2        : integer;
    signal s_char_address_2      : std_logic_vector(47 downto 0);
    signal s_text_origin_col_2   : std_logic_vector(9 downto 0);
    signal s_text_origin_row_2   : std_logic_vector(9 downto 0);
    signal s_text_scale_2        : integer;
    signal s_text_visible_2       : std_logic;
    signal s_red_2            : std_logic_vector(3 downto 0);
    signal s_green_2          : std_logic_vector(3 downto 0);
    signal s_blue_2           : std_logic_vector(3 downto 0);

    constant char_scorehash : std_logic_vector(47 downto 0) :=
        ("010011" & "000011" & "001111" & "010010" & "000101" & "100000" & "100011") & ("000000");
    constant char_start : std_logic_vector(47 downto 0) :=
        ("010011" & "010100" & "000001" & "010010" & "010100") & ("000000" & "000000" & "000000");  
    constant char_over : std_logic_vector(47 downto 0) :=
        ("000111" & "000001" & "001101" & "000101") & ("001111" & "010110" & "000101" & "010010");
    constant char_easy : std_logic_vector(47 downto 0) :=
        ("000101" & "000001" & "010011" & "011001") & ("000000" & "000000" & "000000" & "000000");
    constant char_hard : std_logic_vector(47 downto 0) :=
        ("001000" & "000001" & "010010" & "000100") & ("000000" & "000000" & "000000" & "000000");
    constant char_practice : std_logic_vector(47 downto 0) :=
        ("010000" & "010010" & "000001" & "000011" & "010100" & "001001" & "000011" & "000101");
    constant char_empty : std_logic_vector(47 downto 0) :=
        ("100000" & "100000" & "100000" & "100000") & ("100000" & "100000" & "100000" & "100000");     

begin

    t1: text_renderer
        port map (
            clk                                 => clk,
            char_count                          => s_char_count_1,
            char_address                        => s_char_address_1,
            current_row                         => current_row,
            current_col                         => current_col,
            text_origin_col                     => s_text_origin_col_1,
            text_origin_row                     => s_text_origin_row_1,
            text_scale                          => s_text_scale_1,

            text_visible                        => s_text_visible_1,
            red                                 => s_red_1,
            green                               => s_green_1,
            blue                                => s_blue_1
        );

    t2: text_renderer
        port map (
            clk                                 => clk,
            char_count                          => s_char_count_2,
            char_address                        => s_char_address_2,
            current_row                         => current_row,
            current_col                         => current_col,
            text_origin_col                     => s_text_origin_col_2,
            text_origin_row                     => s_text_origin_row_2,
            text_scale                          => s_text_scale_2,

            text_visible                        => s_text_visible_2,
            red                                 => s_red_2,
            green                               => s_green_2,
            blue                                => s_blue_2
        );

    text_visible <= s_text_visible_1 or s_text_visible_2;
    red <= s_red_1 or s_red_2;
    green <= s_green_1 or s_green_2;
    blue <= s_blue_1 or s_blue_2;

    process(game_state)
    begin
        case game_state is
            when start =>
                s_char_count_1 <= 5;
                s_char_address_1 <= char_start;
                s_text_origin_col_1 <= CONV_STD_LOGIC_VECTOR(240,10);
                s_text_origin_row_1 <= CONV_STD_LOGIC_VECTOR(224,10);
                s_text_scale_1 <= 4;

                s_char_count_2 <= 8;
                s_char_address_2 <= char_empty;
                s_text_origin_col_2 <= CONV_STD_LOGIC_VECTOR(20,10);
                s_text_origin_row_2 <= CONV_STD_LOGIC_VECTOR(20,10);
                s_text_scale_2 <= 1;                

            when practice =>
                s_char_count_1 <= 8;
                s_char_address_1 <= char_practice;
                s_text_origin_col_1 <= CONV_STD_LOGIC_VECTOR(20,10);
                s_text_origin_row_1 <= CONV_STD_LOGIC_VECTOR(20,10);
                s_text_scale_1 <= 2;

                s_char_count_2 <= 7;
                s_char_address_2 <= char_scorehash;
                s_text_origin_col_2 <= CONV_STD_LOGIC_VECTOR(20,10);
                s_text_origin_row_2 <= CONV_STD_LOGIC_VECTOR(40,10);
                s_text_scale_2 <= 2;
            
            when easy =>
                s_char_count_1 <= 4;
                s_char_address_1 <= char_easy;
                s_text_origin_col_1 <= CONV_STD_LOGIC_VECTOR(20,10);
                s_text_origin_row_1 <= CONV_STD_LOGIC_VECTOR(20,10);
                s_text_scale_1 <= 2;

                s_char_count_2 <= 7;
                s_char_address_2 <= char_scorehash;
                s_text_origin_col_2 <= CONV_STD_LOGIC_VECTOR(20,10);
                s_text_origin_row_2 <= CONV_STD_LOGIC_VECTOR(40,10);
                s_text_scale_2 <= 2;

            when hard =>
                s_char_count_1 <= 4;
                s_char_address_1 <= char_hard;
                s_text_origin_col_1 <= CONV_STD_LOGIC_VECTOR(20,10);
                s_text_origin_row_1 <= CONV_STD_LOGIC_VECTOR(20,10);
                s_text_scale_1 <= 2;

                s_char_count_2 <= 7;
                s_char_address_2 <= char_scorehash;
                s_text_origin_col_2 <= CONV_STD_LOGIC_VECTOR(20,10);
                s_text_origin_row_2 <= CONV_STD_LOGIC_VECTOR(40,10);
                s_text_scale_2 <= 2;

            when game_over =>
                s_char_count_1 <= 8;
                s_char_address_1 <= char_over;
                s_text_origin_col_1 <= CONV_STD_LOGIC_VECTOR(185,10);
                s_text_origin_row_1 <= CONV_STD_LOGIC_VECTOR(224,10);
                s_text_scale_1 <= 4;

                s_char_count_2 <= 7;
                s_char_address_2 <= char_scorehash;
                s_text_origin_col_2 <= CONV_STD_LOGIC_VECTOR(236,10);
                s_text_origin_row_2 <= CONV_STD_LOGIC_VECTOR(260,10);
                s_text_scale_2 <= 3;                

            when others =>
                null;
        end case;
    end process;

end architecture behaviour; 