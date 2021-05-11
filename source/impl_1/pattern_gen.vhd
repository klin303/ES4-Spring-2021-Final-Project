library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;

entity game is 
	port(
		clk : in std_logic;
		input : in std_logic_vector (4 downto 0);
		col : in unsigned (9 downto 0);
		row : in unsigned (9 downto 0);
		valid : in std_logic;
		rgb : out std_logic_vector(5 downto 0) := "000000"
	);
end game;


architecture synth of game is
	
	signal output : std_logic_vector(5 downto 0) := "000000";
	
	-- FROG
	-- player input clock
	signal frog_clk_counter: integer := 1;
	signal frog_clk_tmp : std_logic := '0';
	signal frog_clock : std_logic;
	
	-- frog display signals
	signal is_frog : std_logic;
	signal is_frow : std_logic;
	signal is_fcol : std_logic;
	
	signal input_high : std_logic;
	signal mov_left : std_logic;
	signal mov_up : std_logic;
	signal mov_right : std_logic;
	signal mov_down : std_logic;
	signal reset : std_logic;
	
	signal frog_row : unsigned (9 downto 0) := 10d"10";
	signal frog_col : unsigned (9 downto 0) := 10d"7";
	
	--GAME
	-- game control signals
	signal is_safe : std_logic;
	signal is_safe_zone : std_logic;
	signal levels_passed : unsigned (9 downto 0) := 10d"0";
	signal is_alive : std_logic := '1';
	
	-- game state vars
	signal is_menu : std_logic;
	signal restart : std_logic;
	type game_state_t is (pregame, new_level, running, over);
	signal game_state : game_state_t := new_level;
	signal frog_reset : std_logic;
	
	-- car movement clock signals
	signal car_clk_counter: integer := 1;
	signal car_clk_tmp : std_logic := '0';
	signal car_clock : std_logic;
	signal car_speed : integer;
	
	
	-- car print signals
	signal is_car : std_logic;
	signal car_row : integer;
	signal car_col : integer;
	signal is_divider : std_logic;
	
	-- default car board for start of the game
	signal car_temp : std_logic := '0';
	type t_Row_Col is array (0 to 11) of std_logic_vector(0 to 31);
	signal default_board : t_Row_Col := ("00000000000000000000000000000000",
										 "00000000111000000000000000111000",		
										 "11100000000011100000000000000000",				 
										 "11000000111000000000000000000001",												 
										 "00000000000001110000000000000000",				
										 "00011100000000000011100000000000",
										 "00011100000111000000000000011100",			
										 "10000111000000000000000111000011",											
										 "00000111000000000000000001110000",			
										 "00011100000000001110000000000000",			
										 "00000000000111000011100001110000",			
										 "00000000000000000000000000000000");	
	
	signal board_direction : std_logic_vector(0 to 11) := ("010101010101");
	signal actual_board : t_Row_Col;
	signal temp_board: t_Row_Col;
	signal temp: std_logic;
	signal board_reset : std_logic := '1';
	
	begin
		-- GAME STATE
		game_state_process : process (clk) is begin
			
			restart <= input(0); --reset button
			
			if rising_edge(clk) then
			  case game_state is
				when pregame =>
					levels_passed <= 10d"0";
					board_reset <= '1';
					if (actual_board(2)(0) = '1') then
						game_state <= new_level;
					end if;
					
				when new_level =>
					frog_reset <= '1';
					
					if (input(4) = '0') then
						if (frog_col = 7 and frog_row = 11) then
							board_reset <= '0';
							is_menu <= '0';
							game_state <= running;
						end if;
					end if;
				when running =>
					frog_reset <= '0';
					board_reset <= '0';
					if (is_alive = '0') then
						game_state <= over;
					elsif (is_safe = '1') then
						levels_passed <= levels_passed + 10d"1";
						game_state <= new_level;
					end if;
		 
				when over =>
					is_menu <= '1';
					if (restart = '1') then
						game_state <= pregame;
					end if;
					
				when others =>
				  game_state <= over;
				   
			  end case;
			end if;
		end process game_state_process;
		
		---------------------------------------------------------------------------------------------
		
		--FREQUENCY DIVIDER FOR FROG CONTROL
		frog_clock_divider : process(clk,reset)
		begin
			if(rising_edge(clk)) then
				frog_clk_counter <=frog_clk_counter+1;
				if (frog_clk_counter = 3000000) then
					frog_clk_tmp <= NOT frog_clk_tmp;
					frog_clk_counter <= 1;
				end if;
			end if;
			
		end process frog_clock_divider;
		frog_clock <= frog_clk_tmp;
		
		--PLAYER INPUT
		player_input : process (frog_clock, input) begin
			mov_left <= input(1); -- translate input to directions
			mov_up <= input(4);
			mov_right <= input(3);
			mov_down <= input(2);
			
			
			-- only allow one input at a time
			input_high <= '1' when mov_up xor mov_left xor mov_right xor mov_down else '0';

			if rising_edge(frog_clock) then
				if (frog_reset = '1') then
					frog_col <= 10d"7"; -- starting pos in middle of bottom row
					frog_row <= 10d"11";
				elsif (mov_left = '1' and input_high = '1') then
					if frog_col > 0 then -- do not move if on edge
					  frog_col <= frog_col - 10d"1";
					end if;
				elsif (mov_right = '1' and input_high = '1') then
					if frog_col < 14 then
					  frog_col <= frog_col + 10d"1";
					end if;
				elsif (mov_up = '1' and input_high = '1') then
					if frog_row > 0 then
						frog_row <= frog_row - 10d"1";
					end if;
				elsif (mov_down = '1' and input_high = '1') then 
					if frog_row < 11 then
						frog_row <= frog_row + 10d"1";
					end if;
				end if;
			end if;
		end process player_input;
		
		----------------------------------------------------------------------------------------
		-- FREQUENCY DIVIDER FOR CARS
		car_clock_divider : process(clk) begin
			
			car_speed <= 4500000;
			if(rising_edge(clk)) then
				car_clk_counter <= car_clk_counter + 1;
				if (car_clk_counter = car_speed) then
					car_clk_tmp <= NOT car_clk_tmp;
					car_clk_counter <= 1;
				end if;
			end if;
			
		end process car_clock_divider;
		car_clock <= car_clk_tmp;
		
		move_cars : process (car_clock) begin

			if (rising_edge(car_clock)) then
				if (board_reset = '1') then
					temp_board <= default_board;
				else

					temp_board(1) <= actual_board(1)(31) & actual_board(1)(0 to 30);	
					temp_board(2) <= actual_board(2)(1 to 31) & actual_board(2)(0);	
					temp_board(3) <= actual_board(3)(31) & actual_board(3)(0 to 30);	
					temp_board(4) <= actual_board(4)(1 to 31) & actual_board(4)(0);	
					temp_board(5) <= actual_board(5)(31) & actual_board(5)(0 to 30);	
					temp_board(6) <= actual_board(6)(1 to 31) & actual_board(6)(0);	
					temp_board(7) <= actual_board(7)(31) & actual_board(7)(0 to 30);	
					temp_board(8) <= actual_board(8)(1 to 31) & actual_board(9)(0);	
					temp_board(9) <= actual_board(9)(31) & actual_board(9)(0 to 30);	
					temp_board(10) <= actual_board(10)(1 to 31) & actual_board(10)(0);	
					
				end if;
			end if;
		end process move_cars;
		actual_board <= temp_board;
		------------------------------------------------------------------
		-- get position of cars on the board
		car_row <= to_integer(row) / 4 / 5 / 2;
		car_col <= to_integer(col) / 4 / 5;
		is_car <= actual_board(car_row)(car_col);
		
		-- determine when to print the frog based on the frog's row and col pos
		is_frow <= '1' when row >= (frog_row * 10d"40") and row < (frog_row * 10d"40" + 10d"40") else '0';
		is_fcol <= '1' when (col >= (frog_col * 10d"40" + 10d"15")) and (col <= (frog_col * 10d"40" + 10d"55")) else '0';
		is_frog <= '1' when (is_frow and is_fcol) else '0';
			
		-- define safe zone
		is_safe_zone <= '1' when (row < 40 or row >= 440) else '0';
		is_safe <= '1' when frog_row = 0 else '0';
		
		-- define divider
		is_divider <= '1' when (row >= 40 and row < 45) or (row > 75 and row < 85) or (row > 115 and row < 125) or (row > 155 and row < 165) or 
							   (row > 195 and row < 205) or (row > 235 and row < 245) or (row > 275 and row < 285) or (row > 315 and row < 325) or 
							   (row > 355 and row < 365) or (row > 395 and row < 405) or (row > 435 and row < 440) else '0';
		
		-- check collisions between the cars and the frog
		check_collision : process(car_clock) begin
			if(rising_edge(car_clock)) then
				is_alive <= '0' when actual_board(to_integer(frog_row))(to_integer(frog_col) * 2) = '1' or actual_board(to_integer(frog_row))(to_integer(frog_col) * 2 + 1) = '1' or
									 actual_board(to_integer(frog_row))(to_integer(frog_col) * 2 + 2) = '1' or actual_board(to_integer(frog_row))(to_integer(frog_col) * 2 + 3) = '1' else '1';
			end if;
		end process check_collision;
		
		-- final output
		output <= "110000" when is_menu else
				  "001100" when is_frog else
				  "111111" when is_divider else
				  "000011" when is_car else
				  "110111" when is_safe_zone else
				  "111111";
		
		rgb <= output when valid = '1' else "000000";
		
end;