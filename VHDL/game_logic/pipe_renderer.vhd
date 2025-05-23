library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pipe_renderer is
    port(
        clk, reset                                      : IN std_logic;
        VGA_VS                                          : IN std_logic;
        current_row, current_col                        : IN std_logic_vector(9 downto 0);
        lfsr_value                                      : IN std_logic_vector(9 downto 0);
        pipe1_visible, pipe2_visible, pipe3_visible     : OUT std_logic;
        red1, green1, blue1                             : OUT std_logic_vector(3 downto 0);
        red2, green2, blue2                             : OUT std_logic_vector(3 downto 0);
        red3, green3, blue3                             : OUT std_logic_vector(3 downto 0)
    );
end entity pipe_renderer;

architecture behaviour of pipe_renderer is

    constant pipe_width         : integer := 50;    -- diameter of pipe
    constant screen_width       : integer := 640;

    signal s_pipe1_on, s_pipe2_on, s_pipe3_on                   : std_logic_vector(3 downto 0);
    signal s_pipe1_on_bool, s_pipe2_on_bool, s_pipe3_on_bool    : std_logic;

    -- tracks the right edge of the pipes
    signal pipe1_x_pos          : unsigned(9 downto 0) := to_unsigned(215,10);
    signal pipe2_x_pos          : unsigned(9 downto 0) := to_unsigned(433,10);
    signal pipe3_x_pos          : unsigned(9 downto 0) := to_unsigned(661,10);
    
    signal gap1_seed, gap2_seed, gap3_seed                      : unsigned(5 downto 0);
    signal gap1_y_pos, gap2_y_pos, gap3_y_pos                   : unsigned(11 downto 0) := to_unsigned(200,12);
    signal gap_height                                           : unsigned(9 downto 0) := to_unsigned(60,10);

begin

    gap1_y_pos <= to_unsigned(80,12) + (gap1_seed * 5);
    gap2_y_pos <= to_unsigned(80,12) + (gap2_seed * 5);
    gap3_y_pos <= to_unsigned(80,12) + (gap3_seed * 5);

    s_pipe1_on_bool <= '1' when (to_integer(unsigned(current_col)) >= to_integer(pipe1_x_pos) - pipe_width) and (to_integer(unsigned(current_col)) <= to_integer(pipe1_x_pos))
                            and ((to_integer(unsigned(current_row)) <= to_integer(gap1_y_pos) - to_integer(gap_height)) or (to_integer(unsigned(current_row)) >= to_integer(gap1_y_pos) + to_integer(gap_height)))
                            else '0';

    s_pipe2_on_bool <= '1' when (to_integer(unsigned(current_col)) >= to_integer(pipe2_x_pos) - pipe_width) and (to_integer(unsigned(current_col)) <= to_integer(pipe2_x_pos))
                            and ((to_integer(unsigned(current_row)) <= to_integer(gap2_y_pos) - to_integer(gap_height)) or (to_integer(unsigned(current_row)) >= to_integer(gap2_y_pos) + to_integer(gap_height)))
                            else '0';

    s_pipe3_on_bool <= '1' when (to_integer(unsigned(current_col)) >= to_integer(pipe3_x_pos) - pipe_width) and (to_integer(unsigned(current_col)) <= to_integer(pipe3_x_pos))
                            and ((to_integer(unsigned(current_row)) <= to_integer(gap3_y_pos) - to_integer(gap_height)) or (to_integer(unsigned(current_row)) >= to_integer(gap3_y_pos) + to_integer(gap_height)))
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

    -- moving pipes across the screen
    process(VGA_VS)
    begin
        if rising_edge(VGA_VS) then

            -- need to adjust this comparison if changing the "speed" of the pipes to avoid negative values
            if (to_integer(pipe1_x_pos)) <= 1 then
                pipe1_x_pos <= to_unsigned(screen_width + pipe_width, 10);
                gap1_seed <= unsigned(lfsr_value(9 downto 4));
            else
                pipe1_x_pos <= pipe1_x_pos - 2;
            end if;
                
            if (to_integer(pipe2_x_pos)) <= 1 then
                pipe2_x_pos <= to_unsigned(screen_width + pipe_width, 10);
                gap2_seed <= unsigned(lfsr_value(7 downto 2));    
                else 
                pipe2_x_pos <= pipe2_x_pos - 2;
            end if;

            if (to_integer(pipe3_x_pos)) <= 1 then
                pipe3_x_pos <= to_unsigned(screen_width + pipe_width, 10);
                gap3_seed <= unsigned(lfsr_value(5 downto 0));
                else
                pipe3_x_pos <= pipe3_x_pos - 2;
            end if;

        end if;
    end process;

end architecture behaviour;