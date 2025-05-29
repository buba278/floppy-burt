LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.STD_LOGIC_ARITH.all;
USE IEEE.STD_LOGIC_UNSIGNED.all;
USE work.fsm_states_pkg.all;

entity game_state is
    port (
        clk             : IN std_logic;
        reset           : IN std_logic;
        keys            : IN std_logic_vector(3 downto 0);
        mode_switch     : IN std_logic;
        left_button     : IN std_logic;
        bird_collision  : IN std_logic;
        score           : IN std_logic_vector(9 downto 0);
        bird_reset      : OUT std_logic;
        state           : OUT state_type
    );
end entity game_state;

architecture behaviour of game_state is
    -- State type declaration	
    signal s_current_state : state_type := start_menu;

begin

    process (clk, reset, keys, mode_switch, left_button, bird_collision, score)
        variable v_current_state : state_type;
        variable v_next_state : state_type;
    begin
        if (reset = '1' or (keys(0)= '0' and s_current_state = game_over)) then
            s_current_state <= start_menu;
        elsif (rising_edge(clk)) then
            v_current_state := s_current_state;

            case v_current_state is
                when start_menu =>
                    bird_reset <= '0';
                    if mode_switch = '0' and left_button = '1' then
                        v_next_state := practice;
                    elsif mode_switch = '1' and left_button = '1' then
                        v_next_state := easy;
                    else
                        v_next_state := start_menu;
                    end if;

                when practice =>
                    if keys(0) = '0' then
                        v_next_state := start_menu;
                    elsif bird_collision = '1' then
                        bird_reset <= '1';
                        v_next_state := practice;
                    elsif bird_collision = '0' then
                        bird_reset <= '0';
                        v_next_state := practice;
                    else
                        v_next_state := practice;
                    end if;

                when easy =>
                    -- if score is equal to 20 go to medium mode
                    if score = CONV_STD_LOGIC_VECTOR(1,10) then
                        v_next_state := medium;
                    elsif bird_collision = '1' then
                        v_next_state := game_over;
                    else
                        v_next_state := easy;
                    end if;

                when medium =>
                    -- if score is equal to 40 go to hard mode
                    if score = CONV_STD_LOGIC_VECTOR(2,10) then -- NUMBER NEEDS TO BE HARD MODE - 2 (so pipes can start moving earlier)
                        v_next_state := hard;
                    elsif bird_collision = '1' then
                        v_next_state := game_over;
                    else
                        v_next_state := medium;
                    end if;

                when hard =>
                    if bird_collision = '1' then
                        v_next_state := game_over;
                    else
                        v_next_state := hard;
                    end if;

                when game_over =>
                    if keys(0) = '0' then
                        v_next_state := start_menu;
                    else
                        v_next_state := game_over;
                    end if;
                
                when others =>
                    v_next_state := start_menu;
            end case;

            s_current_state <= v_next_state;
            state <= v_next_state;
        end if;
    end process;

end architecture behaviour;

