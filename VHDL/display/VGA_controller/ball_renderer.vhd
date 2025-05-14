LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE  IEEE.STD_LOGIC_ARITH.all;
USE  IEEE.STD_LOGIC_UNSIGNED.all;

ENTITY ball_renderer IS
	PORT ( 
		pixel_row, pixel_column	: IN std_logic_vector(9 DOWNTO 0);
        ball_visible : OUT std_logic;
		red, green, blue : OUT std_logic_vector(3 downto 0)
	);		
END ball_renderer;

architecture behaviour of ball_renderer is

	SIGNAL ball_on					: std_logic_vector(3 DOWNTO 0);
	SIGNAL ball_on_bool				: std_logic;
	SIGNAL size 					: std_logic_vector(9 DOWNTO 0);  
	SIGNAL ball_y_pos, ball_x_pos	: std_logic_vector(9 DOWNTO 0);

BEGIN           

	size <= CONV_STD_LOGIC_VECTOR(8,10);
	-- ball_x_pos and ball_y_pos show the (x,y) for the centre of ball_renderer
	ball_x_pos <= CONV_STD_LOGIC_VECTOR(590,10);
	ball_y_pos <= CONV_STD_LOGIC_VECTOR(350,10);


	ball_on_bool <= '1' when ( (ball_x_pos - size <= pixel_column) and (pixel_column <= ball_x_pos + size) 	-- x_pos - size <= pixel_column <= x_pos + size
						and (ball_y_pos - size <= pixel_row) and (pixel_row <= ball_y_pos + size) )  else	-- y_pos - size <= pixel_row <= y_pos + size
					'0';

	ball_on <= (others => ball_on_bool);
	-- Colours for pixel data on video signal
	-- Keeping background white and square in red
	red <=  "1111";
	-- Turn off Green and Blue when displaying square
	green <= not ball_on;
	blue <=  not ball_on;

    ball_visible <= ball_on_bool;

END behaviour;

