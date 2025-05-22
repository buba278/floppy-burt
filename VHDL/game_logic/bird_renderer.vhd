LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE  IEEE.STD_LOGIC_ARITH.all;
USE  IEEE.STD_LOGIC_UNSIGNED.all;
USE work.fsm_states_pkg.all;

ENTITY bird_renderer IS

	PORT ( 
		left_button, right_button 	: IN std_logic;
		VGA_VS 						: IN std_logic;
		current_row, current_col	: IN std_logic_vector(9 DOWNTO 0);
		bird_reset					: IN std_logic;
		game_state 					: IN state_type;
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

	signal s_acceleration				: integer := 0;
	signal s_flap_velocity				: integer := -7;

	signal s_previous_game_state		: state_type;

	signal s_left_button_one_shot 		: std_logic := '0';
	signal s_previous_left_button		: std_logic := '0';
BEGIN           

	-- radius of ball & x pos
	s_size <= CONV_STD_LOGIC_VECTOR(10,10);

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

	bird_x_pos <= s_bird_x_pos;
	bird_y_pos <= s_bird_y_pos;

	process (VGA_VS, bird_reset)
		variable v_bird_x_pos 				: std_logic_vector(9 DOWNTO 0);
		variable v_bird_y_pos 				: std_logic_vector(9 DOWNTO 0);
		variable v_vel						: integer;
		variable v_acceleration				: integer;
		variable v_flap_velocity			: integer;
		variable v_left_button_one_shot 	: std_logic;
		variable v_previous_left_button		: std_logic;
	begin
		if (bird_reset = '1') then
			s_bird_y_pos <= CONV_STD_LOGIC_VECTOR(230,10);
			s_bird_x_pos <= CONV_STD_LOGIC_VECTOR(100,10);
			s_vel <= 0;
		elsif (rising_edge(VGA_VS)) then
			case game_state is
				when start =>
					v_flap_velocity := 0;
					v_acceleration := 0;
				when practice | easy | hard =>
					v_flap_velocity := -7;
					v_acceleration := 1;
				when game_over =>
					v_flap_velocity := 0;
					v_acceleration := 0;
				when others =>
					v_flap_velocity := 0;
					v_acceleration := 0;
			end case;

			v_left_button_one_shot := s_left_button_one_shot;

			if (left_button /= v_previous_left_button) then
				v_left_button_one_shot := left_button;
				s_left_button_one_shot <= v_left_button_one_shot;
				s_previous_left_button <= left_button;
			end if;

			if (game_state /= s_previous_game_state) then
				
				s_previous_game_state <= game_state;

				case game_state is
					when start | practice | easy | hard =>
						v_bird_y_pos := CONV_STD_LOGIC_VECTOR(230,10);
						v_bird_x_pos := CONV_STD_LOGIC_VECTOR(100,10);
						v_vel := 0;
					when game_over =>
						v_vel := 0;
					when others =>
						null;
				end case;
				
			else 
				if (v_left_button_one_shot ='1' and game_state /= game_over and game_state /= start) then
					v_vel := v_flap_velocity;
				else
					v_vel := s_vel + v_acceleration;
				end if;
				
				v_bird_y_pos := s_bird_y_pos + CONV_STD_LOGIC_VECTOR(v_vel,10);

			end if;

			s_bird_y_pos <= v_bird_y_pos;
			s_bird_x_pos <= v_bird_x_pos;

			s_vel <= v_vel;
		end if;

	end process;

END behaviour;

