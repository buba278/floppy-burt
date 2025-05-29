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
        score_out                                       : OUT std_logic_vector(9 downto 0);
        pipe1_visible, pipe2_visible, pipe3_visible     : OUT std_logic;
        red1, green1, blue1                             : OUT std_logic_vector(3 downto 0);
        red2, green2, blue2                             : OUT std_logic_vector(3 downto 0);
        red3, green3, blue3                             : OUT std_logic_vector(3 downto 0)
    );
end entity pipe_renderer;

architecture behaviour of pipe_renderer is

    constant pipe_width         : integer range 0 to 64     := 50;    -- diameter of pipe
    constant screen_width       : integer range 0 to 1023   := 640;
    constant bird_x_pos         : integer range 0 to 127    := 100;   -- x position of the bird

    signal s_previous_game_state    : state_type := start_menu;
    signal s_score                  : std_logic_vector(9 downto 0) := (others => '0');
    signal s_game_start_bool        : std_logic := '0';

    -- tracks the right edge of the pipes
    signal s_pipe1_x_pos          : integer := 690 + pipe_width; -- pipes start off screen
    signal s_pipe2_x_pos          : integer := 904 + pipe_width;
    signal s_pipe3_x_pos          : integer := 1117 + pipe_width;
    signal s_pipe_velocity        : integer range 0 to 8  := 0;
    
    signal s_gap1_seed, s_gap2_seed, s_gap3_seed                          : unsigned(5 downto 0);
    signal s_gap1_y_pos, s_gap2_y_pos, s_gap3_y_pos                       : integer range 0 to 480 := 0;
    signal s_gap1_y_pos_calc, s_gap2_y_pos_calc, s_gap3_y_pos_calc        : integer;
    signal s_moving_gap1_bool, s_moving_gap2_bool, s_moving_gap3_bool     : boolean := false;
    signal s_gap1_displacement, s_gap2_displacement, s_gap3_displacement  : integer range -320 to 320 := 0;
    signal s_gap1_velocity, s_gap2_velocity, s_gap3_velocity              : integer range -4 to 4 := 0;
    signal s_gap_height                                                   : integer range 0 to 128 := 65; -- half of the total gap size

    signal s_pipe1_on, s_pipe2_on, s_pipe3_on                       : std_logic_vector(3 downto 0);
    signal s_pipe1_on_bool, s_pipe2_on_bool, s_pipe3_on_bool        : std_logic;

begin

    -- game started when game_state is in practice, easy, medium or hard
    s_game_start_bool <= '1' when (game_state = practice) or (game_state = easy) or (game_state = medium) or (game_state = hard) else '0';

    -- Calculate desired gap positions without range constraint first
    s_gap1_y_pos_calc <= 80 + (to_integer(s_gap1_seed) * 5) + s_gap1_displacement;
    s_gap2_y_pos_calc <= 80 + (to_integer(s_gap2_seed) * 5) + s_gap2_displacement;
    s_gap3_y_pos_calc <= 80 + (to_integer(s_gap3_seed) * 5) + s_gap3_displacement;

    -- Clamp the calculated values before assigning to the ranged signals
    s_gap1_y_pos <= 0 when s_gap1_y_pos_calc < 0 else
                    480 when s_gap1_y_pos_calc > 480 else
                    s_gap1_y_pos_calc;

    s_gap2_y_pos <= 0 when s_gap2_y_pos_calc < 0 else
                    480 when s_gap2_y_pos_calc > 480 else
                    s_gap2_y_pos_calc;

    s_gap3_y_pos <= 0 when s_gap3_y_pos_calc < 0 else
                    480 when s_gap3_y_pos_calc > 480 else
                    s_gap3_y_pos_calc;

    s_pipe1_on_bool <= '1' when (to_integer(unsigned(current_col)) >= (s_pipe1_x_pos - pipe_width)) and (to_integer(unsigned(current_col)) <= s_pipe1_x_pos)
                            and ((to_integer(unsigned(current_row)) <= (s_gap1_y_pos - s_gap_height)) or (to_integer(unsigned(current_row)) >= (s_gap1_y_pos + s_gap_height)))
                            else '0';

    s_pipe2_on_bool <= '1' when (to_integer(unsigned(current_col)) >= (s_pipe2_x_pos - pipe_width)) and (to_integer(unsigned(current_col)) <= s_pipe2_x_pos)
                            and ((to_integer(unsigned(current_row)) <= (s_gap2_y_pos - s_gap_height)) or (to_integer(unsigned(current_row)) >= (s_gap2_y_pos + s_gap_height)))
                            else '0';

    s_pipe3_on_bool <= '1' when (to_integer(unsigned(current_col)) >= (s_pipe3_x_pos - pipe_width)) and (to_integer(unsigned(current_col)) <= s_pipe3_x_pos)
                            and ((to_integer(unsigned(current_row)) <= (s_gap3_y_pos - s_gap_height)) or (to_integer(unsigned(current_row)) >= (s_gap3_y_pos + s_gap_height)))
                            else '0';

    s_pipe1_on <= (others => s_pipe1_on_bool);
    s_pipe2_on <= (others => s_pipe2_on_bool);
    s_pipe3_on <= (others => s_pipe3_on_bool);

    -- red1 <= s_pipe1_on; green1 <= s_pipe1_on; blue1 <= s_pipe1_on;
    -- red2 <= s_pipe2_on; green2 <= s_pipe2_on; blue2 <= s_pipe2_on;
    -- red3 <= s_pipe3_on; green3 <= s_pipe3_on; blue3 <= s_pipe3_on;

    -- pipe 1 color
    red1   <= "0100" when s_pipe1_on_bool = '1' else (others => '0');
    green1 <= "1100" when s_pipe1_on_bool = '1' else (others => '0');
    blue1  <= "1111" when s_pipe1_on_bool = '1' else (others => '0');

    -- pipe 2 color
    red2   <= "0100" when s_pipe2_on_bool = '1' else (others => '0');
    green2 <= "1100" when s_pipe2_on_bool = '1' else (others => '0');
    blue2  <= "1111" when s_pipe2_on_bool = '1' else (others => '0');

    -- pipe 3 color
    red3   <= "0100" when s_pipe3_on_bool = '1' else (others => '0');
    green3 <= "1100" when s_pipe3_on_bool = '1' else (others => '0');
    blue3  <= "1111" when s_pipe3_on_bool = '1' else (others => '0');

    pipe1_visible <= s_pipe1_on_bool;
    pipe2_visible <= s_pipe2_on_bool;
    pipe3_visible <= s_pipe3_on_bool;

    score_out <= s_score;

    with game_state select
    s_pipe_velocity <= 2 when practice,
                     2 when easy, 
                     4 when medium,
                     4 when hard,
                     0 when others; 

    -- moving pipes across the screen
    process(clk, reset, lfsr_value)

    begin
        -- functionality for resetting the pipes in practice mode
        if (reset = '1') then
                s_pipe1_x_pos <= 690 + pipe_width;
                s_pipe2_x_pos <= 904 + pipe_width;
                s_pipe3_x_pos <= 1117 + pipe_width;

                s_gap1_seed <= unsigned(lfsr_value(9 downto 4));
                s_gap2_seed <= unsigned(lfsr_value(7 downto 2));
                s_gap3_seed <= unsigned(lfsr_value(5 downto 0));

                s_score <= (others => '0');

        elsif (rising_edge(clk)) then
            if (game_state /= s_previous_game_state) then 

                s_previous_game_state <= game_state;

                case game_state is
					when start_menu | practice | easy =>
                        s_pipe1_x_pos <= 690 + pipe_width;
                        s_pipe2_x_pos <= 904 + pipe_width;
                        s_pipe3_x_pos <= 1117 + pipe_width;
        
                        s_gap1_seed <= unsigned(lfsr_value(9 downto 4));
                        s_gap2_seed <= unsigned(lfsr_value(7 downto 2));
                        s_gap3_seed <= unsigned(lfsr_value(5 downto 0));

                        s_gap1_velocity <= 0;
                        s_gap2_velocity <= 0;
                        s_gap3_velocity <= 0;
                        s_gap1_displacement <= 0;
                        s_gap2_displacement <= 0;
                        s_gap3_displacement <= 0;
                        s_moving_gap1_bool <= false;
                        s_moving_gap2_bool <= false;
                        s_moving_gap3_bool <= false;
        
                        s_score <= (others => '0');
					when others =>
						null;
				end case;

            elsif (s_game_start_bool = '1') then

                -- reset pipe 1 position when it reaches the left side of the screen
                if (s_pipe1_x_pos) <= (s_pipe_velocity - 1) then
                    s_pipe1_x_pos <= screen_width + pipe_width;
                    s_gap1_seed <= unsigned(lfsr_value(9 downto 4));

                    -- if in hard mode, pipe 1 has a chance of moving vertically
                    if (game_state = hard) then
                        s_gap1_displacement <= 0;
                        s_moving_gap1_bool <= (unsigned(lfsr_value(9 downto 0)) <= to_unsigned(512, 10)); -- 50% chance of pipe moving vertically for testin
                        if (s_moving_gap1_bool = true) then
                            if (lfsr_value(0) = '1') then
                                s_gap1_velocity <= -1; -- move up
                            else
                                s_gap1_velocity <= 1; -- move down
                            end if;
                        end if;
                    end if;
                else

                    -- pipe 1 horizontal movement
                    s_pipe1_x_pos <= s_pipe1_x_pos - s_pipe_velocity;

                    -- pipe 1 vertical movement
                    if (s_moving_gap1_bool = true) then
                        if (((s_gap1_y_pos <= 80) and (s_gap1_velocity = -1)) or ((s_gap1_y_pos >= 400) and (s_gap1_velocity = 1))) then
                            s_gap1_velocity <= -s_gap1_velocity;
                        end if;
                        s_gap1_displacement <= s_gap1_displacement + s_gap1_velocity;
                    end if;
                end if;
                
                -- reset pipe 2 position when it reaches the left side of the screen
                if (s_pipe2_x_pos) <= (s_pipe_velocity - 1) then
                    s_pipe2_x_pos <= screen_width + pipe_width;
                    s_gap2_seed <= unsigned(lfsr_value(9 downto 4));

                    -- if in hard mode, pipe 2 has a chance of moving vertically
                    if (game_state = hard) then
                        s_gap2_displacement <= 0;
                        s_moving_gap2_bool <= (unsigned(lfsr_value(9 downto 0)) <= to_unsigned(512, 10)); -- 50% chance of pipe moving vertically for testin
                        if (s_moving_gap2_bool = true) then
                            if (lfsr_value(0) = '1') then
                                s_gap2_velocity <= -1; -- move up
                            else
                                s_gap2_velocity <= 1; -- move down
                            end if;
                        end if;
                    end if;
                else

                    -- pipe 2 horizontal movement
                    s_pipe2_x_pos <= s_pipe2_x_pos - s_pipe_velocity;

                    -- pipe 2 vertical movement
                    if (s_moving_gap2_bool = true) then
                        if (((s_gap2_y_pos <= 80) and (s_gap2_velocity = -1)) or ((s_gap2_y_pos >= 400) and (s_gap2_velocity = 1))) then
                            s_gap2_velocity <= -s_gap2_velocity;
                        end if;
                        s_gap2_displacement <= s_gap2_displacement + s_gap2_velocity;
                    end if;
                end if;

                -- reset pipe 3 position when it reaches the left side of the screen
                if (s_pipe3_x_pos) <= (s_pipe_velocity - 1) then
                    s_pipe3_x_pos <= screen_width + pipe_width;
                    s_gap3_seed <= unsigned(lfsr_value(9 downto 4));

                    -- if in hard mode, pipe 1 has a chance of moving vertically
                    if (game_state = hard) then
                        s_gap3_displacement <= 0;
                        s_moving_gap3_bool <= (unsigned(lfsr_value(9 downto 0)) <= to_unsigned(512, 10)); -- 50% chance of pipe moving vertically for testin
                        if (s_moving_gap3_bool = true) then
                            if (lfsr_value(0) = '1') then
                                s_gap3_velocity <= -1; -- move up
                            else
                                s_gap3_velocity <= 1; -- move down
                            end if;
                        end if;
                    end if;
                else

                    -- pipe 3 horizontal movement
                    s_pipe3_x_pos <= s_pipe3_x_pos - s_pipe_velocity;

                    -- pipe 3 vertical movement
                    if (s_moving_gap3_bool = true) then
                        if (((s_gap3_y_pos <= 80) and (s_gap3_velocity = -1)) or ((s_gap3_y_pos >= 400) and (s_gap3_velocity = 1))) then
                            s_gap3_velocity <= -s_gap3_velocity;
                        end if;
                        s_gap3_displacement <= s_gap3_displacement + s_gap3_velocity;
                    end if;
                end if;

                -- s_score counting
                if ((s_pipe1_x_pos <= bird_x_pos) and (s_pipe1_x_pos >= (bird_x_pos - (s_pipe_velocity - 1)))) or
                    ((s_pipe2_x_pos <= bird_x_pos) and (s_pipe2_x_pos >= (bird_x_pos - (s_pipe_velocity - 1)))) or
                    ((s_pipe3_x_pos <= bird_x_pos) and (s_pipe3_x_pos >= (bird_x_pos - (s_pipe_velocity - 1)))) then

                    s_score <= std_logic_vector(unsigned(s_score) + 1);
                end if;

            end if;
        end if;
    end process;

end architecture behaviour;