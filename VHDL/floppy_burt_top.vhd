library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity floppy_burt_top is
    port (
        CLOCK_50 : in std_logic;
        KEY : in std_logic_vector(3 downto 0);
        SW : in std_logic_vector(9 downto 0);
        HEX0, HEX1, HEX2, HEX3 : out std_logic_vector(6 downto 0);
        VGA_R, VGA_G, VGA_B : out std_logic_vector(3 downto 0);
        VGA_HS, VGA_VS : out std_logic;
        LEDR : out std_logic_vector(9 downto 0);
        PS2_CLK : INOUT std_logic;
        PS2_DAT : INOUT std_logic
    );
end floppy_burt_top; 

configuration config of floppy_burt_top is
    for seven_seg_test -- change to desired architecture
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

architecture mouse_dev of floppy_burt_top is

    component pll25MHz is
        port (
            refclk   : in  std_logic := '0'; -- refclk.clk
            rst      : in  std_logic := '0'; -- reset.reset
            outclk_0 : out std_logic;        -- outclk0.clk
            locked   : out std_logic         -- locked.export
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

    -- INTERMEDIATE SIGNALS
    signal clock_25Mhz                  : std_logic;
    signal s_locked                     : std_logic;
    signal s_rst 		        	    : std_logic := '0'; 
    signal s_left_button                : std_logic;
    signal s_right_button	            : std_logic;
    signal s_mouse_cursor_row 			: std_logic_vector(9 DOWNTO 0); 
    signal s_mouse_cursor_column 		: std_logic_vector(9 DOWNTO 0); 

begin
    
    c1: pll25MHz
    port map (
        refclk => CLOCK_50,
        rst => s_rst,
        outclk_0 => clock_25Mhz,
        locked => s_locked
    );

    m1: mouse
    port map (
        clock_25Mhz => clock_25Mhz,
        reset => s_rst,
        mouse_data => PS2_DAT,
        mouse_clk => PS2_CLK,
        left_button => LEDR(1),
        right_button => LEDR(0),
        mouse_cursor_row => s_mouse_cursor_row,
        mouse_cursor_column => s_mouse_cursor_column
    );

end architecture;

architecture seven_seg_test of floppy_burt_top is

    component pll25MHz is
        port (
            refclk   : in  std_logic := '0'; -- refclk.clk
            rst      : in  std_logic := '0'; -- reset.reset
            outclk_0 : out std_logic;        -- outclk0.clk
            locked   : out std_logic         -- locked.export
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

    component display_7seg is
        port (
            clk_25MHz, reset    : in std_logic;
            mouse_cursor_row    : in std_logic_vector(9 downto 0);
            mouse_cursor_column : in std_logic_vector(9 downto 0);
            mouse_dir_toggle    : in std_logic;
            seven_seg_out       : out std_logic_vector(6 downto 0)
        );
    end component display_7seg;

    -- INTERMEDIATE SIGNALS
    signal clock_25Mhz                  : std_logic;
    signal s_locked                     : std_logic;
    signal s_rst 		        	    : std_logic := '0'; 
    signal s_left_button                : std_logic;
    signal s_right_button	            : std_logic;
    signal s_mouse_cursor_row 			: std_logic_vector(9 DOWNTO 0); 
    signal s_mouse_cursor_column 		: std_logic_vector(9 DOWNTO 0);

begin
    
    c1: pll25MHz
    port map (
        refclk => CLOCK_50,
        rst => s_rst,
        outclk_0 => clock_25Mhz,
        locked => s_locked
    );

    m1: mouse
    port map (
        clock_25Mhz => clock_25Mhz,
        reset => s_rst,
        mouse_data => PS2_DAT,
        mouse_clk => PS2_CLK,
        left_button => LEDR(1),
        right_button => LEDR(0),
        mouse_cursor_row => s_mouse_cursor_row,
        mouse_cursor_column => s_mouse_cursor_column
    );

    d1: display_7seg
    port map (
        clk_25MHz => clock_25Mhz,
        reset => s_rst,
        mouse_cursor_row => s_mouse_cursor_row,
        mouse_cursor_column => s_mouse_cursor_column,
        mouse_dir_toggle => SW(0),
        seven_seg_out => HEX0
    );

end seven_seg_test;