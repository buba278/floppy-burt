LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.STD_LOGIC_ARITH.all;
USE IEEE.STD_LOGIC_UNSIGNED.all;
USE work.fsm_states_pkg.all;

entity game_state is
    port (
        mode_switches   : IN std_logic_vector(1 downto 0);
        start_button    : IN std_logic;
        bird_collision  : IN std_logic;
        bird_reset      : OUT std_logic;
        state           : OUT state_type
    );
end entity game_state;

architecture behaviour of game_state is
    -- State type declaration	
    signal s_current_state : state_type := start;
    signal s_next_state    : state_type;

begin

    process (start_button, bird_collision)
        variable v_current_state : state_type;
    begin
        v_current_state := s_current_state;

        case v_current_state is
            when start =>
                if start_button = '1' and mode_switches = "01" then
                    s_next_state <= practice;
                elsif start_button = '1' and mode_switches = "10" then
                    s_next_state <= easy;
                elsif start_button = '1' and mode_switches = "11" then
                    s_next_state <= hard;
                else
                    s_next_state <= start;
                end if;

            when practice =>
                if mode_switches = "00" then
                    s_next_state <= start;
                elsif bird_collision = '1' then
                    bird_reset <= '1';
                    s_next_state <= practice;
                else
                    s_next_state <= practice;
                end if;

            when easy =>
                if bird_collision = '1' then
                    s_next_state <= game_over;
                else
                    s_next_state <= easy;
                end if;

            when hard =>
                if bird_collision = '1' then
                    s_next_state <= game_over;
                else
                    s_next_state <= hard;
                end if;

            when game_over =>
                if start_button = '1' then
                    s_next_state <= start;
                else
                    s_next_state <= game_over;
                end if;

        end case;

        s_current_state <= s_next_state;
    end process;


end architecture behaviour;

