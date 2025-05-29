library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fsm_states_pkg.all;

entity pipe_renderer is
    port(
        clk, reset                                      : IN std_logic;
        current_row, current_col                        : IN std_logic_vector(9 downto 0);
        lfsr_value                                      : IN std_logic_vector(9 downto 0);
        game_state                                      : IN state_type;
        new_score                                       : IN integer range 0 to 999; -- new score from the game state
        score_out                                       : OUT std_logic_vector(9 downto 0);
        pipe1_visible, pipe2_visible, pipe3_visible     : OUT std_logic;
        pipe1_x_pos, pipe2_x_pos, pipe3_x_pos           : OUT integer range 0 to 1023; -- right edge of the pipes
        red1, green1, blue1                             : OUT std_logic_vector(3 downto 0);
        red2, green2, blue2                             : OUT std_logic_vector(3 downto 0);
        red3, green3, blue3                             : OUT std_logic_vector(3 downto 0)
    );
end entity pipe_renderer;

architecture behaviour of pipe_renderer is

    constant c_pipe_width         : integer range 0 to 64     := 50;    -- diameter of pipe
    constant c_screen_width       : integer range 0 to 1023   := 640;   -- VGA screen width
    constant c_bird_x_pos         : integer range 0 to 127    := 100;   -- x position of the bird

    signal previous_game_state  : state_type := start_menu;
    signal s_game_start_bool    : std_logic := '0';
    signal score                : std_logic_vector(9 downto 0) := (others => '0');

    -- tracks the right edge of the pipes
    signal s_pipe1_x_pos        : integer := 690 + c_pipe_width;    -- pipes start off screen
    signal s_pipe2_x_pos        : integer := 904 + c_pipe_width;
    signal s_pipe3_x_pos        : integer := 1117 + c_pipe_width;
    signal pipe_velocity        : integer range 0 to 8  := 0;
    
    -- for the gaps in the pipes
    signal gap1_seed, gap2_seed, gap3_seed                          : unsigned(5 downto 0);
    signal gap1_y_pos, gap2_y_pos, gap3_y_pos                       : integer range 0 to 512 := 0;
    signal gap_height                                               : integer range 0 to 128 := 65; -- half of the total gap size

    -- for moving pipes in hard mode
    signal moving_gap1_bool, moving_gap2_bool, moving_gap3_bool     : boolean := false;
    signal gap1_displacement, gap2_displacement, gap3_displacement  : integer range -320 to 320 := 0;
    signal gap1_velocity, gap2_velocity, gap3_velocity              : integer range -4 to 4 := 0;

    -- pipe visibility
    signal s_pipe1_on, s_pipe2_on, s_pipe3_on                       : std_logic_vector(3 downto 0);
    signal s_pipe1_on_bool, s_pipe2_on_bool, s_pipe3_on_bool        : std_logic;

begin

    -- game started when game_state is in practice, easy, medium or hard
    s_game_start_bool <= '1' when (game_state = practice) or (game_state = easy) or (game_state = medium) or (game_state = hard) else '0';

    -- calculate the gaps in the pipes based on the LFSR value
    gap1_y_pos <= 80 + (to_integer(gap1_seed) * 5) + gap1_displacement;
    gap2_y_pos <= 80 + (to_integer(gap2_seed) * 5) + gap2_displacement;
    gap3_y_pos <= 80 + (to_integer(gap3_seed) * 5) + gap3_displacement;

    -- calculate the visibility of the pipes based on the current row and column
    s_pipe1_on_bool <= '1' when (to_integer(unsigned(current_col)) >= (s_pipe1_x_pos - c_pipe_width)) and (to_integer(unsigned(current_col)) <= s_pipe1_x_pos)
                            and ((to_integer(unsigned(current_row)) <= (gap1_y_pos - gap_height)) or (to_integer(unsigned(current_row)) >= (gap1_y_pos + gap_height)))
                            else '0';

    s_pipe2_on_bool <= '1' when (to_integer(unsigned(current_col)) >= (s_pipe2_x_pos - c_pipe_width)) and (to_integer(unsigned(current_col)) <= s_pipe2_x_pos)
                            and ((to_integer(unsigned(current_row)) <= (gap2_y_pos - gap_height)) or (to_integer(unsigned(current_row)) >= (gap2_y_pos + gap_height)))
                            else '0';

    s_pipe3_on_bool <= '1' when (to_integer(unsigned(current_col)) >= (s_pipe3_x_pos - c_pipe_width)) and (to_integer(unsigned(current_col)) <= s_pipe3_x_pos)
                            and ((to_integer(unsigned(current_row)) <= (gap3_y_pos - gap_height)) or (to_integer(unsigned(current_row)) >= (gap3_y_pos + gap_height)))
                            else '0';

    s_pipe1_on <= (others => s_pipe1_on_bool);
    s_pipe2_on <= (others => s_pipe2_on_bool);
    s_pipe3_on <= (others => s_pipe3_on_bool);

    red1 <= not s_pipe1_on; green1 <= s_pipe1_on; blue1 <= not s_pipe1_on;
    red2 <= not s_pipe2_on; green2 <= s_pipe2_on; blue2 <= not s_pipe2_on;
    red3 <= not s_pipe3_on; green3 <= s_pipe3_on; blue3 <= not s_pipe3_on;

    pipe1_visible <= s_pipe1_on_bool;
    pipe2_visible <= s_pipe2_on_bool;
    pipe3_visible <= s_pipe3_on_bool;

    pipe1_x_pos <= s_pipe1_x_pos;
    pipe2_x_pos <= s_pipe2_x_pos;
    pipe3_x_pos <= s_pipe3_x_pos;

    score_out <= score;

    -- pipe velocity based on game state
    with game_state select
    pipe_velocity <= 2 when practice,
                     2 when easy, 
                     3 when medium,
                     4 when hard,
                     0 when others; 

    -- moving pipes across the screen
    process(clk, reset, lfsr_value)

    begin
        -- functionality for resetting the pipes in practice mode
        if (reset = '1') then
                s_pipe1_x_pos <= 690 + c_pipe_width;
                s_pipe2_x_pos <= 904 + c_pipe_width;
                s_pipe3_x_pos <= 1117 + c_pipe_width;

                gap1_seed <= unsigned(lfsr_value(9 downto 4));
                gap2_seed <= unsigned(lfsr_value(7 downto 2));
                gap3_seed <= unsigned(lfsr_value(5 downto 0));

                score <= (others => '0');

        elsif (rising_edge(clk)) then
            if (game_state /= previous_game_state) then 

                previous_game_state <= game_state;

                case game_state is
					when start_menu | practice | easy =>
                        s_pipe1_x_pos <= 690 + c_pipe_width;
                        s_pipe2_x_pos <= 904 + c_pipe_width;
                        s_pipe3_x_pos <= 1117 + c_pipe_width;
        
                        gap1_seed <= unsigned(lfsr_value(9 downto 4));
                        gap2_seed <= unsigned(lfsr_value(7 downto 2));
                        gap3_seed <= unsigned(lfsr_value(5 downto 0));

                        gap1_velocity <= 0;
                        gap2_velocity <= 0;
                        gap3_velocity <= 0;
                        gap1_displacement <= 0;
                        gap2_displacement <= 0;
                        gap3_displacement <= 0;
                        moving_gap1_bool <= false;
                        moving_gap2_bool <= false;
                        moving_gap3_bool <= false;
        
                        score <= (others => '0');
					when others =>
						null;
				end case;

            elsif (s_game_start_bool = '1') then

                -- reset pipe 1 position when it reaches the left side of the screen
                if (s_pipe1_x_pos) <= (pipe_velocity - 1) then
                    s_pipe1_x_pos <= c_screen_width + c_pipe_width;
                    gap1_seed <= unsigned(lfsr_value(9 downto 4));

                    -- if in hard mode, pipe 1 has a chance of moving vertically
                    if (game_state = hard) then
                        gap1_displacement <= 0;
                        moving_gap1_bool <= (unsigned(lfsr_value(9 downto 0)) <= to_unsigned(512, 10)); -- 50% chance of pipe moving vertically for testin
                        if (moving_gap1_bool = true) then
                            if (lfsr_value(0) = '1') then
                                gap1_velocity <= -1; -- move up
                            else
                                gap1_velocity <= 1; -- move down
                            end if;
                        end if;
                    end if;
                else

                    -- pipe 1 horizontal movement
                    s_pipe1_x_pos <= s_pipe1_x_pos - pipe_velocity;

                    -- pipe 1 vertical movement
                    if (moving_gap1_bool = true) then
                        if (((gap1_y_pos <= 80) and (gap1_velocity = -1)) or ((gap1_y_pos >= 400) and (gap1_velocity = 1))) then
                            gap1_velocity <= -gap1_velocity;
                        end if;
                        gap1_displacement <= gap1_displacement + gap1_velocity;
                    end if;
                end if;
                
                -- reset pipe 2 position when it reaches the left side of the screen
                if (s_pipe2_x_pos) <= (pipe_velocity - 1) then
                    s_pipe2_x_pos <= c_screen_width + c_pipe_width;
                    gap2_seed <= unsigned(lfsr_value(9 downto 4));

                    -- if in hard mode, pipe 2 has a chance of moving vertically
                    if (game_state = hard) then
                        gap2_displacement <= 0;
                        moving_gap2_bool <= (unsigned(lfsr_value(9 downto 0)) <= to_unsigned(512, 10)); -- 50% chance of pipe moving vertically for testin
                        if (moving_gap2_bool = true) then
                            if (lfsr_value(0) = '1') then
                                gap2_velocity <= -1; -- move up
                            else
                                gap2_velocity <= 1; -- move down
                            end if;
                        end if;
                    end if;
                else

                    -- pipe 2 horizontal movement
                    s_pipe2_x_pos <= s_pipe2_x_pos - pipe_velocity;

                    -- pipe 2 vertical movement
                    if (moving_gap2_bool = true) then
                        if (((gap2_y_pos <= 80) and (gap2_velocity = -1)) or ((gap2_y_pos >= 400) and (gap2_velocity = 1))) then
                            gap2_velocity <= -gap2_velocity;
                        end if;
                        gap2_displacement <= gap2_displacement + gap2_velocity;
                    end if;
                end if;

                -- reset pipe 3 position when it reaches the left side of the screen
                if (s_pipe3_x_pos) <= (pipe_velocity - 1) then
                    s_pipe3_x_pos <= c_screen_width + c_pipe_width;
                    gap3_seed <= unsigned(lfsr_value(9 downto 4));

                    -- if in hard mode, pipe 1 has a chance of moving vertically
                    if (game_state = hard) then
                        gap3_displacement <= 0;
                        moving_gap3_bool <= (unsigned(lfsr_value(9 downto 0)) <= to_unsigned(512, 10)); -- 50% chance of pipe moving vertically for testin
                        if (moving_gap3_bool = true) then
                            if (lfsr_value(0) = '1') then
                                gap3_velocity <= -1; -- move up
                            else
                                gap3_velocity <= 1; -- move down
                            end if;
                        end if;
                    end if;
                else

                    -- pipe 3 horizontal movement
                    s_pipe3_x_pos <= s_pipe3_x_pos - pipe_velocity;

                    -- pipe 3 vertical movement
                    if (moving_gap3_bool = true) then
                        if (((gap3_y_pos <= 80) and (gap3_velocity = -1)) or ((gap3_y_pos >= 400) and (gap3_velocity = 1))) then
                            gap3_velocity <= -gap3_velocity;
                        end if;
                        gap3_displacement <= gap3_displacement + gap3_velocity;
                    end if;
                end if;

                -- score counting
                if (new_score > to_integer(unsigned(score))) then
                    score <= std_logic_vector(to_unsigned(new_score, 10));
                end if;
                if ((s_pipe1_x_pos <= c_bird_x_pos) and (s_pipe1_x_pos >= (c_bird_x_pos - (pipe_velocity - 1)))) or
                    ((s_pipe2_x_pos <= c_bird_x_pos) and (s_pipe2_x_pos >= (c_bird_x_pos - (pipe_velocity - 1)))) or
                    ((s_pipe3_x_pos <= c_bird_x_pos) and (s_pipe3_x_pos >= (c_bird_x_pos - (pipe_velocity - 1)))) then

                    score <= std_logic_vector(unsigned(score) + 1);
                end if;

            end if;
        end if;
    end process;

end architecture behaviour;