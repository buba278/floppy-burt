library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.fsm_states_pkg.all;

entity floppy_burt_top is
    port (
        RESET_N : in std_logic;
        CLOCK_50 : in std_logic;
        KEY : in std_logic_vector(3 downto 0);
        SW : in std_logic_vector(9 downto 0);
        HEX0, HEX1, HEX2, HEX3, HEX4, HEX5 : out std_logic_vector(6 downto 0);
        VGA_R, VGA_G, VGA_B : out std_logic_vector(3 downto 0);
        VGA_HS, VGA_VS : out std_logic;
        LEDR : out std_logic_vector(9 downto 0);
        PS2_CLK : INOUT std_logic;
        PS2_DAT : INOUT std_logic
    );
end floppy_burt_top; 

configuration config of floppy_burt_top is
    for test_game -- change to desired architecture
    end for;
end config;

architecture test_game of floppy_burt_top is
    component VGA_SYNC is
        port (
            clock_25Mhz : in STD_LOGIC; 
            red, green, blue : in STD_LOGIC_VECTOR(3 downto 0);
            red_out, green_out, blue_out : out STD_LOGIC_VECTOR(3 downto 0);
            horiz_sync_out, vert_sync_out : out STD_LOGIC;
            pixel_row, pixel_column: out STD_LOGIC_VECTOR(9 downto 0)
        );
    end component VGA_SYNC;

    component total_text_renderer IS
	PORT (
        clk                                 : in std_logic;
        current_row, current_col            : in std_logic_vector(9 downto 0);
        game_state                          : in state_type;
        text_visible                        : out std_logic;
        red, green, blue                    : out std_logic_vector(3 downto 0)
	);		
    END component total_text_renderer;

    component pll25MHz is
        port (
            refclk   : in  std_logic := '0'; --  refclk.clk
            rst      : in  std_logic := '0'; --   reset.reset
            outclk_0 : out std_logic;        -- outclk0.clk
            locked   : out std_logic         --  locked.export
        );
    end component pll25MHz;

    component mouse is
        port (
        	clock_25Mhz 		        : IN std_logic;
            reset 		                : IN std_logic := '0';
            mouse_data					: INOUT std_logic;
            mouse_clk 					: INOUT std_logic;
            left_button, right_button	: OUT std_logic;
		    mouse_cursor_row 			: OUT std_logic_vector(9 DOWNTO 0); 
		    mouse_cursor_column 		: OUT std_logic_vector(9 DOWNTO 0) 
        );
    end component mouse;

    component bird_renderer IS
        port (
            left_button, right_button   : IN std_logic;
            VGA_VS                      : IN std_logic;
            current_row, current_col	: IN std_logic_vector(9 DOWNTO 0);
            bird_reset					: IN std_logic;
		    game_state 					: IN state_type;
            bird_visible                : OUT std_logic;
            red, green, blue            : OUT std_logic_vector(3 downto 0);
            bird_y_pos 					: OUT std_logic_vector(9 DOWNTO 0);
		    bird_x_pos					: OUT std_logic_vector(9 DOWNTO 0)
        );		
    end component bird_renderer;

    component pipe_renderer is
    port(
        clk, reset                                      : IN std_logic;
        VGA_VS                                          : IN std_logic;
        current_row, current_col                        : IN std_logic_vector(9 downto 0);
        lfsr_value                                      : IN std_logic_vector(9 downto 0);
        pipe1_visible, pipe2_visible, pipe3_visible     : OUT std_logic;
		red1, green1, blue1                             : OUT std_logic_vector(3 downto 0);
        red2, green2, blue2                             : OUT std_logic_vector(3 downto 0);
        red3, green3, blue3                             : OUT std_logic_vector(3 downto 0)
    );
    end component pipe_renderer;

    component display_7seg is
        port (
            clk_25MHz, reset      : in std_logic;
            mode_select           : in std_logic;
            seven_seg_out_0       : out std_logic_vector(6 downto 0);
            seven_seg_out_1       : out std_logic_vector(6 downto 0);
            seven_seg_out_2       : out std_logic_vector(6 downto 0);
            seven_seg_out_3       : out std_logic_vector(6 downto 0);
            seven_seg_out_4       : out std_logic_vector(6 downto 0);
            seven_seg_out_5       : out std_logic_vector(6 downto 0)
        );
    end component display_7seg;

    component collision is 
        port (
            bird_visible 	                                : IN std_logic;
            pipe1_visible, pipe2_visible, pipe3_visible     : IN std_logic;
            bird_x_pos, bird_y_pos                          : IN std_logic_vector(9 DOWNTO 0);
            bird_collision						            : OUT std_logic
        );
    end component collision;

    component game_state is
        port (
            clk             : IN std_logic;
            mode_switches   : IN std_logic_vector(1 downto 0);
            start_button    : IN std_logic;
            bird_collision  : IN std_logic;
            bird_reset      : OUT std_logic;
            state           : OUT state_type
        );
    end component game_state;

    component lfsr
        port (
            clk             : IN std_logic;
            reset           : IN std_logic;
            lfsr_out        : OUT std_logic_vector(9 downto 0)
        );
    end component lfsr;

    -- ===== INTERMEDIATE SIGNALS =====
    -- pll
    signal clock_25Mhz, s_locked, s_rst : std_logic;

    -- ball renderer
    signal s_bird_visible : std_logic;
    signal s_bird_r, s_bird_g, s_bird_b : std_logic_vector(3 downto 0);
    signal s_bird_x_pos, s_bird_y_pos : std_logic_vector(9 downto 0);

    -- pipe renderer
    signal s_pipe1_visible, s_pipe2_visible, s_pipe3_visible : std_logic;
    signal s_pipe1_r, s_pipe1_g, s_pipe1_b : std_logic_vector(3 downto 0);
    signal s_pipe2_r, s_pipe2_g, s_pipe2_b : std_logic_vector(3 downto 0);
    signal s_pipe3_r, s_pipe3_g, s_pipe3_b : std_logic_vector(3 downto 0);

    -- text
    signal s_text_r, s_text_g, s_text_b : std_logic_vector(3 downto 0);
    signal s_text_visible : std_logic;

    -- full renderer
    signal s_final_r, s_final_g, s_final_b : std_logic_vector(3 downto 0);
    signal s_pix_row, s_pix_col : std_logic_vector(9 downto 0);

    signal s_VGA_VS, s_VGA_HS : std_logic;

    -- mouse
    signal s_left_button                : std_logic;
    signal s_right_button	            : std_logic;
    signal s_mouse_cursor_row 			: std_logic_vector(9 DOWNTO 0); 
    signal s_mouse_cursor_column 		: std_logic_vector(9 DOWNTO 0);

    -- collision
    signal s_bird_collision : std_logic;

    -- game state
    signal s_game_state : state_type;
    signal s_bird_reset : std_logic;

    -- lfsr
    signal s_lfsr_out : std_logic_vector(9 downto 0);
    

begin

    -- pulled down
    s_rst <= not RESET_N;

    c1: pll25MHz
        port map (
            refclk => CLOCK_50,
            rst => s_rst,
            outclk_0 => clock_25Mhz,
            locked => s_locked
        );

    v1: VGA_SYNC
        port map (
            -- input
            clock_25Mhz => clock_25Mhz,
            red => s_final_r,
            green => s_final_g,
            blue => s_final_b,
            -- output
            red_out => VGA_R, 
            green_out => VGA_G,
            blue_out => VGA_B,
            horiz_sync_out => s_VGA_HS,
            vert_sync_out => s_VGA_VS,
            pixel_row => s_pix_row, -- what pixel we currently rendering? might need +1
            pixel_column => s_pix_col
        );  

    t1: total_text_renderer
        port map (
            -- input
            clk => clock_25Mhz,
            current_row => s_pix_row,
            current_col => s_pix_col,
            game_state => s_game_state,

            -- output
            text_visible => s_text_visible,
            red => s_text_r,
            green => s_text_g,
            blue => s_text_b
        );

    m1: mouse
        port map (
            -- in
            clock_25Mhz => clock_25Mhz,
            -- inout
            reset => s_rst,
            mouse_data => PS2_DAT,
            mouse_clk => PS2_CLK,
            -- out
            left_button => s_left_button,
            right_button => s_right_button,
            mouse_cursor_row => s_mouse_cursor_row,
            mouse_cursor_column => s_mouse_cursor_column
        );
    
    b1: bird_renderer
        port map (
            -- in
            left_button => s_left_button,
            right_button => s_right_button,
            VGA_VS => s_VGA_VS,
            current_row => s_pix_row, 
            current_col => s_pix_col,
            bird_reset => s_bird_reset,
            game_state => s_game_state,
            -- out
            bird_visible => s_bird_visible,
            red => s_bird_r,
            green => s_bird_g,
            blue => s_bird_b,
            bird_y_pos => s_bird_y_pos,
            bird_x_pos => s_bird_x_pos
        );	

    p1: pipe_renderer
        port map (
            -- input
            clk => clock_25Mhz,
            reset => s_rst,
            VGA_VS => s_VGA_VS,
            current_row => s_pix_row,
            current_col => s_pix_col,
            lfsr_value => s_lfsr_out,
            -- output
            pipe1_visible => s_pipe1_visible,
            pipe2_visible => s_pipe2_visible,
            pipe3_visible => s_pipe3_visible,
            red1 => s_pipe1_r,
            green1 => s_pipe1_g,
            blue1 => s_pipe1_b,
            red2 => s_pipe2_r,
            green2 => s_pipe2_g,
            blue2 => s_pipe2_b,
            red3 => s_pipe3_r,
            green3 => s_pipe3_g,
            blue3 => s_pipe3_b
        );
        
    d1: display_7seg
    port map (
        -- in
        clk_25MHz => clock_25Mhz,
        reset => s_rst,
        mode_select => SW(2),
        -- out
        seven_seg_out_0 => HEX0,
        seven_seg_out_1 => HEX1,
        seven_seg_out_2 => HEX2,
        seven_seg_out_3 => HEX3,
        seven_seg_out_4 => HEX4,
        seven_seg_out_5 => HEX5
        );

    k1 : collision
    port map (
        bird_visible => s_bird_visible,
        pipe1_visible => s_pipe1_visible,
        pipe2_visible => s_pipe2_visible,
        pipe3_visible => s_pipe3_visible,
        bird_x_pos => s_bird_x_pos,
        bird_y_pos => s_bird_y_pos,
        bird_collision => s_bird_collision
    );

    g1 : game_state
    port map (
        clk => clock_25Mhz,
        mode_switches => SW(1 downto 0),
        start_button => not KEY(0),
        bird_collision => s_bird_collision,
        bird_reset => s_bird_reset,
        state => s_game_state
    );

    l1 : lfsr
    port map (
        clk => clock_25Mhz,
        reset => s_rst,
        lfsr_out => s_lfsr_out
    );

    -- ======= RENDERER =======

    process(s_bird_r,s_bird_g,s_bird_b,s_bird_visible,s_text_r,s_text_g,s_text_b,s_text_visible, 
            s_pipe1_r,s_pipe1_g,s_pipe1_b,s_pipe1_visible, s_pipe2_r,s_pipe2_g,s_pipe2_b,s_pipe2_visible,
            s_pipe3_r,s_pipe3_g,s_pipe3_b,s_pipe3_visible)
        variable BG_R : std_logic_vector(3 downto 0) := "0000";
        variable BG_G : std_logic_vector(3 downto 0) := "0000";
        variable BG_B : std_logic_vector(3 downto 0) := "0000";
    begin
        -- Layers
        -- background
        s_final_r <= BG_R;
        s_final_g <= BG_G;
        s_final_b <= BG_B;

        -- ball
        if (s_bird_visible = '1') then
            s_final_r <= s_bird_r;
            s_final_g <= s_bird_g;
            s_final_b <= s_bird_b;
        end if;

        -- pipe1
        if (s_pipe1_visible = '1') then
            s_final_r <= s_pipe1_r;
            s_final_g <= s_pipe1_g;
            s_final_b <= s_pipe1_b;
        end if;

        -- pipe2
        if (s_pipe2_visible = '1') then
            s_final_r <= s_pipe2_r;
            s_final_g <= s_pipe2_g;
            s_final_b <= s_pipe2_b;
        end if;

        -- pipe3
        if (s_pipe3_visible = '1') then
            s_final_r <= s_pipe3_r;
            s_final_g <= s_pipe3_g;
            s_final_b <= s_pipe3_b;
        end if;

        -- text
        if (s_text_visible = '1') then
            s_final_r <= s_text_r;
            s_final_g <= s_text_g;
            s_final_b <= s_text_b;
        end if;
        
    end process;

    -- Final Assignment (no rgb as done by vga sync)
    VGA_VS <= s_VGA_VS;
    VGA_HS <= s_VGA_HS;

    -- text config
    --s_char_count <= 7 when KEY(0) = '1' else 5;
    --s_char <= char_scorehash when KEY(0) = '1' else -- 'SCORE #'
    --          char_hello; -- 'hello'
    --s_text_scale <= 1 when KEY(0) = '1' else 2;

    --s_text_origin_col <= "0000010100"; -- Column 20
    --s_text_origin_row <= "0000010100"; -- Row 20

    -- LEDR to represent game state
    with s_game_state select
        LEDR(9 downto 5) <= "00001" when start,
        "00010" when practice,
        "00100" when easy,
        "01000" when hard,
        "10000" when game_over,
        "00000" when others;

    LEDR(3) <= s_bird_collision;

    LEDR(2) <= KEY(0);

    -- mouse indicators
    LEDR(1) <= s_left_button;
    LEDR(0) <= s_right_button;

end architecture;