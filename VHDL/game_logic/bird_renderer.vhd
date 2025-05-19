LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE  IEEE.STD_LOGIC_ARITH.all;
USE  IEEE.STD_LOGIC_UNSIGNED.all;

ENTITY bird_renderer IS

	PORT ( 
		left_button, right_button 	: IN std_logic;
		VGA_VS 						: IN std_logic;
		current_row, current_col	: IN std_logic_vector(9 DOWNTO 0);
        bird_visible 				: OUT std_logic;
		red, green, blue 			: OUT std_logic_vector(3 downto 0);
		bird_y_pos 					: OUT std_logic_vector(9 DOWNTO 0);
		bird_x_pos					: OUT std_logic_vector(9 DOWNTO 0)
	);		
END ENTITY bird_renderer;

architecture behaviour of bird_renderer is

	signal s_bird_on					: std_logic_vector(3 DOWNTO 0);
	SIGNAL s_bird_on_bool				: std_logic;
	SIGNAL s_size 						: std_logic_vector(9 DOWNTO 0);  

	SIGNAL s_bird_y_pos 				: std_logic_vector(9 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(230,10);
	signal s_bird_x_pos					: std_logic_vector(9 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(100,10);

	signal s_reset_vel					: std_logic := '0';
	signal s_vel						: integer := 0;

BEGIN           

	-- radius of ball & x pos
	s_size <= CONV_STD_LOGIC_VECTOR(10,10);
	s_bird_x_pos <= CONV_STD_LOGIC_VECTOR(100,10);

	s_bird_on_bool <= '1' when ( (s_bird_x_pos - s_size <= current_col) and (current_col <= s_bird_x_pos + s_size) 	-- x_pos - s_size <= current_col <= x_pos + s_size
						and (s_bird_y_pos - s_size <= current_row) and (current_row <= s_bird_y_pos + s_size) )  else	-- y_pos - s_size <= current_row <= y_pos + s_size
				'0';

	s_bird_on <= (others => s_bird_on_bool);

	-- ball red when visible
	red <=  s_bird_on;
	green <= not s_bird_on;
	blue <=  not s_bird_on;

	-- renederer output port
    bird_visible <= s_bird_on_bool;

	s_reset_vel <= right_button;
	-- s_bird_y_pos <= CONV_STD_LOGIC_VECTOR(300,10) when left_button = '0' else (s_bird_y_pos - CONV_STD_LOGIC_VECTOR(1,10));

	bird_x_pos <= s_bird_x_pos;
	bird_y_pos <= s_bird_y_pos;

	process (VGA_VS)
		variable v_bird_y_pos 	: std_logic_vector(9 DOWNTO 0);
		variable v_vel			: integer;
	begin
		if (rising_edge(VGA_VS) and left_button = '1') then
			v_vel := s_vel + 1;
			s_vel <= v_vel;

			v_bird_y_pos := s_bird_y_pos + CONV_STD_LOGIC_VECTOR(v_vel,10);
			s_bird_y_pos <= v_bird_y_pos;
		end if;

		if (s_reset_vel = '1') then
			s_vel <= -10;
		end if;
	end process;

END behaviour;

