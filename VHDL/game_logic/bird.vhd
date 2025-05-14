LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE  IEEE.STD_LOGIC_ARITH.all;
USE  IEEE.STD_LOGIC_UNSIGNED.all;

ENTITY bird IS
	PORT ( 
		clk : IN std_logic;
        left_button, right_button : IN std_logic;
		pixel_row, pixel_column	: IN std_logic_vector(9 DOWNTO 0);
        bird_visible : OUT std_logic;
		red, green, blue : OUT std_logic_vector(3 downto 0)
	);		
END bird;

architecture behaviour of bird is

	SIGNAL bird_on					: std_logic_vector(3 DOWNTO 0);
	SIGNAL bird_on_bool				: std_logic;
	SIGNAL size 					: std_logic_vector(9 DOWNTO 0);  
	SIGNAL bird_y_pos, bird_x_pos	: std_logic_vector(9 DOWNTO 0);
    SIGNAL velocity                 : std_logic_vector(9 DOWNTO 0);

BEGIN           

	size <= CONV_STD_LOGIC_VECTOR(8,10);
	-- bird_x_pos and bird_y_pos show the (x,y) for the centre of bird_renderer
	bird_x_pos <= CONV_STD_LOGIC_VECTOR(590,10);
	bird_y_pos <= CONV_STD_LOGIC_VECTOR(350,10);


	bird_on_bool <= '1' when ( (bird_x_pos - size <= pixel_column) and (pixel_column <= bird_x_pos + size) 	-- x_pos - size <= pixel_column <= x_pos + size
						and (bird_y_pos - size <= pixel_row) and (pixel_row <= bird_y_pos + size) )  else	-- y_pos - size <= pixel_row <= y_pos + size
					'0';

	bird_on <= (others => bird_on_bool);
	-- Colours for pixel data on video signal
	-- Keeping background white and square in red
	red <=  "1111";
	-- Turn off Green and Blue when displaying square
	green <= not bird_on;
	blue <=  not bird_on;

    bird_visible <= bird_on_bool;

    process (s_VGA_VS)
    begin
        vert_sync_div <= vert_sync_div + 1;

    end process;

    Bird_Movement: process (clk, left_button)
    begin 

        if (left_button = '1') then
            bird_y_pos <= bird_y_pos + 5;
        elsif (rising_edge(clk)) then
            bird_y_pos <= bird_y_pos - 1;
        end if;

    end process Bird_Movement;

END behaviour;

