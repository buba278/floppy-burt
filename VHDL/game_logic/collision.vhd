LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE  IEEE.STD_LOGIC_ARITH.all;
USE  IEEE.STD_LOGIC_UNSIGNED.all;

ENTITY collision IS

    PORT ( 
        bird_visible 	                                : IN std_logic;
        pipe1_visible, pipe2_visible, pipe3_visible     : IN std_logic;
        bird_x_pos, bird_y_pos                          : IN std_logic_vector(9 DOWNTO 0);
        bird_collision						            : OUT std_logic
    );		
END ENTITY collision;

architecture behaviour of collision is

    signal s_pipe_visible : std_logic;

BEGIN

    s_pipe_visible <= pipe1_visible or pipe2_visible or pipe3_visible;

    -- collosion detected when bird is visible and any pipe is visible at same time or when bird hits top or bottom of screen
    -- change when not a square

    bird_collision <= '1' when (s_pipe_visible = '1' and bird_visible = '1') or
                          (bird_y_pos <= CONV_STD_LOGIC_VECTOR(10,10)) or
                          (bird_y_pos >= CONV_STD_LOGIC_VECTOR(470,10)) else
                          '0';

end architecture behaviour;
