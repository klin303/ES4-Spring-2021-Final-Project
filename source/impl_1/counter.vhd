library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity counter is
	port(
		clk : in std_logic;
		counter_value : out unsigned(13 downto 0) := 14d"0"
	);
end;


architecture synth of counter is
begin
	process(clk)
	begin
		if rising_edge(clk) then counter_value <= counter_value + 1;
		end if;
	end process;
end;