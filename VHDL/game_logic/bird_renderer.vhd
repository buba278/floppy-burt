LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;
use work.fsm_states_pkg.all;

ENTITY bird_renderer IS
	PORT ( 
		left_button, right_button 	: IN std_logic;
		VGA_VS, clock 				: IN std_logic;
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
	-- bird movement
	signal s_bird_y_pos, s_bird_x_pos 	: std_logic_vector(9 DOWNTO 0); -- := CONV_STD_LOGIC_VECTOR(230,10);
	signal s_vel						: integer range -12 to 100; -- := 0;

	signal s_previous_game_state		: state_type;
	signal s_previous_left_button		: std_logic; -- := '0';
	signal s_left_button_one_shot		: std_logic;

	-- clock "divisor"
	signal s_vga_counter 				: integer range 0 to 3; -- := 0;

	-- sprite position conversion
	signal s_otter_pos_row : std_logic_vector(6 downto 0);
	signal s_otter_pos_col : std_logic_vector(5 downto 0);
	signal s_otter_sprite  : integer range 0 to 6;
	signal s_otter_rom_row : std_logic_vector(6 downto 0);
	signal s_otter_rom_col : std_logic_vector(5 downto 0);
	-- flag for bird visibility
	signal s_otter_within_bounds : std_logic;

	-- seperating color for shield future proofing
	signal s_otter_r, s_otter_g, s_otter_b : std_logic_vector(3 downto 0);

	component otter_rom IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (12 DOWNTO 0);
		clock		: IN STD_LOGIC;
		q			: OUT STD_LOGIC_VECTOR (11 DOWNTO 0)
	);
	END component otter_rom;
	
BEGIN           
	
	otter: otter_rom
        port map (
            -- in
            address(12 downto 6) => s_otter_rom_row, -- 7 bit 96
            address(5 downto 0) => s_otter_rom_col, -- 6 bit 64
            clock => clock,
            -- out
            q(11 downto 8) => s_otter_r,
            q(7 downto 4) => s_otter_g,
            q(3 downto 0) => s_otter_b
        );

	-- set point for x
	-- ports for collision
	bird_x_pos <= s_bird_x_pos;
	bird_y_pos <= s_bird_y_pos;

	-- final color
	red <= s_otter_r;
	green <= s_otter_g;
	blue <= s_otter_b;

	-- sprite matching => matching multiplication to otter sprite
	-- just think about it sorry
	s_otter_rom_col <= std_logic_vector(to_unsigned((to_integer(unsigned(s_otter_pos_col)) / 2) + (32 * (1 - (s_otter_sprite mod 2))), s_otter_rom_col'length));
	s_otter_rom_row <= std_logic_vector(to_unsigned((to_integer(unsigned(s_otter_pos_row)) / 2) + (32 * (s_otter_sprite / 3)), s_otter_rom_row'length));

	-- otter positioning
	-- x positioning - 100 +- 16
	-- y positioning - y pos +- 16
	s_otter_within_bounds <= '1' when
    (to_integer(unsigned(current_col)) >= 68 and 
     to_integer(unsigned(current_col)) < 132 and
     to_integer(unsigned(current_row)) >= (to_integer(unsigned(s_bird_y_pos)) - 32) and 
     to_integer(unsigned(current_row)) < (to_integer(unsigned(s_bird_y_pos)) + 32))
    else '0';

	s_otter_pos_col <= std_logic_vector(to_unsigned(to_integer(unsigned(current_col)) - (to_integer(unsigned(s_bird_x_pos)) - 32), s_otter_pos_col'length))
					when s_otter_within_bounds = '1' else (others => '0');
	s_otter_pos_row <= std_logic_vector(to_unsigned(to_integer(unsigned(current_row)) - (to_integer(unsigned(s_bird_y_pos)) - 32), s_otter_pos_row'length))
					when s_otter_within_bounds = '1' else (others => '0');

	-- otter visibility
	bird_visible <= '1' when s_otter_within_bounds = '1' and not(s_otter_r = "0000" and s_otter_g = "0000" and s_otter_b = "0000") else '0';

	process (VGA_VS)
	begin
		if (rising_edge(VGA_VS)) then
			-- deciding what sprite we are at (6 states)
			-- neutral
			if (s_vel = 0) then
				s_otter_sprite <= 1;
			-- two for jump up
			-- stage 1
			elsif (s_vel < 0 and s_vel > -4) then
				s_otter_sprite <= 2;
			-- stage 2
			elsif (s_vel < -3) then
				s_otter_sprite <= 3;
			-- three for falling
			-- stage 1
			elsif (s_vel > 0 and s_vel < 3) then
				s_otter_sprite <= 4;
			-- stage 2
			elsif (s_vel < 5) then
				s_otter_sprite <= 5;
			-- stage 3
			elsif (s_vel < 8) then
				s_otter_sprite <= 6;
			else
				s_otter_sprite <= 1;
			end if;
		end if;
	end process;

	-- jumping and falling bird process
	process (VGA_VS, bird_reset, left_button, game_state)
		variable v_bird_x_pos 				: std_logic_vector(9 DOWNTO 0);
		variable v_bird_y_pos 				: std_logic_vector(9 DOWNTO 0);
		variable v_vel						: integer range -7 to 100 := 0;
		variable v_acceleration				: integer range 0 to 3;
		variable v_flap_velocity			: integer range -7 to 0;
		variable v_left_button_one_shot 	: std_logic;
		variable v_previous_left_button		: std_logic;
	begin
		-- reset condition
		if (bird_reset = '1') then
			s_bird_y_pos <= std_logic_vector(to_unsigned(230,10));
			s_bird_x_pos <= std_logic_vector(to_unsigned(100,10));
			s_vel <= 0;
		elsif (rising_edge(VGA_VS)) then
			-- different movements based on game state
			-- as in not response when not playing
			case game_state is
				when start_menu =>
					v_flap_velocity := 0;
					v_acceleration := 0;
				when practice | easy | medium | hard =>
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

			-- if left button has changes then one shot equals left button
			if (left_button /= s_previous_left_button) then
				v_left_button_one_shot := left_button;
				s_left_button_one_shot <= v_left_button_one_shot;
				s_previous_left_button <= left_button;
			else 
				v_left_button_one_shot := '0';
			end if;

			if (game_state /= s_previous_game_state) then
				
				s_previous_game_state <= game_state;

				case game_state is
					when start_menu =>
						v_bird_y_pos := std_logic_vector(to_unsigned(230,10));
						v_bird_x_pos := std_logic_vector(to_unsigned(100,10));
						v_vel := 0;
					when practice | easy =>
						v_vel := -7;
					when game_over =>
						v_vel := 0;
					when others =>
						null;
				end case;
				
			else 
				if (v_left_button_one_shot ='1' and game_state /= game_over and game_state /= start_menu) then
					v_vel := v_flap_velocity;
					v_left_button_one_shot := '0';
					v_left_button_one_shot := '0';
				else
					if (s_vga_counter < 1) then
						s_vga_counter <= s_vga_counter + 1;
					else
						v_vel := s_vel + v_acceleration;
						s_vga_counter <= 0;
					end if;	
				end if;
				
				v_bird_y_pos := std_logic_vector(to_unsigned(to_integer(unsigned(s_bird_y_pos)) + v_vel,10));
	
			end if;

			s_bird_y_pos <= v_bird_y_pos;
			s_bird_x_pos <= v_bird_x_pos;

			s_vel <= v_vel;
		end if;

	end process;
END behaviour;