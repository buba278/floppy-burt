LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;
USE work.fsm_states_pkg.all

entity shield_renderer is
    port (
        clk             : IN std_logic;
        vga_vs          : IN std_logic;
        reset           : IN std_logic;
        game_state      : IN state_type;
        lfsr_value      : IN std_logic_vector(9 downto 0);
        current_row     : IN std_logic_vector(9 downto 0);
        current_col     : IN std_logic_vector(9 downto 0);
        pipe1_x_pos     : IN std_logic_vector(11 downto 0);
        bird_visible    : IN std_logic;
        score           : IN std_logic_vector(9 downto 0);        

        shield_visible  : OUT std_logic;
        shield_red      : OUT std_logic_vector(3 downto 0);
        shield_green    : OUT std_logic_vector(3 downto 0);
        shield_blue     : OUT std_logic_vector(3 downto 0)
    );
end entity shield_renderer;

architecture behaviour of shield_renderer is

    constant shield_size    : unsigned(9 downto 0) := to_unsigned(7, 10); -- size of the shield in pixels

    signal s_shield_on_bool : std_logic := '0';
    signal s_shield_x_pos   : unsigned(9 downto 0);
    signal s_shield_y_pos   : unsigned(9 downto 0);

    signal s_shield_on : std_logic_vector(3 downto 0);

    signal s_game_start_bool : std_logic := '0';

begin

    s_shield_on_bool <= '1' when ((s_shield_x_pos - shield_size <= unsigned(current_col)) and (unsigned(current_col) <= s_shield_x_pos + shield_size) 	-- x_pos - s_size <= current_col <= x_pos + s_size
						and (s_shield_y_pos - shield_size <= unsigned(current_row)) and (unsigned(current_row) <= s_shield_y_pos + shield_size))  else	-- y_pos - s_size <= current_row <= y_pos + s_size
				'0';
    
    shield_visible <= s_shield_on_bool; 

    s_game_start_bool <= '1' when (game_state = easy) or (game_state = medium) or (game_state = hard) else '0';
    
    s_shield_on <= (others => s_shield_on_bool);

    shield_red <= not s_shield_on;
    shield_green <= not s_shield_on;
    shield_blue <= s_shield_on;

    process(vga_vs, reset)
    begin
        if (rising_edge(vga_vs)) then

        end if;
    end process;
    
end architecture behaviour;