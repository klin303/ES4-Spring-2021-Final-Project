library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity vga is 
	port(
		clk : in std_logic;
		column : out unsigned (9 downto 0);
		rows : out unsigned (9 downto 0);
		hsync : out std_logic;
		vsync : out std_logic
	);
end vga;

architecture synth of vga is
	
	signal col_count : unsigned (9 downto 0) := 10d"0";
	signal row_count : unsigned (9 downto 0) := 10d"0";
	
	begin
		process (clk) is
		begin
			if rising_edge(clk) then
				if col_count = 10d"799" then
					if row_count = 10d"524" then
						row_count <= 10d"0";
					else
						row_count <= row_count + 10d"1";
					end if;
					col_count <= 10d"0";
				else
					col_count <= col_count + 10d"1";
				end if;
			end if;
		end process;
		
		--hsync <= '1' when col_count > 95 else '0';
		--vsync <= '1' when row_count > 1 else '0';
		hsync <= '1' when col_count < 656 or col_count >= 752 else '0'; -- or 752
		vsync <= '1' when row_count < 490 or row_count >= 492 else '0'; -- or 492
		
		column <= col_count;
		rows <= row_count;
			   
end;