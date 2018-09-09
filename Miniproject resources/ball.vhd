-- Ball Catcher Game
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
library lpm;
use lpm.lpm_components.all;
package de0core is
	component vga_sync
		port
		(
			clock_25Mhz, red, green, blue : in STD_LOGIC;
			red_out, green_out, blue_out : out STD_LOGIC;
			horiz_sync_out, vert_sync_out : out STD_LOGIC;
			pixel_row, pixel_column : out STD_LOGIC_VECTOR(9 downto 0));
	end component;
end de0core;

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_SIGNED.all;
library work;
use work.de0core.all;
entity ball is
	generic
	(
		ADDR_WIDTH : integer := 12;
		DATA_WIDTH : integer := 1);
	port
	(
		signal Clock						: in std_logic;
		signal SWITCH1, MODE 			: in std_logic;
		signal Game_Mode 					: in std_logic_vector(2 downto 0);
		signal mouse_col 					: in std_logic_vector(9 downto 0);
		signal Red, Green, Blue 		: out std_logic;
		signal Horiz_sync, Vert_sync  : out std_logic;
		signal timer 						: out integer range 0 to 100;
		signal full_score 				: out integer range 0 to 200);
end ball;
architecture behavior of ball is
	-- Video Display Signals
	signal Red_Data, Green_Data, Blue_Data, vert_sync_int, hort_sync_int,
	reset, Ball_on, Paddle_on, Direction, Ball_on_2, Ball_on_3, Pause 			: std_logic;
	signal rom_mux, rom_mux_2, rom_mux_3 													: std_logic;
	signal gameOver 																				: std_logic;
	signal temp_Game_Mode										 								: std_logic_vector(2 downto 0) := "000";
	signal Size, Paddle_Size, Paddle_Size_Y 												: std_logic_vector(9 downto 0);
	signal Ball_Y_motion, Ball_Y_motion_2, Ball_Y_motion_3 							: std_logic_vector(9 downto 0);
	signal Ball_X_motion, Ball_X_motion_2, Ball_X_motion_3 							: std_logic_vector(10 downto 0);
	signal Ball_Y_pos, Ball_Y_pos_2, Ball_Y_pos_3 										: std_logic_vector(9 downto 0);
	signal Ball_X_pos, Ball_X_pos_2, Ball_X_pos_3								 		: std_logic_vector(10 downto 0);
	signal pixel_row, pixel_column 															: std_logic_vector(9 downto 0);
	signal Paddle_X_motion 																		: std_logic_vector(10 downto 0);
	signal char_address, char_address_2, char_address_3 								: std_logic_vector(5 downto 0);
	signal score_ones, score_tens																: std_logic_vector(5 downto 0) := CONV_STD_LOGIC_VECTOR(48, 6);
	signal Paddle_Y_pos 																			: std_logic_vector(10 downto 0) := CONV_STD_LOGIC_VECTOR(460, 11);
	signal Paddle_X_pos 																			: std_logic_vector(10 downto 0) := CONV_STD_LOGIC_VECTOR(320, 11);
	signal sec_tens 																				: std_logic_vector(5 downto 0) := CONV_STD_LOGIC_VECTOR(53, 6);
	signal sec_ones 																				: std_logic_vector(5 downto 0) := CONV_STD_LOGIC_VECTOR(57, 6);
	signal Level 																					: std_logic_vector(5 downto 0) := CONV_STD_LOGIC_VECTOR(49, 6);
	signal counter 																				: integer range 0 to 28000000 := 0;
	signal full_score1 																			: integer range 0 to 200 := 0;
	signal timer1 																					: integer range 0 to 100 := 5;
	signal Speed 																					: integer range 0 to 10 := 2;
	signal X_pos, X_Pos_2, X_pos_3 															: std_LOGIC_VECTOR(10 downto 0);
	signal count 																					: std_logic_vector (10 downto 0) := "00100101010";
	signal count_2 																				: std_logic_vector (10 downto 0) := "00110011100"; --Initial value
	signal count_3 																				: std_logic_vector (10 downto 0) := "00001110110"; --Initial value
	signal countA, countB 																		: std_logic_vector (10 downto 0);
	signal SPEED1 																					: std_logic_vector(10 downto 0) := "00000000010";
	component char_rom is
		port
		(
			character_address : in STD_LOGIC_VECTOR (5 downto 0);
			font_row, font_col : in STD_LOGIC_VECTOR (2 downto 0);
			clock : in STD_LOGIC;
			rom_mux_output : out STD_LOGIC);
	end component;
begin
	CHAR_1 : char_rom
	port map
		(char_address, pixel_row (3 downto 1), pixel_column(3 downto 1), clock, rom_mux);
	CHAR_2 : char_rom
	port map
		(char_address_2, pixel_row (4 downto 2), pixel_column(4 downto 2), clock, rom_mux_2);
	CHAR_3 : char_rom
	port map
		(char_address_3, pixel_row (5 downto 3), pixel_column(5 downto 3), clock, rom_mux_3);
	SYNC : vga_sync
	port map
		(clock_25Mhz => clock,
		red => red_data, green => green_data, blue => blue_data,
		red_out => red, green_out => green, blue_out => blue,
		horiz_sync_out => horiz_sync, vert_sync_out => vert_sync_int,
		pixel_row => pixel_row, pixel_column => pixel_column);
	-- need internal copy of vert_sync to read
	vert_sync <= vert_sync_int;
	-- Colors for pixel data on video signal
	Red_Data <= (rom_mux) or (rom_mux_2) or (rom_mux_3);
	Green_Data <= ((Paddle_On) or (Ball_On) or (Ball_On_2));
	Blue_Data <= ((Paddle_On) or (Ball_On) or (Ball_On_3));
	Size <= CONV_STD_LOGIC_VECTOR(8, 10);
	Paddle_Size_Y <= CONV_STD_LOGIC_VECTOR(4, 10);
	
	RGB_Display_2 : process (pixel_row, pixel_column, Game_Mode)
	begin
		-- Display Ball Catcher Game Title
		if (Game_Mode = "000") then
			-- Text row of 128 to 159
			if (pixel_row >= CONV_STD_LOGIC_VECTOR(128, 10)) and (pixel_row <= CONV_STD_LOGIC_VECTOR(159, 10)) then
					--B
				if (pixel_column >= CONV_STD_LOGIC_VECTOR(224, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(255, 10)) then
					char_address_2 <= CONV_STD_LOGIC_VECTOR(2, 6);
					--A
				elsif (pixel_column >= CONV_STD_LOGIC_VECTOR(256, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(287, 10)) then
					char_address_2 <= CONV_STD_LOGIC_VECTOR(1, 6);
					--L
				elsif (pixel_column >= CONV_STD_LOGIC_VECTOR(288, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(319, 10)) then
					char_address_2 <= CONV_STD_LOGIC_VECTOR(12, 6);
					--L
				elsif (pixel_column >= CONV_STD_LOGIC_VECTOR(320, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(351, 10)) then
					char_address_2 <= CONV_STD_LOGIC_VECTOR(12, 6);
				else
					-- Space
					char_address_2 <= CONV_STD_LOGIC_VECTOR(32, 6);
				end if;
			-- Text row of 160 to 191
			elsif (pixel_row >= CONV_STD_LOGIC_VECTOR(160, 10)) and (pixel_row <= CONV_STD_LOGIC_VECTOR(191, 10)) then
					--C
				if (pixel_column >= CONV_STD_LOGIC_VECTOR(224, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(255, 10)) then
					char_address_2 <= CONV_STD_LOGIC_VECTOR(3, 6);
					--A
				elsif (pixel_column >= CONV_STD_LOGIC_VECTOR(256, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(287, 10)) then
					char_address_2 <= CONV_STD_LOGIC_VECTOR(1, 6);
					--T
				elsif (pixel_column >= CONV_STD_LOGIC_VECTOR(288, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(319, 10)) then
					char_address_2 <= CONV_STD_LOGIC_VECTOR(20, 6);
					--C
				elsif (pixel_column >= CONV_STD_LOGIC_VECTOR(320, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(351, 10)) then
					char_address_2 <= CONV_STD_LOGIC_VECTOR(3, 6);
					--H
				elsif (pixel_column >= CONV_STD_LOGIC_VECTOR(352, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(383, 10)) then
					char_address_2 <= CONV_STD_LOGIC_VECTOR(8, 6);
					--E
				elsif (pixel_column >= CONV_STD_LOGIC_VECTOR(384, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(415, 10)) then
					char_address_2 <= CONV_STD_LOGIC_VECTOR(5, 6);
					--R
				elsif (pixel_column >= CONV_STD_LOGIC_VECTOR(416, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(447, 10)) then
					char_address_2 <= CONV_STD_LOGIC_VECTOR(18, 6);
					-- Space
				else
					char_address_2 <= CONV_STD_LOGIC_VECTOR(32, 6);
				end if;
			-- Space
			else
				char_address_2 <= CONV_STD_LOGIC_VECTOR(32, 6);
			end if;
		-- Space
		else
			char_address_2 <= CONV_STD_LOGIC_VECTOR(32, 6);
		end if;
	end process;
	
	RGB_Display : process (pixel_column, pixel_row, Game_Mode, mode, score_tens, score_ones, sec_tens, sec_ones, level, size)
	begin
		if (Game_Mode = "000") then
			-- for arrow
			if (pixel_column >= CONV_STD_LOGIC_VECTOR(224, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(239, 10)) and
				(pixel_row >= CONV_STD_LOGIC_VECTOR(304, 10)) and (pixel_row <= CONV_STD_LOGIC_VECTOR(319, 10) and mode = '1') then
				char_address <= CONV_STD_LOGIC_VECTOR(41, 6);
			-- for arrow
			elsif (pixel_column >= CONV_STD_LOGIC_VECTOR(224, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(239, 10)) and
				(pixel_row >= CONV_STD_LOGIC_VECTOR(336, 10)) and (pixel_row <= CONV_STD_LOGIC_VECTOR(351, 10) and mode = '0') then
				char_address <= CONV_STD_LOGIC_VECTOR(41, 6);
			-- Text display for row 304 to 319
			elsif (pixel_row >= CONV_STD_LOGIC_VECTOR(304, 10)) and (pixel_row <= CONV_STD_LOGIC_VECTOR(319, 10)) then
				-- P
				if (pixel_column >= CONV_STD_LOGIC_VECTOR(240, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(255, 10)) then
					char_address <= CONV_STD_LOGIC_VECTOR(16, 6);
				-- L
				elsif (pixel_column >= CONV_STD_LOGIC_VECTOR(256, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(271, 10)) then
					char_address <= CONV_STD_LOGIC_VECTOR(12, 6);
				-- A
				elsif (pixel_column >= CONV_STD_LOGIC_VECTOR(272, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(287, 10)) then
					char_address <= CONV_STD_LOGIC_VECTOR(1, 6);
				-- Y
				elsif (pixel_column >= CONV_STD_LOGIC_VECTOR(288, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(303, 10)) then
					char_address <= CONV_STD_LOGIC_VECTOR(25, 6);
				-- space
				elsif (pixel_column >= CONV_STD_LOGIC_VECTOR(304, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(319, 10)) then
					char_address <= CONV_STD_LOGIC_VECTOR(32, 6);
				-- N
				elsif (pixel_column >= CONV_STD_LOGIC_VECTOR(320, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(335, 10)) then
					char_address <= CONV_STD_LOGIC_VECTOR(14, 6);
				-- O
				elsif (pixel_column >= CONV_STD_LOGIC_VECTOR(336, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(351, 10)) then
					char_address <= CONV_STD_LOGIC_VECTOR(15, 6);
				-- w
				elsif (pixel_column >= CONV_STD_LOGIC_VECTOR(352, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(367, 10)) then
					char_address <= CONV_STD_LOGIC_VECTOR(23, 6);
				-- space
				else
					char_address <= CONV_STD_LOGIC_VECTOR(32, 6);
				end if;
			-- Text display for row 336 to 351
			elsif (pixel_row >= CONV_STD_LOGIC_VECTOR(336, 10)) and (pixel_row <= CONV_STD_LOGIC_VECTOR(351, 10)) then
				-- T
				if (pixel_column >= CONV_STD_LOGIC_VECTOR(240, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(255, 10)) then
					char_address <= CONV_STD_LOGIC_VECTOR(20, 6);
				-- R
				elsif (pixel_column >= CONV_STD_LOGIC_VECTOR(256, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(271, 10)) then
					char_address <= CONV_STD_LOGIC_VECTOR(18, 6);
				-- A
				elsif (pixel_column >= CONV_STD_LOGIC_VECTOR(272, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(287, 10)) then
					char_address <= CONV_STD_LOGIC_VECTOR(1, 6);
				-- I
				elsif (pixel_column >= CONV_STD_LOGIC_VECTOR(288, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(303, 10)) then
					char_address <= CONV_STD_LOGIC_VECTOR(9, 6);
				-- N
				elsif (pixel_column >= CONV_STD_LOGIC_VECTOR(304, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(319, 10)) then
					char_address <= CONV_STD_LOGIC_VECTOR(14, 6);
				-- I
				elsif (pixel_column >= CONV_STD_LOGIC_VECTOR(320, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(335, 10)) then
					char_address <= CONV_STD_LOGIC_VECTOR(9, 6);
				-- N
				elsif (pixel_column >= CONV_STD_LOGIC_VECTOR(336, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(351, 10)) then
					char_address <= CONV_STD_LOGIC_VECTOR(14, 6);
				-- G
				elsif (pixel_column >= CONV_STD_LOGIC_VECTOR(352, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(367, 10)) then
					char_address <= CONV_STD_LOGIC_VECTOR(07, 6);
				-- Space
				elsif (pixel_column >= CONV_STD_LOGIC_VECTOR(368, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(383, 10)) then
					char_address <= CONV_STD_LOGIC_VECTOR(32, 6);
				-- M
				elsif (pixel_column >= CONV_STD_LOGIC_VECTOR(384, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(399, 10)) then
					char_address <= CONV_STD_LOGIC_VECTOR(13, 6);
				-- O
				elsif (pixel_column >= CONV_STD_LOGIC_VECTOR(400, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(415, 10)) then
					char_address <= CONV_STD_LOGIC_VECTOR(15, 6);
				-- D
				elsif (pixel_column >= CONV_STD_LOGIC_VECTOR(416, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(431, 10)) then
					char_address <= CONV_STD_LOGIC_VECTOR(04, 6);
				-- E
				elsif (pixel_column >= CONV_STD_LOGIC_VECTOR(432, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(447, 10)) then
					char_address <= CONV_STD_LOGIC_VECTOR(05, 6);
				-- Space
				else
					char_address <= CONV_STD_LOGIC_VECTOR(32, 6);
				end if;
			-- Space
			else
				char_address <= CONV_STD_LOGIC_VECTOR(32, 6);
			end if;
		-- Text display of score, time and level 1, 2 and 3
		elsif (Game_Mode = "001" or GAME_MODE = "010" or Game_Mode = "011") then
			-- S
			if (pixel_column >= CONV_STD_LOGIC_VECTOR(1, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(15, 10)) and
				(pixel_row >= CONV_STD_LOGIC_VECTOR(1, 10)) and (pixel_row <= CONV_STD_LOGIC_VECTOR(15, 10)) then
				char_address <= CONV_STD_LOGIC_VECTOR(19, 6);
			-- C
			elsif (pixel_column >= CONV_STD_LOGIC_VECTOR(16, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(31, 10)) and
				(pixel_row >= CONV_STD_LOGIC_VECTOR(1, 10)) and (pixel_row <= CONV_STD_LOGIC_VECTOR(15, 10)) then
				char_address <= CONV_STD_LOGIC_VECTOR(3, 6);
			-- O
			elsif (pixel_column >= CONV_STD_LOGIC_VECTOR(32, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(47, 10)) and
				(pixel_row >= CONV_STD_LOGIC_VECTOR(1, 10)) and (pixel_row <= CONV_STD_LOGIC_VECTOR(15, 10)) then
				char_address <= CONV_STD_LOGIC_VECTOR(15, 6);
			-- R
			elsif (pixel_column >= CONV_STD_LOGIC_VECTOR(48, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(63, 10)) and
				(pixel_row >= CONV_STD_LOGIC_VECTOR(1, 10)) and (pixel_row <= CONV_STD_LOGIC_VECTOR(15, 10)) then
				char_address <= CONV_STD_LOGIC_VECTOR(18, 6);
			-- E
			elsif (pixel_column >= CONV_STD_LOGIC_VECTOR(64, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(79, 10)) and
				(pixel_row >= CONV_STD_LOGIC_VECTOR(1, 10)) and (pixel_row <= CONV_STD_LOGIC_VECTOR(15, 10)) then
				char_address <= CONV_STD_LOGIC_VECTOR(05, 6);
			-- space
			elsif (pixel_column >= CONV_STD_LOGIC_VECTOR(80, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(95, 10)) and
				(pixel_row >= CONV_STD_LOGIC_VECTOR(1, 10)) and (pixel_row <= CONV_STD_LOGIC_VECTOR(15, 10)) then
				char_address <= CONV_STD_LOGIC_VECTOR(32, 6);
			-- score tens
			elsif (pixel_column >= CONV_STD_LOGIC_VECTOR(96, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(111, 10)) and
				(pixel_row >= CONV_STD_LOGIC_VECTOR(1, 10)) and (pixel_row <= CONV_STD_LOGIC_VECTOR(15, 10)) then
				char_address <= score_tens;
			-- score ones
			elsif (pixel_column >= CONV_STD_LOGIC_VECTOR(112, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(127, 10)) and
				(pixel_row >= CONV_STD_LOGIC_VECTOR(1, 10)) and (pixel_row <= CONV_STD_LOGIC_VECTOR(15, 10)) then
				char_address <= score_ones;
			-- T
			elsif (pixel_column >= CONV_STD_LOGIC_VECTOR(160, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(175, 10)) and
				(pixel_row >= CONV_STD_LOGIC_VECTOR(1, 10)) and (pixel_row <= CONV_STD_LOGIC_VECTOR(15, 10)) then
				char_address <= CONV_STD_LOGIC_VECTOR(20, 6);
			-- I
			elsif (pixel_column >= CONV_STD_LOGIC_VECTOR(176, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(191, 10)) and
				(pixel_row >= CONV_STD_LOGIC_VECTOR(1, 10)) and (pixel_row <= CONV_STD_LOGIC_VECTOR(15, 10)) then
				char_address <= CONV_STD_LOGIC_VECTOR(09, 6);
			-- M
			elsif (pixel_column >= CONV_STD_LOGIC_VECTOR(192, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(207, 10)) and
				(pixel_row >= CONV_STD_LOGIC_VECTOR(1, 10)) and (pixel_row <= CONV_STD_LOGIC_VECTOR(15, 10)) then
				char_address <= CONV_STD_LOGIC_VECTOR(13, 6);
			-- E
			elsif (pixel_column >= CONV_STD_LOGIC_VECTOR(208, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(223, 10)) and
				(pixel_row >= CONV_STD_LOGIC_VECTOR(1, 10)) and (pixel_row <= CONV_STD_LOGIC_VECTOR(15, 10)) then
				char_address <= CONV_STD_LOGIC_VECTOR(05, 6);
			-- Space
			elsif (pixel_column >= CONV_STD_LOGIC_VECTOR(224, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(239, 10)) and
				(pixel_row >= CONV_STD_LOGIC_VECTOR(1, 10)) and (pixel_row <= CONV_STD_LOGIC_VECTOR(15, 10)) then
				char_address <= CONV_STD_LOGIC_VECTOR(32, 6);
			-- SEC_TENS
			elsif (pixel_column >= CONV_STD_LOGIC_VECTOR(240, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(255, 10)) and
				(pixel_row >= CONV_STD_LOGIC_VECTOR(1, 10)) and (pixel_row <= CONV_STD_LOGIC_VECTOR(15, 10)) then
				char_address <= sec_tens;
			-- SEC_ONES
			elsif (pixel_column >= CONV_STD_LOGIC_VECTOR(256, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(271, 10)) and
				(pixel_row >= CONV_STD_LOGIC_VECTOR(1, 10)) and (pixel_row <= CONV_STD_LOGIC_VECTOR(15, 10)) then
				char_address <= sec_ones;
			-- L
			elsif (pixel_column >= CONV_STD_LOGIC_VECTOR(320, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(335, 10)) and
				(pixel_row >= CONV_STD_LOGIC_VECTOR(1, 10)) and (pixel_row <= CONV_STD_LOGIC_VECTOR(15, 10)) then
				char_address <= CONV_STD_LOGIC_VECTOR(12, 6);
			-- E
			elsif (pixel_column >= CONV_STD_LOGIC_VECTOR(336, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(351, 10)) and
				(pixel_row >= CONV_STD_LOGIC_VECTOR(1, 10)) and (pixel_row <= CONV_STD_LOGIC_VECTOR(15, 10)) then
				char_address <= CONV_STD_LOGIC_VECTOR(5, 6);
			-- V
			elsif (pixel_column >= CONV_STD_LOGIC_VECTOR(352, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(367, 10)) and
				(pixel_row >= CONV_STD_LOGIC_VECTOR(1, 10)) and (pixel_row <= CONV_STD_LOGIC_VECTOR(15, 10)) then
				char_address <= CONV_STD_LOGIC_VECTOR(22, 6);
			-- E
			elsif (pixel_column >= CONV_STD_LOGIC_VECTOR(368, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(383, 10)) and
				(pixel_row >= CONV_STD_LOGIC_VECTOR(1, 10)) and (pixel_row <= CONV_STD_LOGIC_VECTOR(15, 10)) then
				char_address <= CONV_STD_LOGIC_VECTOR(5, 6);
			-- L
			elsif (pixel_column >= CONV_STD_LOGIC_VECTOR(384, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(399, 10)) and
				(pixel_row >= CONV_STD_LOGIC_VECTOR(1, 10)) and (pixel_row <= CONV_STD_LOGIC_VECTOR(15, 10)) then
				char_address <= CONV_STD_LOGIC_VECTOR(12, 6);
			-- space
			elsif (pixel_column >= CONV_STD_LOGIC_VECTOR(400, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(415, 10)) and
				(pixel_row >= CONV_STD_LOGIC_VECTOR(1, 10)) and (pixel_row <= CONV_STD_LOGIC_VECTOR(15, 10)) then
				char_address <= CONV_STD_LOGIC_VECTOR(32, 6);
			-- Level Num
			elsif (pixel_column >= CONV_STD_LOGIC_VECTOR(416, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(431, 10)) and
				(pixel_row >= CONV_STD_LOGIC_VECTOR(1, 10)) and (pixel_row <= CONV_STD_LOGIC_VECTOR(15, 10)) then
				char_address <= Level;
			-- space
			else
				char_address <= CONV_STD_LOGIC_VECTOR(32, 6);
			end if;
		-- space
		else
			char_address <= CONV_STD_LOGIC_VECTOR(32, 6);
		end if;
	end process;
	
	-- Display all ball and paddle
	process (Ball_X_pos, Ball_Y_pos, pixel_column, pixel_row, Game_Mode,
	Ball_X_pos_2, Ball_Y_pos_2, Ball_X_pos_3, Ball_y_pos_3, size, Paddle_X_pos, Paddle_Y_pos, Paddle_Size_Y, Paddle_Size)
		variable Delta_x 	 : STD_logic_vector(21 downto 0);
		variable Delta_Y	 : STD_logic_vector(21 downto 0);
		variable Delta_x_2 : STD_logic_vector(21 downto 0);
		variable Delta_Y_2 : STD_logic_vector(21 downto 0);
		variable Delta_x_3 : STD_logic_vector(21 downto 0);
		variable Delta_Y_3 : STD_logic_vector(21 downto 0);
	begin
		if (Game_Mode = "001" or GAME_MODE = "010" or Game_Mode = "011") then
			-- Sets the x and y values for the circle (x^2 and y^2)
			Delta_x 	 := ((Ball_X_pos)	  - ('0' & pixel_column)) * ((Ball_X_pos)		- ('0' & pixel_column));
			Delta_Y 	 := ((Ball_Y_pos)   - ('0' & pixel_row)) 	  * ((Ball_Y_pos) 	- ('0' & pixel_row));
			Delta_x_2 := ((Ball_X_pos_2) - ('0' & pixel_column)) * ((Ball_X_pos_2) 	- ('0' & pixel_column));
			Delta_Y_2 := ((Ball_Y_pos_2) - ('0' & pixel_row)) 	  * ((Ball_Y_pos_2) 	- ('0' & pixel_row));
			Delta_x_3 := ((Ball_X_pos_3) - ('0' & pixel_column)) * ((Ball_X_pos_3) 	- ('0' & pixel_column));
			Delta_Y_3 := ((Ball_Y_pos_3) - ('0' & pixel_row)) 	  * ((Ball_Y_pos_3) 	- ('0' & pixel_row));
			-- Sets the ball 1 to display
			if ((Delta_x + Delta_Y) <= (Size * size)) then
				Ball_On <= '1';
			else
			-- Sets the ball 1 to not display
				Ball_On <= '0';
			end if;
			
			-- Set Ball 2 to on only in Level 2 and Level 3
			if (GAME_MODE = "010" or GAME_MODE = "011") then
				-- Turns the ball 2 on
				if ((Delta_x_2 + Delta_Y_2) <= (Size * size)) then
					Ball_on_2 <= '1';
				-- Turns the ball 2 off
				else
					Ball_on_2 <= '0';
				end if;
			-- Turns the ball 2 off if not in level 2 or level 3
			else
				Ball_on_2 <= '0';
			end if;
			
			-- Set Ball 3 to on only in Level 3
			if (GAME_MODE = "011") then
				-- Turns the ball 3 on
				if ((Delta_x_3 + Delta_Y_3) <= (Size * size)) then
					Ball_on_3 <= '1';
				-- Turns the ball 2 off
				else
					Ball_on_3 <= '0';
				end if;
			-- Turns the ball 3 off if not in level 3
			else
				Ball_on_3 <= '0';
			end if;
			
			-- Set Paddle on to display in all level
			if ('0' & Paddle_X_pos <= '0' & pixel_column + Paddle_Size) and
				('0' & Paddle_X_pos + Paddle_Size >= '0' & pixel_column) and
				('0' & Paddle_Y_pos <= '0' & pixel_row + Paddle_Size_Y) and
				('0' & Paddle_Y_pos + Paddle_Size_Y >= '0' & pixel_row) then
				Paddle_on <= '1';
			-- Set paddle off
			else
				Paddle_on <= '0';
			end if;
		-- If not in level 1,2 or 3 then turn all ball off and paddle off
		else
			Ball_on <= '0';
			Ball_on_2 <= '0';
			Ball_on_3 <= '0';
			Paddle_on <= '0';
		end if;
	end process;
	
	-- Display "GAME OVER" text when game finished
	process (GAME_MODE, pixel_row, pixel_column)
	begin
		-- If the game finishes display "Game Over"
		if (GAME_MODE = "100") then
			-- Display Game from row 192 to 255
			if (pixel_row >= CONV_STD_LOGIC_VECTOR(192, 10)) and (pixel_row <= CONV_STD_LOGIC_VECTOR(255, 10)) then
				--G
				if (pixel_column >= CONV_STD_LOGIC_VECTOR(192, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(255, 10)) then
					char_address_3 <= CONV_STD_LOGIC_VECTOR(7, 6);
				--A
				elsif (pixel_column >= CONV_STD_LOGIC_VECTOR(256, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(319, 10)) then
					char_address_3 <= CONV_STD_LOGIC_VECTOR(1, 6);
				--M
				elsif (pixel_column >= CONV_STD_LOGIC_VECTOR(320, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(383, 10)) then
					char_address_3 <= CONV_STD_LOGIC_VECTOR(13, 6);
				--E
				elsif (pixel_column >= CONV_STD_LOGIC_VECTOR(384, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(447, 10)) then
					char_address_3 <= CONV_STD_LOGIC_VECTOR(5, 6);
				-- Space
				else
					char_address_3 <= CONV_STD_LOGIC_VECTOR(32, 6);
				end if;
			-- Display Over from row 256 to 317		
			elsif (pixel_row >= CONV_STD_LOGIC_VECTOR(256, 10)) and (pixel_row <= CONV_STD_LOGIC_VECTOR(317, 10)) then
				--O
				if (pixel_column >= CONV_STD_LOGIC_VECTOR(192, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(255, 10)) then
					char_address_3 <= CONV_STD_LOGIC_VECTOR(15, 6);
				--V
				elsif (pixel_column >= CONV_STD_LOGIC_VECTOR(256, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(319, 10)) then
					char_address_3 <= CONV_STD_LOGIC_VECTOR(22, 6);
				--E
				elsif (pixel_column >= CONV_STD_LOGIC_VECTOR(320, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(383, 10)) then
					char_address_3 <= CONV_STD_LOGIC_VECTOR(5, 6);
				--R
				elsif (pixel_column >= CONV_STD_LOGIC_VECTOR(384, 10)) and (pixel_column <= CONV_STD_LOGIC_VECTOR(447, 10)) then
					char_address_3 <= CONV_STD_LOGIC_VECTOR(18, 6);
				-- Space
				else
					char_address_3 <= CONV_STD_LOGIC_VECTOR(32, 6);
				end if;
			-- Space
			else
				char_address_3 <= CONV_STD_LOGIC_VECTOR(32, 6);
			end if;
		-- Space if not Game Over
		else
			char_address_3 <= CONV_STD_LOGIC_VECTOR(32, 6);
		end if;
	end process;
	
	Level <= CONV_STD_LOGIC_VECTOR(49, 6) when Game_Mode = "001" else
				CONV_STD_LOGIC_VECTOR(50, 6) when Game_Mode = "010" else
				CONV_STD_LOGIC_VECTOR(51, 6) when Game_Mode = "011";
				
	Paddle_Size <= CONV_STD_LOGIC_VECTOR(32, 10) when Game_Mode = "001" else
						CONV_STD_LOGIC_VECTOR(16, 10) when Game_Mode = "010" else
						CONV_STD_LOGIC_VECTOR(12, 10) when Game_Mode = "011";
						
	Speed <=3 when Game_Mode = "000" else 3 when Game_Mode = "001" else 4 when Game_Mode = "010" else 5 when Game_Mode = "011";
	
	-- Switch for pausing the game
	Pause_Process : process (Switch1)
	begin
	-- If switch is done then pause
		if (Switch1 = '0') then
			Pause <= '1';
	-- otherwise dont pause
		else
			Pause <= '0';
		end if;
	end process;
	
	-- Process for making the ball move and detection of collision and adding the score when detection is detected
	Game_Logic : process
	begin
		-- Move ball once every vertical sync
		wait until vert_sync_int'event and vert_sync_int = '1';
		countA <= count;
		countB <= countA;
		-- Ball Movement, collision detection, score is added only if in Level 1,2 or 3
		if (GAME_MODE = "001" or GAME_MODE = "010" or GAME_MODE = "011") then
			-- Checks if the game is paused or not
			if (Pause = '0') then
				-- Bounce off top or bottom of screen (Ball 1)
				if (('0' & Ball_Y_pos) >= CONV_STD_LOGIC_VECTOR(472, 10) - Size) then
					Ball_Y_motion <= - CONV_STD_LOGIC_VECTOR(speed, 10);
				elsif (Ball_Y_pos <= Size) then
					Ball_Y_motion <= CONV_STD_LOGIC_VECTOR(speed, 10);
				end if;
				
				-- Randomly generates the speed for the X angle to make a random angle
				if ((countB(2 downto 0) > 0)) then
					if ('0' & Ball_X_pos) = CONV_STD_LOGIC_VECTOR(640, 11) - Size then
						speed1 <= "00000000" & (countB(2 downto 0));
					elsif (Ball_X_pos = size) then
						speed1 <= "00000000" & (countB(2 downto 0));
					end if;
					if (Ball_Y_pos <= Size) then
						speed1 <= "00000000" & (countB(2 downto 0));
					end if;
				else
					speed1 <= "00000000010";
				end if;
				
				-- Assigns the random X speed to the Ball X motion if
				-- Checks for the right wall
				if ("00" & Ball_X_pos) >= CONV_STD_LOGIC_VECTOR(640, 11) - Size then
					Ball_X_motion <= - SPEED1;
				-- Checks for the left wall
				elsif ("00" & Ball_X_pos) <= ('0' & Size - Ball_X_motion)then
					Ball_X_motion <= SPEED1;
				end if;
				
				-- Checks for the paddle and ball collision
				if ('0' & Paddle_X_pos - Paddle_Size <= '0' & Ball_X_pos) and
					('0' & Paddle_X_pos + Paddle_Size >= '0' & Ball_X_pos) and
					('0' & Paddle_Y_pos <= '0' & Ball_Y_pos + Size) and
					('0' & Paddle_Y_pos + Paddle_Size_Y >= '0' & Ball_Y_pos) then
					-- Increments the score text in the game
					if (score_ones > 56) then
						score_ones <= CONV_STD_LOGIC_VECTOR(48, 6);
						score_tens <= score_tens + 1;
					else
						score_ones <= score_ones + 1;
					end if;
					-- Full score which is used for game logic increments
					full_score1 <= full_score1 + 1;
					-- Resets the y position of the ball
					Ball_Y_pos <= CONV_STD_LOGIC_VECTOR(7, 10);
					
					-- Randomly selects the starting X position
					if (countB < CONV_STD_LOGIC_VECTOR(58, 11)) then
						x_pos <= CONV_STD_LOGIC_VECTOR(58, 11);
					elsif (countB > CONV_STD_LOGIC_VECTOR(589, 11)) then
						x_pos <= CONV_STD_LOGIC_VECTOR(589, 11);
					else
						x_pos <= countB;
					end if;
					Ball_X_pos <= X_pos;
				-- Movement of the ball in X and Y position	
				else
					Ball_Y_pos <= Ball_Y_pos + Ball_Y_motion;
					Ball_X_pos <= Ball_X_pos + Ball_X_motion;
				end if;
				
				-- Movement of Ball 2 and collision in Level 2 and 3
				if (GAME_MODE = "010" or GAME_MODE = "011") then
					-- Bounce off top or bottom of screen (Ball 2)
					if ('0' & Ball_Y_pos_2) >= CONV_STD_LOGIC_VECTOR(472, 10) - Size then
						Ball_Y_motion_2 <= - CONV_STD_LOGIC_VECTOR(Speed, 10);
					elsif ('0' & Ball_Y_pos_2) <= Size then
						Ball_Y_motion_2 <= CONV_STD_LOGIC_VECTOR(Speed, 10);
					end if;
					-- Bounce off right and Left of screen (Ball 2)
					if ("00" & Ball_X_pos_2) >= CONV_STD_LOGIC_VECTOR(640, 11) - Size then
						Ball_X_motion_2 <= - CONV_STD_LOGIC_VECTOR(Speed, 11);
					elsif ("00" & Ball_X_pos_2) <= ('0' & Size - Ball_X_motion_2) then
						Ball_X_motion_2 <= CONV_STD_LOGIC_VECTOR(Speed, 11);
					end if;
					
				-- Checks for the paddle and ball collision
					if ('0' & Paddle_X_pos - Paddle_Size <= '0' & Ball_X_pos_2) and
						('0' & Paddle_X_pos + Paddle_Size >= '0' & Ball_X_pos_2) and
						('0' & Paddle_Y_pos <= '0' & Ball_Y_pos_2 + Size) and
						('0' & Paddle_Y_pos + Paddle_Size >= '0' & Ball_Y_pos_2) then
						-- Increments the score text in the game
						if (score_ones > 56) then
							score_ones <= CONV_STD_LOGIC_VECTOR(48, 6);
							score_tens <= score_tens + 1;
						else
							score_ones <= score_ones + 1;
						end if;
						
						-- Full score which is used for game logic increments
						full_score1 <= full_score1 + 1;
						Ball_Y_pos_2 <= CONV_STD_LOGIC_VECTOR(8, 10);

						-- Random starting X position of ball 2
						if (count_2 < CONV_STD_LOGIC_VECTOR(58, 11)) then
							x_pos_2 <= CONV_STD_LOGIC_VECTOR(58, 11);
						elsif (count_2 > CONV_STD_LOGIC_VECTOR(589, 11)) then
							x_pos_2 <= CONV_STD_LOGIC_VECTOR(589, 11);
						else
							x_pos_2 <= count_2;
						end if;
						Ball_X_pos_2 <= X_pos_2;
					-- Movement of the ball in X and Y position	
					else
						Ball_Y_pos_2 <= Ball_Y_pos_2 + Ball_Y_motion_2;
						Ball_X_pos_2 <= Ball_X_pos_2 + Ball_X_motion_2;
					end if;
				end if;
				
				-- Movement of Ball 3 and collision in Level 3
				if (GAME_MODE = "011") then
					-- Bounces off top and bottom wall
					if ('0' & Ball_Y_pos_3) >= CONV_STD_LOGIC_VECTOR(472, 10) - Size then
						Ball_Y_motion_3 <= - CONV_STD_LOGIC_VECTOR(Speed, 10);
					elsif ('0' & Ball_Y_pos_3) <= Size then
						Ball_Y_motion_3 <= CONV_STD_LOGIC_VECTOR(Speed, 10);
					end if;
					-- Bounces off right and left wall
					if ("00" & Ball_X_pos_3) >= CONV_STD_LOGIC_VECTOR(640, 11) - Size then
						Ball_X_motion_3 <= - CONV_STD_LOGIC_VECTOR(Speed, 11);
					elsif ("00" & Ball_X_pos_3) <= ('0' & Size - Ball_X_motion_3) then
						Ball_X_motion_3 <= CONV_STD_LOGIC_VECTOR(Speed, 11);
					end if;
					
					-- Checks for the paddle and ball collision
					if ('0' & Paddle_X_pos - Paddle_Size <= '0' & Ball_X_pos_3) and
						('0' & Paddle_X_pos + Paddle_Size >= '0' & Ball_X_pos_3) and
						('0' & Paddle_Y_pos <= '0' & Ball_Y_pos_3 + Size) and
						('0' & Paddle_Y_pos + Paddle_Size >= '0' & Ball_Y_pos_3) then
						-- Increments the score text in the game
						if (score_ones > 56) then
							score_ones <= CONV_STD_LOGIC_VECTOR(48, 6);
							score_tens <= score_tens + 1;
						else
							score_ones <= score_ones + 1;
						end if;
						
						-- Full score which is used for game logic increments
						full_score1 <= full_score1 + 1;
						
						Ball_Y_pos_3 <= CONV_STD_LOGIC_VECTOR(8, 10);
						
						-- Random starting X position of ball 3
						if (count_3 < CONV_STD_LOGIC_VECTOR(58, 11)) then
							x_pos_3 <= CONV_STD_LOGIC_VECTOR(58, 11);
						elsif (count_3 > CONV_STD_LOGIC_VECTOR(589, 11)) then
							x_pos_3 <= CONV_STD_LOGIC_VECTOR(589, 11);
						else
							x_pos_3 <= count_3;
						end if;
						Ball_x_pos_3 <= X_pos_3;
					
					-- Movement of the ball in X and Y position	
					else
						Ball_Y_pos_3 <= Ball_Y_pos_3 + Ball_Y_motion_3;
						Ball_x_pos_3 <= Ball_x_pos_3 + Ball_x_motion_3;
					end if;
				end if;
			-- Keeps the same position
			else
				Ball_Y_pos <= Ball_Y_pos;
				Ball_X_pos <= Ball_X_pos;
				Ball_Y_pos_2 <= Ball_Y_pos_2;
				Ball_X_pos_2 <= Ball_X_pos_2;
				Ball_Y_pos_3 <= Ball_Y_pos_3;
				Ball_X_pos_3 <= Ball_X_pos_3;
			end if;
		-- Starting positions of the ball and score
		else
			Ball_Y_pos <= CONV_STD_LOGIC_VECTOR(8, 10); 
			Ball_X_pos <= CONV_STD_LOGIC_VECTOR(7, 11);
			Ball_Y_pos_2 <= CONV_STD_LOGIC_VECTOR(7, 10);
			Ball_X_pos_2 <= CONV_STD_LOGIC_VECTOR(7, 11);
			Ball_Y_pos_3 <= CONV_STD_LOGIC_VECTOR(8, 10);
			Ball_X_pos_3 <= CONV_STD_LOGIC_VECTOR(7, 11);
			score_ones <= CONV_STD_LOGIC_VECTOR(48, 6);
			score_tens <= CONV_STD_LOGIC_VECTOR(48, 6);
			full_score1 <= 0;
		end if;
		-- stores to score
		full_score <= full_score1;
	end process Game_Logic;
	
	-- Timer for the game
	Timing : process (clock, Game_MODE, Pause, timer1)
	begin
		if (clock'event and clock = '1') then
			temp_Game_Mode <= Game_Mode;
			-- Checks if in level 1, 2 or 3
			if (GAME_MODE = "001" or GAME_MODE = "010" or GAME_MODE = "011") then
				-- Timer keeps running unless the game is paushed
				if (Pause = '0') then
					if (temp_Game_Mode /= game_Mode) then
						timer1 <= 59;
						sec_ones <= CONV_STD_LOGIC_VECTOR(57, 6);
						sec_tens <= CONV_STD_LOGIC_VECTOR(53, 6);
					end if;
					-- clock divider to 25Mhz
					if (counter < 25000000) then
						counter <= counter + 1;
					else
						counter <= 0;
						sec_ones <= sec_ones - 1;
						timer1 <= timer1 - 1;
					end if;
					-- sets the sec_ones text which is displayed to 0
					if (sec_ones < 48) then
						sec_ones <= CONV_STD_LOGIC_VECTOR(57, 6);
						-- sets the sec_tens text which is displayed to 0 and timer to 0 if it goes less than 0
						if (sec_tens < 48) then
							sec_tens <= CONV_STD_LOGIC_VECTOR(48, 6);
							timer1 <= 0;
						else
							sec_tens <= sec_tens - 1;
						end if;
					end if;
				-- keeps the current value
				else
					sec_ones <= sec_ones;
					sec_tens <= sec_tens;
				end if;
			-- Initilase the sec ones to 9 and sec tens to 5 in the screen
			else
				sec_ones <= CONV_STD_LOGIC_VECTOR(57, 6);
				sec_tens <= CONV_STD_LOGIC_VECTOR(53, 6);
				timer1 <= 59;
			end if;
		end if;
		timer <= timer1;
	end process Timing;
	
	--Random number generator
	lfsr_process : process (clock)
	begin
		if (clock'event and clock = '1') then
			count <= '0' & '0' & count(7) & count(6) & (count(5) & count(4)) & count(2)
				& (count(3) xor count(8)) & count(1) & count(0) & count(3);
			count_2 <= '0' & '0' & count_2(7) & count_2(6) & (count_2(5) & count_2(4)) & count_2(2)
				& (count_2(3) xor count_2(8)) & count_2(1) & count_2(0) & count_2(3);
			count_3 <= '0' & '0' & count_3(7) & count_3(6) & (count_3(5) & count_3(4)) & count_3(2)
				& (count_3(3) xor count_3(8)) & count_3(1) & count_3(0) & count_3(3);
		end if;
	end process;
	
	-- Movement of the paddle
	Paddle_X_pos <= '0' & mouse_col when ((Game_MODE = "001" or Game_Mode = "010" or Game_Mode = "011") and (Pause = '0'));
end behavior;