library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity controller is
  port(
	  buttons : out std_logic_vector(4 downto 0) := 5d"0";
	  data : in std_logic; --Controller to PSX.
	  command : out std_logic; --PSX to controller 
	  attention : out std_logic;
	  acknowledge : in std_logic; --Controller to PSX. Drive low once after each byte.
	  clock : out std_logic
  );
end controller;


architecture synth of controller is
	component HSOSC is
		generic (
			CLKHF_DIV : String := "0b00"
		);
		port(
			CLKHFPU : in std_logic := 'X';
			CLKHFEN : in std_logic := 'X';
			CLKHF : out std_logic := 'X'
		);
	end component;

	component counter is
	port(
		clk : in std_logic;
		counter_value : out unsigned(13 downto 0) := 14d"0"
	);
	end component;

	signal clk_wire : std_logic;
	signal counter_out : unsigned(13 downto 0);
	signal PS_clk : std_logic;
	signal PS_count : unsigned(3 downto 0);
	signal inputs_register : std_logic_vector(7 downto 0);
	signal byte_count : unsigned(2 downto 0) := "000";
	signal data_register : std_logic_vector(15 downto 0) := 16d"0";
	
	
	type State is (BYTE_1, BYTE_2, ZERO);
	signal command_state : State;
	signal command_sig : unsigned(7 downto 0) := 8d"0";
	
begin
	
	clk_inst : HSOSC port map(CLKHFPU => '1', CLKHFEN => '1', CLKHF => clk_wire);
	counter_inst : counter port map(clk => clk_wire, counter_value => counter_out);
	PS_clk <= counter_out(9);
	PS_count <= counter_out(13 downto 10);
	attention <= '0' when (byte_count < 7d"5") else '1';
	clock <= '0' when (PS_clk = '0') and (PS_count < 8) and (attention = '0') 
				else '1';
	command <= '1' when (PS_count = 0) and (byte_count = 0) else
				'0' when (byte_count = 0) else
				'0' when (PS_count = 0) and (byte_count = 1) else
				'1' when (PS_count = 1) and (byte_count = 1) else
				'0' when (PS_count < 6) and (byte_count = 1) else
				'1' when (PS_count = 6) and (byte_count = 1) else
				'0' when (PS_count = 7) and (byte_count = 1) else
				'0';
	process (clock, PS_clk)
	begin
		if rising_edge(clock)  then
			data_register <= data_register(14 downto 0) & data;
		end if;
		if rising_edge(PS_clk) then
			if (byte_count = 5) and (PS_count = 0) then
					buttons <= (not data_register(11)) & (not data_register(10)) & (not data_register(9)) & (not data_register(8)) & (not data_register(12));
			end if;
			if (PS_count = 7) then
				byte_count <= byte_count + 1;
				
			end if;
		end if;
	end process;
	
end;

