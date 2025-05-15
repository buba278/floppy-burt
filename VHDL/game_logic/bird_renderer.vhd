LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE  IEEE.STD_LOGIC_ARITH.all;
USE  IEEE.STD_LOGIC_UNSIGNED.all;

ENTITY bird_renderer IS

	PORT ( 
		left_button, right_button : IN std_logic;
		VGA_VS : IN std_logic;
		pixel_row, pixel_column	: IN std_logic_vector(9 DOWNTO 0);
        bird_visible : OUT std_logic;
		red, green, blue : OUT std_logic_vector(3 downto 0)
	);		
END ENTITY bird_renderer;

architecture behaviour of bird_renderer is

	constant acceleration : integer := 1;

	signal bird_on					: std_logic_vector(3 DOWNTO 0);
	SIGNAL bird_on_bool				: std_logic;
	SIGNAL size 					: std_logic_vector(9 DOWNTO 0);  
	SIGNAL bird_y_pos 				: std_logic_vector(9 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(230,10);
	signal bird_x_pos				: std_logic_vector(9 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(100,10);
	signal velocity					: integer range -10 to 10;
	signal vert_sync_div			: integer range 0 to 1000 := 0;

BEGIN           

	size <= CONV_STD_LOGIC_VECTOR(10,10);

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

	process(left_button, VGA_VS)
	begin
		if (left_button = '1') then
			velocity <= -5;
		end if;

		if (VGA_VS = '1') then
			vert_sync_div <= vert_sync_div + 1;

			if (vert_sync_div = 50) then

				bird_y_pos <= bird_y_pos + velocity;
				velocity <= velocity + acceleration;
				if (velocity > 5) then
					velocity <= 5;
				elsif (velocity < -5) then
					velocity <= -5;
				end if;

				if (bird_y_pos > CONV_STD_LOGIC_VECTOR(470,10)) then
					bird_y_pos <= CONV_STD_LOGIC_VECTOR(230,10);
				elsif 
					(bird_y_pos < CONV_STD_LOGIC_VECTOR(0,10)) then
					bird_y_pos <= CONV_STD_LOGIC_VECTOR(230,10);					
				end if;

				vert_sync_div <= 0;
			end if;
			
		end if;
	end process;

END behaviour;

