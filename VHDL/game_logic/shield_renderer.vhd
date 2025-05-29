LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;
USE work.fsm_states_pkg.all;

entity shield_renderer is
    port (
        clk, reset                              : IN std_logic;
        vga_vs                                  : IN std_logic;
        game_state                              : IN state_type;
        lfsr_value                              : IN std_logic_vector(9 downto 0);
        current_row, current_col                : IN std_logic_vector(9 downto 0);
        pipe1_x_pos, pipe2_x_pos, pipe3_x_pos   : IN integer;
        bird_visible                            : IN std_logic;
        score                                   : IN std_logic_vector(9 downto 0);        
        shield_visible                          : OUT std_logic;
        shield_red, shield_green, shield_blue   : OUT std_logic_vector(3 downto 0);
        new_score                               : OUT integer range 0 to 999
    );
end entity shield_renderer;

architecture behaviour of shield_renderer is

    constant c_shield_width     : integer range 0 to 30 := 30;      -- size of the shield in pixels
    constant c_shield_height    : integer range 0 to 30 := 15;      -- size of the shield in pixels
    constant c_screen_width     : integer range 0 to 1023 := 640;   -- VGA screen width

    signal s_shield_x_pos       : integer range -8 to 1023; -- right edge of shield
    signal s_shield_y_pos       : integer range 0 to 500;

    signal s_previous_game_state    : state_type := start_menu;
    signal s_game_start_bool        : std_logic := '0';

    signal s_previous_score         : std_logic_vector(9 downto 0) := (others => '0');

    signal s_shield_icon_active     : std_logic := '0'; -- is the shield icon active on screen
    signal s_shield_ability_active  : std_logic := '0'; -- is the shield ability activated by player
    signal s_shield_placed          : std_logic := '0'; -- signal to indicate if shield has been placed

    signal s_most_right_pipe_x_pos : integer range 0 to 1023 := 0;

    signal s_seed : unsigned(5 downto 0);

    signal s_shield_velocity : integer range 0 to 4 := 0;

    signal s_new_score : integer range 0 to 999 := 0;

    signal s_shield_collision   : std_logic := '0';

    -- shield visibility
    signal s_shield_on          : std_logic_vector(3 downto 0);
    signal s_shield_on_bool     : std_logic := '0';

begin

    s_shield_on_bool <= '1' when (((to_integer(unsigned(current_col)) >= (s_shield_x_pos - c_shield_width))
                            and (to_integer(unsigned(current_col)) <= s_shield_x_pos)
						    and (to_integer(unsigned(current_row)) >= s_shield_y_pos - c_shield_height) 
                            and (to_integer(unsigned(current_row)) <= s_shield_y_pos + c_shield_height))) 
                            and (s_shield_icon_active = '1')
                            else '0';
    
    s_game_start_bool <= '1' when (game_state = easy) or (game_state = medium) or (game_state = hard) else '0';
    
    s_shield_on <= (others => s_shield_on_bool);

    shield_red      <= not s_shield_on;
    shield_green    <= not s_shield_on;
    shield_blue     <= s_shield_on;

    shield_visible <= s_shield_on_bool; 

    new_score <= s_new_score;

    -- shield velocity based on game state
    with game_state select
    s_shield_velocity <= 2 when easy, 
                         3 when medium,
                         4 when hard,
                         0 when others;                     

    -- process to find the most right pipe
    process(pipe1_x_pos, pipe2_x_pos, pipe3_x_pos)
        variable max_val : integer;
    begin
        max_val := pipe1_x_pos;
        if pipe2_x_pos > max_val then
            max_val := pipe2_x_pos;
        end if;
        if pipe3_x_pos > max_val then
            max_val := pipe3_x_pos;
        end if;
        s_most_right_pipe_x_pos <= max_val;
    end process;

    process(clk)
    begin
        if (rising_edge(clk)) then
            if(s_shield_on_bool = '1' and bird_visible = '1') then
                s_shield_collision <= '1'; -- collision detected when shield is on and bird is visible
            elsif (s_shield_ability_active = '1') then
                s_shield_collision <= '0'; -- no collision
            end if;
        end if;
    end process;

    process(vga_vs, reset)
    begin
        if (reset = '1') then
            s_shield_icon_active <= '0';
            s_shield_ability_active <= '0';
            s_previous_score <= (others => '0');
            s_new_score <= 0;
            s_shield_placed <= '0';
        elsif (rising_edge(vga_vs)) then
            if (game_state /= s_previous_game_state) then 

                s_previous_game_state <= game_state;

                if game_state = start_menu then

                    s_shield_icon_active <= '0';
                    s_shield_ability_active <= '0';
                    s_previous_score <= (others => '0');
                    s_new_score <= 0;
                    s_shield_placed <= '0';

				end if;

            elsif (s_game_start_bool = '1') then
                
                s_previous_score <= score;

                -- Detect score milestone
                -- if game_start_bool is 1, score greater than 0, score mod 10 is 0 and previous score mod 10 is not 0
                if ((unsigned(score) > 0) and (unsigned(score) mod 7 = 0) and (unsigned(s_previous_score) mod 7 /= 0) and s_shield_icon_active = '0') then
                    s_shield_icon_active <= '1';
                end if;

                -- Movement and collision of shield
                if (s_shield_icon_active = '1') then

                    if (s_shield_placed = '0') then
                        s_shield_x_pos <= s_most_right_pipe_x_pos + 107; -- place shield 50 pixels to the right of the most right pipe
                        s_shield_y_pos <= 80 + (to_integer(unsigned(lfsr_value(5 downto 0))) * 5); -- place shield below the current row
                        s_shield_placed <= '1'; 
                    elsif (s_shield_placed = '1') then
                        -- Shield has been placed, so we move it to the left
                        s_shield_x_pos <= s_shield_x_pos - s_shield_velocity;
                    end if;

                    -- Check if shield is out of screen
                    if (s_shield_x_pos <= 0) then
                        s_shield_icon_active <= '0';
                        s_shield_placed <= '0';
                        s_shield_x_pos <= 680;
                        s_shield_y_pos <= 240;
                    end if;

                    -- Check collision with bird
                    if (s_shield_collision = '1') then
                        s_shield_icon_active <= '0';
                        s_shield_ability_active <= '1';
                        s_shield_placed <= '0';
                        s_shield_x_pos <= 680;
                        s_shield_y_pos <= 240;
                        s_new_score <= to_integer(unsigned(score)) + 5;
                    end if;
                end if;
                
            end if;
        end if;
    end process;
    
end architecture behaviour;