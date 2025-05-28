LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;
use work.fsm_states_pkg.all;


ENTITY screen_renderer IS
	PORT ( 
      clock                       	: IN std_logic;
      game_state                  	: IN state_type;
      current_col	               	: IN std_logic_vector(9 DOWNTO 0);
	  current_row                	: IN std_logic_vector(9 DOWNTO 0);
	  red, green, blue            	: OUT std_logic_vector(3 downto 0) -- 4bit color
	);		
END screen_renderer;

architecture behaviour of screen_renderer is
    -- rom declarations
    component mainmenu_rom IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (14 DOWNTO 0);
		clock		: IN STD_LOGIC;
		q		    : OUT STD_LOGIC_VECTOR (11 DOWNTO 0)
	);
    END component mainmenu_rom;

    component gameover_rom IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		: IN STD_LOGIC;
		q		    : OUT STD_LOGIC_VECTOR (11 DOWNTO 0)
	);
    END component gameover_rom;

    -- intermediate signals
    signal s_col_gameover : std_logic_vector(6 downto 0);
    signal s_row_gameover : std_logic_vector(6 downto 0);
    
    signal s_col_mainmenu : std_logic_vector(7 downto 0);
    signal s_row_mainmenu : std_logic_vector(6 downto 0);

    -- colors
    signal s_gameover_r, s_gameover_g, s_gameover_b : std_logic_vector(3 downto 0);
    signal s_mainmenu_r, s_mainmenu_g, s_mainmenu_b : std_logic_vector(3 downto 0);
    
BEGIN           
    -- 640x480 to 128x96 is 5 scaling
    -- pixel position assignments
    s_col_gameover <= std_logic_vector(to_unsigned(to_integer(unsigned(current_col)) / 5, 7));
    s_row_gameover <= std_logic_vector(to_unsigned(to_integer(unsigned(current_row)) / 5, 7));

    -- 256x120 is 2.5x4 scaling XD
    s_col_mainmenu <= std_logic_vector(to_unsigned((to_integer(unsigned(current_col)) * 2) / 5, 8));
    s_row_mainmenu <= std_logic_vector(to_unsigned(to_integer(unsigned(current_row)) / 4, 7));

    -- init components
    s1: mainmenu_rom
        port map (
            -- in
            address(14 downto 8) => s_row_mainmenu, -- 120 7 bytes
            address(7 downto 0) => s_col_mainmenu, -- 256 round up 8 bytes
            clock => clock,
            -- out
            q(11 downto 8) => s_mainmenu_r,
            q(7 downto 4) => s_mainmenu_g,
            q(3 downto 0) => s_mainmenu_b
        );

    g1: gameover_rom
        port map (
            -- in
            address(13 downto 7) => s_row_gameover, 
            address(6 downto 0) => s_col_gameover,
            clock => clock,
            -- out
            q(11 downto 8) => s_gameover_r,
            q(7 downto 4) => s_gameover_g,
            q(3 downto 0) => s_gameover_b
        );

    process(game_state, s_gameover_r, s_gameover_g, s_gameover_b, 
            s_mainmenu_r, s_mainmenu_g, s_mainmenu_b)
    begin
        if (game_state = game_over) then
            red <= s_gameover_r;
            green <= s_gameover_g;
            blue <= s_gameover_b;
        end if;
        if (game_state = start_menu) then
            red <= s_mainmenu_r;
            green <= s_mainmenu_g;
            blue <= s_mainmenu_b;
        end if;
    end process;

END behaviour;