-- note bgs are all 256x192
-- therefore 8bit x 8bit

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE  IEEE.STD_LOGIC_ARITH.all;
USE  IEEE.STD_LOGIC_UNSIGNED.all;

ENTITY bg_renderer IS
	PORT ( 
        clock                       : IN std_logic;
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
		q		: OUT STD_LOGIC_VECTOR (11 DOWNTO 0)
	);
    end component foreground1_rom;

    signal s_row_scaled : std_logic_vector(7 downto 0);
    signal s_col_scaled : std_logic_vector(7 downto 0);
BEGIN           
    bg1: foreground1_rom
        port map (
            -- in
            address(15 downto 8) => s_row_scaled,
            address(7 downto 0) => s_col_scaled,
            clock => clock,
            -- out
            q(11 downto 8) => red,
            q(7 downto 4) => green,
            q(3 downto 0) => blue
        );

        -- 640x480 to 256x192 is 2.5 scaling
         s_row_scaled <= conv_std_logic_vector((conv_integer(current_row) * 2) / 5, 8);
         s_col_scaled <= conv_std_logic_vector((conv_integer(current_col) * 2) / 5, 8);
    
END behaviour;

