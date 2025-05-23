-- note bgs are all 256x192
-- therefore 8bit x 8bit

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;
-- use IEEE.STD_LOGIC_ARITH.all;

ENTITY bg_renderer IS
	PORT ( 
        vsync, clock                : IN std_logic;
		current_row, current_col	: IN std_logic_vector(9 DOWNTO 0); -- bgs only need 8bit but it alg
		red, green, blue            : OUT std_logic_vector(3 downto 0) -- 4bit color
	);		
END bg_renderer;

architecture behaviour of bg_renderer is
    -- rom declarations
    component foreground1_rom IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		clock		: IN STD_LOGIC;
		q		    : OUT STD_LOGIC_VECTOR (11 DOWNTO 0)
	);
    end component foreground1_rom;

    component foreground2_rom IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		clock		: IN STD_LOGIC;
		q		    : OUT STD_LOGIC_VECTOR (11 DOWNTO 0)
	);
    END component foreground2_rom;

    -- intermediate signals
    signal s_col_scaled : std_logic_vector(7 downto 0);
    signal s_row_scaled : std_logic_vector(7 downto 0);

    -- do bounds as double (account for both) foreground sprite sizes
    -- integer needs to be up to
    signal s_fg_offset : integer range 0 to 511;

    signal s_foreground_int_col : integer range 0 to 255;
    signal s_foreground_int_row : integer range 0 to 191;
    signal s_foreground_pos_col : std_logic_vector(7 downto 0);
    signal s_foreground_pos_row : std_logic_vector(7 downto 0);

    signal s_fg_r, s_fg_g, s_fg_b : std_logic_vector(3 downto 0);
    signal s_fg1_r, s_fg1_g, s_fg1_b : std_logic_vector(3 downto 0);
    signal s_fg2_r, s_fg2_g, s_fg2_b : std_logic_vector(3 downto 0);
    
BEGIN           
    bg1: foreground1_rom
        port map (
            -- in
            address(15 downto 8) => s_foreground_pos_row,
            address(7 downto 0) => s_foreground_pos_col,
            clock => clock,
            -- out
            q(11 downto 8) => s_fg1_r,
            q(7 downto 4) => s_fg1_g,
            q(3 downto 0) => s_fg1_b
        );

    bg2: foreground2_rom
        port map (
            -- in
            address(15 downto 8) => s_foreground_pos_row,
            address(7 downto 0) => s_foreground_pos_col,
            clock => clock,
            -- out
            q(11 downto 8) => s_fg2_r,
            q(7 downto 4) => s_fg2_g,
            q(3 downto 0) => s_fg2_b
        );

    -- 640x480 to 256x192 is 2.5 scaling
    s_col_scaled <= std_logic_vector(to_unsigned((to_integer(unsigned(current_col)) * 2)/5, s_col_scaled'length));
    s_row_scaled <= std_logic_vector(to_unsigned((to_integer(unsigned(current_row)) * 2)/5, s_row_scaled'length));

    s_foreground_pos_row <= s_row_scaled;
    -- so many problems with this line, next time just do steps one by one - resize just cause addition can overflow techinally
    s_foreground_pos_col <= std_logic_vector(resize(unsigned(to_unsigned(s_fg_offset mod 256, 8)) + unsigned(s_col_scaled), s_foreground_pos_col'length));

    process(vsync)
    begin
        if(rising_edge(vsync)) then
            -- 2 is hella fast - need to do counter likely
            s_fg_offset <= (s_fg_offset + 1) mod 512;
        end if;
    end process;

    process(s_fg_offset)
        variable v_select_fg : integer;
    begin
        v_select_fg := s_fg_offset / 256;

        if (v_select_fg = 0) then -- fg1
            s_fg_r <= s_fg1_r;
            s_fg_g <= s_fg1_g;
            s_fg_b <= s_fg1_b;
        end if;

        if (v_select_fg = 1) then -- fg2
            s_fg_r <= s_fg2_r;
            s_fg_g <= s_fg2_g;
            s_fg_b <= s_fg2_b;
        end if;
    end process;

    process(s_fg_r, s_fg_g, s_fg_b)
    begin
        -- rendering layering
        red <= s_fg_r;
        green <= s_fg_g;
        blue <= s_fg_b;

    end process;

END behaviour;

