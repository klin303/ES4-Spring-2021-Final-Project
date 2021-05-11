library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity top is
	port(
		fpga_clock : in std_logic;
		data_in : in std_logic;
		acknowledge_in : in std_logic;
		--input : in std_logic_vector (7 downto 0);
		rgb : out std_logic_vector(5 downto 0);
		clock_out : out std_logic;
		attention_out : out std_logic;
		command_out : out std_logic;
		vsync : out std_logic;
		hsync : out std_logic
	);
end top;

architecture synth of top is
	component pll_1 is
		port(
			ref_clk_i: in std_logic;
			rst_n_i: in std_logic;
			outcore_o: out std_logic;
			outglobal_o: out std_logic
		);
	end component;
	
	component vga is 
		port(
			clk : in std_logic;
			column : out unsigned (9 downto 0);
			rows : out unsigned (9 downto 0);
			hsync : out std_logic;
			vsync : out std_logic
		);
	end component;
	
	component controller is
	  port(
		  buttons : out std_logic_vector(4 downto 0) := 5d"0";
		  data : in std_logic; --Controller to PSX.
		  command : out std_logic; --PSX to controller 
		  attention : out std_logic;
		  acknowledge : in std_logic; --Controller to PSX. Drive low once after each byte.
		  clock : out std_logic
	  );
	end component;
	
	component game is 
		port(
			clk : in std_logic;
			input : in std_logic_vector (4 downto 0);
			col : in unsigned (9 downto 0);
			row : in unsigned (9 downto 0);
			valid : in std_logic;
			rgb : out std_logic_vector(5 downto 0)
	);
	end component;


	signal temp_clock : std_logic;
	signal network_clock : std_logic;
	signal sig_out : std_logic := '0';
	
	signal button_output : std_logic_vector(4 downto 0);
	
	signal col_out : unsigned (9 downto 0);
	signal row_out : unsigned (9 downto 0);
	signal visible : std_logic;
	
begin
	pll : pll_1 port map(fpga_clock , '1', temp_clock, network_clock);
	disp : vga port map(clk => network_clock, column => col_out, rows => row_out, hsync => hsync, vsync => vsync);
	
	visible <= '1' when col_out < 640 and row_out < 480 else '0';
	
	control : controller port map(buttons => button_output, data => data_in, command => command_out, attention => attention_out, acknowledge => acknowledge_in, clock => clock_out);
	
	color : game port map(clk => fpga_clock, input => button_output, col => col_out, row => row_out, valid => visible, rgb => rgb);
	
end;
