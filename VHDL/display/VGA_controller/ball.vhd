LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE  IEEE.STD_LOGIC_ARITH.all;
USE  IEEE.STD_LOGIC_UNSIGNED.all;


ENTITY ball IS
	PORT ( 
		clk : IN std_logic;
		pixel_row, pixel_column	: IN std_logic_vector(9 DOWNTO 0);
		red, green, blue : OUT std_logic_vector(3 downto 0)
	);		
END ball;

architecture behavior of ball is

	SIGNAL ball_on					: std_logic_vector(3 DOWNTO 0);
	SIGNAL size 					: std_logic_vector(9 DOWNTO 0);  
	SIGNAL ball_y_pos, ball_x_pos	: std_logic_vector(9 DOWNTO 0);

BEGIN           

	size <= CONV_STD_LOGIC_VECTOR(8,10);
	-- ball_x_pos and ball_y_pos show the (x,y) for the centre of ball
	ball_x_pos <= CONV_STD_LOGIC_VECTOR(590,10);
	ball_y_pos <= CONV_STD_LOGIC_VECTOR(350,10);


	ball_on <= "1111" when ( ("1111" & ball_x_pos <= pixel_column + size) and ("0000" & pixel_column <= ball_x_pos + size) 	-- x_pos - size <= pixel_column <= x_pos + size
						and ("0000" & ball_y_pos <= pixel_row + size) and ("0000" & pixel_row <= ball_y_pos + size) )  else	-- y_pos - size <= pixel_row <= y_pos + size
				"0000";


	-- Colours for pixel data on video signal
	-- Keeping background white and square in red
	red <=  "1111";
	-- Turn off Green and Blue when displaying square
	green <= not ball_on;
	blue <=  not ball_on;

END behavior;

