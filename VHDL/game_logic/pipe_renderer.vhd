library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity pipe_renderer is
    port(
        clk, reset                                      : IN std_logic;
        VGA_VS                                          : IN std_logic;
        current_row, current_col                        : IN std_logic_vector(9 downto 0);
        pipe1_visible, pipe2_visible, pipe3_visible     : OUT std_logic;
		red1, green1, blue1                             : OUT std_logic_vector(3 downto 0);
        red2, green2, blue2                             : OUT std_logic_vector(3 downto 0);
        red3, green3, blue3                             : OUT std_logic_vector(3 downto 0)
    );
end entity pipe_renderer;

architecture behaviour of pipe_renderer is

    constant pipe_width              : integer := 30;                -- radius of pipe
    constant screen_width            : integer := 640;
    constant screen_height           : integer := 480;

    signal s_pipe1_on                : std_logic_vector(3 downto 0);
    signal s_pipe2_on                : std_logic_vector(3 downto 0);
    signal s_pipe3_on                : std_logic_vector(3 downto 0);
    signal s_pipe1_on_bool           : std_logic;
    signal s_pipe2_on_bool           : std_logic;
    signal s_pipe3_on_bool           : std_logic;

    signal pipe1_x_pos               : std_logic_vector(9 downto 0) := CONV_STD_LOGIC_VECTOR(214,10); -- centre of pipe
    signal pipe2_x_pos               : std_logic_vector(9 downto 0) := CONV_STD_LOGIC_VECTOR(428,10); -- centre of pipe
    signal pipe3_x_pos               : std_logic_vector(9 downto 0) := CONV_STD_LOGIC_VECTOR(640,10); -- centre of pipe
    signal gap1_y_pos                : std_logic_vector(9 downto 0) := CONV_STD_LOGIC_VECTOR(200,10); -- TEMP
    signal gap2_y_pos                : std_logic_vector(9 downto 0) := CONV_STD_LOGIC_VECTOR(200,10); -- TEMP
    signal gap3_y_pos                : std_logic_vector(9 downto 0) := CONV_STD_LOGIC_VECTOR(200,10); -- TEMP
    signal gap1_height               : std_logic_vector(9 downto 0) := CONV_STD_LOGIC_VECTOR(60,10);  -- TEMP
    signal gap2_height               : std_logic_vector(9 downto 0) := CONV_STD_LOGIC_VECTOR(60,10);  -- TEMP
    signal gap3_height               : std_logic_vector(9 downto 0) := CONV_STD_LOGIC_VECTOR(60,10);  -- TEMP

    -- component lsfr is

begin

    s_pipe1_on_bool <= '1' when  (current_col >= pipe1_x_pos - CONV_STD_LOGIC_VECTOR(pipe_width,10)) and (current_col <= pipe1_x_pos + CONV_STD_LOGIC_VECTOR(pipe_width,10))
                            and ((current_row <= gap1_y_pos - gap1_height) or (current_row >= gap1_y_pos + gap1_height))
                            else '0';

    s_pipe1_on <= (others => s_pipe1_on_bool);

    s_pipe2_on_bool <= '1' when  (current_col >= pipe2_x_pos - CONV_STD_LOGIC_VECTOR(pipe_width,10)) and (current_col <= pipe2_x_pos + CONV_STD_LOGIC_VECTOR(pipe_width,10))
                            and ((current_row <= gap2_y_pos - gap2_height) or (current_row >= gap2_y_pos + gap2_height))
                            else '0';

    s_pipe2_on <= (others => s_pipe2_on_bool);

    s_pipe3_on_bool <= '1' when  (current_col >= pipe3_x_pos - CONV_STD_LOGIC_VECTOR(pipe_width,10)) and (current_col <= pipe3_x_pos + CONV_STD_LOGIC_VECTOR(pipe_width,10))
                            and ((current_row <= gap3_y_pos - gap3_height) or (current_row >= gap3_y_pos + gap3_height))
                            else '0';

    s_pipe3_on <= (others => s_pipe3_on_bool);

    red1 <= not s_pipe1_on;
    green1 <= s_pipe1_on;
    blue1 <= not s_pipe1_on;

    red2 <= not s_pipe2_on;
    green2 <= s_pipe2_on;
    blue2 <= not s_pipe2_on;

    red3 <= not s_pipe3_on;
    green3 <= s_pipe3_on;
    blue3 <= not s_pipe3_on;

    pipe1_visible <= s_pipe1_on_bool;
    pipe2_visible <= s_pipe2_on_bool;
    pipe3_visible <= s_pipe3_on_bool;

    process(VGA_VS)
    begin
        if (rising_edge(VGA_VS)) then

            if ((pipe1_x_pos + CONV_STD_LOGIC_VECTOR(pipe_width,10)) = CONV_STD_LOGIC_VECTOR(0,10)) then
                pipe1_x_pos <= CONV_STD_LOGIC_VECTOR(screen_width + pipe_width, 10);
            else
                pipe1_x_pos <= pipe1_x_pos - 1;
            end if;

            if ((pipe2_x_pos + CONV_STD_LOGIC_VECTOR(pipe_width,10)) = CONV_STD_LOGIC_VECTOR(0,10)) then
                pipe2_x_pos <= CONV_STD_LOGIC_VECTOR(screen_width + pipe_width, 10);
            else
                pipe2_x_pos <= pipe2_x_pos - 1;
            end if;

            if ((pipe3_x_pos + CONV_STD_LOGIC_VECTOR(pipe_width,10)) = CONV_STD_LOGIC_VECTOR(0,10)) then
                pipe3_x_pos <= CONV_STD_LOGIC_VECTOR(screen_width + pipe_width, 10) ;
            else
                pipe3_x_pos <= pipe3_x_pos - 1;
            end if;

        end if;

    end process;

end architecture behaviour;