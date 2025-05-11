library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity floppy_burt_top is
    port (
        RESET_N : in std_logic;
        CLOCK_50 : in std_logic;
        KEY : in std_logic_vector(3 downto 0);
        VGA_R, VGA_G, VGA_B : out std_logic_vector(3 downto 0);
        VGA_HS, VGA_VS : out std_logic
    );
end floppy_burt_top; 

configuration config of floppy_burt_top is
    for vga_test_renderer -- change to desired architecture
    end for;
end config;

architecture vga_test_ball of floppy_burt_top is

    component VGA_SYNC is
        port (
            clock_25Mhz : in STD_LOGIC; 
            red, green, blue : in STD_LOGIC_VECTOR(3 downto 0);
            red_out, green_out, blue_out : out STD_LOGIC_VECTOR(3 downto 0);
            horiz_sync_out, vert_sync_out : out STD_LOGIC;
            pixel_row, pixel_column: out STD_LOGIC_VECTOR(9 downto 0)
        );
    end component VGA_SYNC;

    component ball IS
        port (
            clk : in std_logic;
            pixel_row, pixel_column	: in std_logic_vector(9 downto 0);
            red, green, blue : out std_logic_vector(3 downto 0)
        );		
    end component ball;

    component pll25MHz is
        port (
            refclk   : in  std_logic := '0'; --  refclk.clk
            rst      : in  std_logic := '0'; --   reset.reset
            outclk_0 : out std_logic;        -- outclk0.clk
            locked   : out std_logic         --  locked.export
        );
    end component pll25MHz;

    -- INTERMEDIATE SIGNALS
    signal clock_25Mhz : std_logic;
    signal s_rst : std_logic; -- can link to board reset if want
    signal s_locked : std_logic; -- ? clock stability

    signal s_pix_row : std_logic_vector(9 downto 0);
    signal s_pix_col : std_logic_vector(9 downto 0);
    signal s_red : std_logic_vector(3 downto 0);
    signal s_green : std_logic_vector(3 downto 0);
    signal s_blue : std_logic_vector(3 downto 0);

    -- need to know fpga pin ports:
    -- for sync and colors

begin

    c1: pll25MHz
        port map (
            refclk => CLOCK_50,
            rst => s_rst,
            outclk_0 => clock_25Mhz,
            locked => s_locked
        );

    b1: ball
        port map (
            -- input
            clk => clock_25Mhz,
            pixel_row => s_pix_row,
            pixel_column => s_pix_col,
            -- output
            red => s_red,
            green => s_green,
            blue => s_blue
        );

    v1: VGA_SYNC
        port map (
            -- input
            clock_25Mhz => clock_25Mhz,
            red => s_red,
            green => s_green,
            blue => s_blue,
            -- output
            -- NOTE: might have to do a different approach for the color mapping - but just test it first
            -- if not working then just make it the entire stdlogicvector, but check ball to see if changes needed
            red_out => VGA_R, 
            green_out => VGA_G,
            blue_out => VGA_B,
            horiz_sync_out => VGA_HS,
            vert_sync_out => VGA_VS,
            pixel_row => s_pix_row, 
            pixel_column => s_pix_col
        );

end architecture;

architecture vga_test_bouncy of floppy_burt_top is

    component VGA_SYNC is
        port (
            clock_25Mhz : in STD_LOGIC; 
            red, green, blue : in STD_LOGIC_VECTOR(3 downto 0);
            red_out, green_out, blue_out : out STD_LOGIC_VECTOR(3 downto 0);
            horiz_sync_out, vert_sync_out : out STD_LOGIC;
            pixel_row, pixel_column: out STD_LOGIC_VECTOR(9 downto 0)
        );
    end component VGA_SYNC;

    component bouncy_ball is
	port ( 
		pb1, pb2, clk, vert_sync	: IN std_logic;
        pixel_row, pixel_column		: IN std_logic_vector(9 DOWNTO 0);
        red, green, blue 			: OUT std_logic_vector(3 downto 0)
	);		
    end component bouncy_ball;

    component pll25MHz is
        port (
            refclk   : in  std_logic := '0'; --  refclk.clk
            rst      : in  std_logic := '0'; --   reset.reset
            outclk_0 : out std_logic;        -- outclk0.clk
            locked   : out std_logic         --  locked.export
        );
    end component pll25MHz;

    -- INTERMEDIATE SIGNALS
    signal clock_25Mhz : std_logic;
    signal s_rst : std_logic; -- can link to board reset if want
    signal s_locked : std_logic; -- ? clock stability

    signal s_VGA_VS : std_logic;
    signal s_VGA_HS : std_logic;
    signal s_pix_row : std_logic_vector(9 downto 0);
    signal s_pix_col : std_logic_vector(9 downto 0);
    signal s_red : std_logic_vector(3 downto 0);
    signal s_green : std_logic_vector(3 downto 0);
    signal s_blue : std_logic_vector(3 downto 0);

    -- need to know fpga pin ports:
    -- for sync and colors

begin

    c1: pll25MHz
        port map (
            refclk => CLOCK_50,
            rst => s_rst,
            outclk_0 => clock_25Mhz,
            locked => s_locked
        );

    b1: bouncy_ball
        port map (
            -- input
            pb1 => KEY(0), -- pushbutton
            pb2 => KEY(1),
            clk => clock_25Mhz,
            vert_sync => s_VGA_VS,

            pixel_row => s_pix_row,
            pixel_column => s_pix_col,
            -- output
            red => s_red,
            green => s_green,
            blue => s_blue
        );

    v1: VGA_SYNC
        port map (
            -- input
            clock_25Mhz => clock_25Mhz,
            red => s_red,
            green => s_green,
            blue => s_blue,
            -- output
            red_out => VGA_R, 
            green_out => VGA_G,
            blue_out => VGA_B,
            horiz_sync_out => s_VGA_HS,
            vert_sync_out => s_VGA_VS,
            pixel_row => s_pix_row, 
            pixel_column => s_pix_col
        );

    -- rendering logic wants syncing (bouncy ball)
    VGA_VS <= s_VGA_VS;
    VGA_HS <= s_VGA_HS;

end architecture;

architecture vga_test_renderer of floppy_burt_top is
    component VGA_SYNC is
        port (
            clock_25Mhz : in STD_LOGIC; 
            red, green, blue : in STD_LOGIC_VECTOR(3 downto 0);
            red_out, green_out, blue_out : out STD_LOGIC_VECTOR(3 downto 0);
            horiz_sync_out, vert_sync_out : out STD_LOGIC;
            pixel_row, pixel_column: out STD_LOGIC_VECTOR(9 downto 0)
        );
    end component VGA_SYNC;
    component ball_renderer IS
        port (
            pixel_row, pixel_column	: in std_logic_vector(9 downto 0);
            ball_visible : OUT std_logic;
            red, green, blue : out std_logic_vector(3 downto 0)
        );		
    end component ball_renderer;
    component text_renderer IS
	PORT ( 
        clk                         : IN std_logic;
        char_address                : IN std_logic_vector(5 downto 0);
		current_row, current_col	: IN std_logic_vector(9 DOWNTO 0);
        text_origin_col, text_origin_row : IN std_logic_vector(9 DOWNTO 0);
        text_visible : OUT std_logic;
		red, green, blue : OUT std_logic_vector(3 downto 0)
	);		
    END component text_renderer;
    component pll25MHz is
        port (
            refclk   : in  std_logic := '0'; --  refclk.clk
            rst      : in  std_logic := '0'; --   reset.reset
            outclk_0 : out std_logic;        -- outclk0.clk
            locked   : out std_logic         --  locked.export
        );
    end component pll25MHz;

    -- ===== INTERMEDIATE SIGNALS =====
    -- pll
    signal clock_25Mhz, s_locked, s_rst : std_logic;

    -- ball renderer
    signal s_ball_visible : std_logic;
    signal s_ball_r, s_ball_g, s_ball_b : std_logic_vector(3 downto 0);

    -- text
    signal s_char : std_logic_vector(5 downto 0);
    signal s_text_r, s_text_g, s_text_b : std_logic_vector(3 downto 0);
    signal s_text_visible : std_logic;
    signal s_text_origin_col, s_text_origin_row : std_logic_vector(9 downto 0);

    -- full renderer
    signal s_final_r, s_final_g, s_final_b : std_logic_vector(3 downto 0);
    signal s_pix_row, s_pix_col : std_logic_vector(9 downto 0);

    signal s_VGA_VS, s_VGA_HS : std_logic;
    
begin

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

    b1: ball_renderer
        port map (
            -- input
            pixel_row => s_pix_row,
            pixel_column => s_pix_col,
            -- output
            ball_visible => s_ball_visible,
            red => s_ball_r,
            green => s_ball_g,
            blue => s_ball_b
        );

    t1: text_renderer
        port map (
            -- input
            clk => clock_25Mhz,
            char_address => s_char,
            current_row => s_pix_row,
            current_col => s_pix_col,
            text_origin_col => s_text_origin_col,
            text_origin_row => s_text_origin_row,
            -- output
            text_visible => s_text_visible,
            red => s_text_r,
            green => s_text_g,
            blue => s_text_b
        );
    
    -- ======= RENDERER =======

    process(s_ball_r,s_ball_g,s_ball_b,s_ball_visible,s_text_r,s_text_g,s_text_b,s_text_visible)
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
        if (s_ball_visible = '1') then
            s_final_r <= s_ball_r;
            s_final_g <= s_ball_g;
            s_final_b <= s_ball_b;
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

    s_char <= "000001"; -- 'A'
    s_text_origin_col <= "0000010100"; -- Column 20
    s_text_origin_row <= "0000010100"; -- Row 20

end architecture;