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

    component sand_rom IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		clock		: IN STD_LOGIC;
		q		    : OUT STD_LOGIC_VECTOR (11 DOWNTO 0)
	);
    END component sand_rom;

    component far_rom IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		: IN STD_LOGIC;
		q		    : OUT STD_LOGIC_VECTOR (11 DOWNTO 0)
	);
    END component far_rom;

    -- intermediate signals
    signal s_col_scaled : std_logic_vector(7 downto 0);
    signal s_row_scaled : std_logic_vector(7 downto 0);

    -- foreground
    -- do bounds as double (account for both) foreground sprite sizes
    signal s_fg_offset : integer range 0 to 511;
    signal s_fg_pos_col : std_logic_vector(7 downto 0);
    signal s_fg_pos_row : std_logic_vector(7 downto 0);
    signal s_fg_r, s_fg_g, s_fg_b : std_logic_vector(3 downto 0);
    signal s_fg1_r, s_fg1_g, s_fg1_b : std_logic_vector(3 downto 0);
    signal s_fg2_r, s_fg2_g, s_fg2_b : std_logic_vector(3 downto 0);

    -- sand
    signal s_sand_offset : integer range 0 to 255;
    signal s_sand_pos_col : std_logic_vector(7 downto 0);
    signal s_sand_pos_row : std_logic_vector(7 downto 0);
    signal s_sand_r, s_sand_g, s_sand_b : std_logic_vector(3 downto 0);

    -- far bg
    signal s_far_pos_col : std_logic_vector(6 downto 0);
    signal s_far_pos_row : std_logic_vector(6 downto 0);
    signal s_far_r, s_far_g, s_far_b : std_logic_vector(3 downto 0);
    
BEGIN           
    bg1: foreground1_rom
        port map (
            -- in
            address(15 downto 8) => s_fg_pos_row,
            address(7 downto 0) => s_fg_pos_col,
            clock => clock,
            -- out
            q(11 downto 8) => s_fg1_r,
            q(7 downto 4) => s_fg1_g,
            q(3 downto 0) => s_fg1_b
        );

    bg2: foreground2_rom
        port map (
            -- in
            address(15 downto 8) => s_fg_pos_row,
            address(7 downto 0) => s_fg_pos_col,
            clock => clock,
            -- out
            q(11 downto 8) => s_fg2_r,
            q(7 downto 4) => s_fg2_g,
            q(3 downto 0) => s_fg2_b
        );

    sand: sand_rom
        port map (
            -- in
            address(15 downto 8) => s_sand_pos_row,
            address(7 downto 0) => s_sand_pos_col,
            clock => clock,
            -- out
            q(11 downto 8) => s_sand_r,
            q(7 downto 4) => s_sand_g,
            q(3 downto 0) => s_sand_b
        );

    far: far_rom
        port map (
            -- in
            address(13 downto 7) => s_far_pos_row,
            address(6 downto 0) => s_far_pos_col,
            clock => clock,
            -- out
            q(11 downto 8) => s_far_r,
            q(7 downto 4) => s_far_g,
            q(3 downto 0) => s_far_b
        );

    -- 640x480 to 256x192 is 2.5 scaling
    -- pixel position assignments
    s_col_scaled <= std_logic_vector(to_unsigned((to_integer(unsigned(current_col)) * 2)/5, s_col_scaled'length));
    s_row_scaled <= std_logic_vector(to_unsigned((to_integer(unsigned(current_row)) * 2)/5, s_row_scaled'length));

    s_fg_pos_row <= s_row_scaled;
    -- so many problems with this line, next time just do steps one by one - resize just cause addition can overflow techinally
    s_fg_pos_col <= std_logic_vector(resize(unsigned(to_unsigned(s_fg_offset mod 256, 8)) + unsigned(s_col_scaled), s_fg_pos_col'length));

    -- but can just copy now cuz work lel
    s_sand_pos_row <= s_row_scaled;
    s_sand_pos_col <= std_logic_vector(resize(unsigned(to_unsigned(s_sand_offset, 8)) + unsigned(s_col_scaled), s_sand_pos_col'length));

    s_far_pos_row <= std_logic_vector(to_unsigned(to_integer(unsigned(current_row))/5, s_far_pos_row'length));
    s_far_pos_col <= std_logic_vector(to_unsigned(to_integer(unsigned(current_col))/5, s_far_pos_col'length));

    -- moving incrememnt
    process(vsync)
    begin
        if(rising_edge(vsync)) then
            -- 2 is hella fast - need to do counter likely
            s_fg_offset <= (s_fg_offset + 2) mod 512;
            s_sand_offset <= (s_sand_offset + 1) mod 256;
        end if;
    end process;

    -- foreground sprite switching
    -- fix wraparound being the same foregound - consider positioning for it too
    process(s_fg_offset, s_col_scaled)
        variable v_select_fg : integer;
    begin
        v_select_fg := s_fg_offset / 256;

        -- fg1 condition
        if (v_select_fg = 0) then -- fg1
            s_fg_r <= s_fg1_r;
            s_fg_g <= s_fg1_g;
            s_fg_b <= s_fg1_b;
        end if;

        -- fg1 wrap condition to fg2
        if (v_select_fg = 0 and to_integer(unsigned(s_col_scaled)) >= (256 - s_fg_offset)) then -- fg2
            s_fg_r <= s_fg2_r;
            s_fg_g <= s_fg2_g;
            s_fg_b <= s_fg2_b;
        end if;

        -- fg2 condition
        if (v_select_fg = 1) then -- fg2
            s_fg_r <= s_fg2_r;
            s_fg_g <= s_fg2_g;
            s_fg_b <= s_fg2_b;
        end if;

        -- fg2 wrap condition to fg1
        if (v_select_fg = 1 and to_integer(unsigned(s_col_scaled)) >= (256 - (s_fg_offset mod 256))) then -- fg1
            s_fg_r <= s_fg1_r;
            s_fg_g <= s_fg1_g;
            s_fg_b <= s_fg1_b;
        end if;
    end process;

    -- rendering layering
    process(s_fg_r, s_fg_g, s_fg_b,
            s_sand_r, s_sand_g, s_sand_b,
            s_far_r, s_far_g, s_far_b)

        variable v_fg_visibility : std_logic;
        variable v_sand_visibility : std_logic;
    begin
        -- can do visibility flags based on color content - (0,0,0)
        -- remember variables cant do "when"
        if (s_fg_r = "0000" and s_fg_g = "0000" and s_fg_b = "0000") then
            v_fg_visibility := '0';
        else
            v_fg_visibility := '1';
        end if;

        if (s_sand_r = "0000" and s_sand_g = "0000" and s_sand_b = "0000") then
            v_sand_visibility := '0';
        else
            v_sand_visibility := '1';
        end if;

        red <= s_far_r;
        green <= s_far_g;
        blue <= s_far_b;

        if (v_sand_visibility = '1') then
            red <= s_sand_r;
            green <= s_sand_g;
            blue <= s_sand_b;
        end if;

        if (v_fg_visibility = '1') then
            red <= s_fg_r;
            green <= s_fg_g;
            blue <= s_fg_b;
        end if;
    end process;

END behaviour;

