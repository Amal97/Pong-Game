----------------------Begin Define Library and Packages---------------------
library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use IEEE.STD_LOGIC_ARITH.all;
---------------------End Define Library and Packages---------------------
---------------------Define Entity Here---------------------
entity control_unit is
	port
	(
		signal PB1, PB2, Clock : in std_logic;
		signal SWITCH0 : in std_logic;
		signal full_score : in integer range 0 to 200;
		signal timer : in integer range 0 to 100;
		signal Mode : out std_logic;
		signal Game_Mode : out std_logic_vector(2 downto 0));
end control_unit;
--------------------- Entity Ends Here ---------------------
--------------------- Define Architecture Here ---------------------
architecture behavior of control_unit is
	type usart_states is (Main_Menu, Level_1, Level_2, Level_3, Training_Mode, Game_Over); -- Define states
	signal CS, NS : usart_states := Main_Menu; -- CS = Current_State , NS = Next_State, Start state is Main_Menu
	---------------------End Architecture Here---------------------
	----------------------- VHDL Code for the FSM (the brain of the machine) ---------------------
begin
	---------------------Begin NextState Logic VHDL Code FSM---------------------
	NextState_logic : process (NS, SWITCH0, clock)
	begin
		if clock'event and clock = '1' then
			case NS is
				-- Main Menu Screen
				when Main_Menu =>
					-- Checks for button press to go to level 1
					if SWITCH0 = '1' and PB1 = '0' then
						NS <= Level_1;
					-- Checks for button press to go to training
					elsif SWITCH0 = '0' and PB1 = '0' then
						NS <= Training_Mode;
					-- Remain in the Main_Menu
					else
						NS <= Main_Menu;
					end if;
				-- Level 1 Screen
				when Level_1 =>
					-- Checks if the score is 10 and timer is more than 0 then proceed to Level 2
					if (full_score = 10) and (timer >= 0) then
						NS <= Level_2;
					-- Checks if push button is pressed then go to main menu
					elsif PB2 = '0' then
						NS <= Main_Menu;
					-- Checks if timer is less than 0 then game finishes
					elsif timer <= 0 then
						NS <= Game_Over;
					-- Otherwise remain in level 1
					else
						NS <= Level_1;
					end if;
				-- Level 2 Screen
				when Level_2 =>
					-- Checks if the score is 40 and timer is more than 0 then proceed to Level 3
					if full_score = 40 and timer >= 0 then
						NS <= Level_3;
					-- Checks if push button is pressed then go to main menu
					elsif PB2 = '0' then
						NS <= Main_Menu;
					-- Checks if timer is less than 0 then game finishes
					elsif timer <= 0 then
						NS <= Game_Over;
					-- Otherwise remain in level 2
					else
						NS <= Level_2;
					end if;
				-- Level 3 Screen
				when Level_3 =>
					-- Checks if the score is 80 and timer is more than 0 then proceed to Level 2
					if full_score = 80 and timer >= 0 then
						NS <= Game_Over;
					-- Checks if push button is pressed then go to main menu
					elsif PB2 = '0' then
						NS <= Main_Menu;
					-- Checks if timer is less than 0 then game finishes
					elsif timer <= 0 then
						NS <= Game_Over;
					else
					-- Otherwise remain in level 3
						NS <= Level_3;
					end if;
				-- Training Mode Screen
				when Training_Mode =>
					-- Checks if the score is 10 and timer is more than 0 then proceed to Level 2
					if full_score = 10 then
						NS <= Game_Over;
					-- Checks if push button is pressed then go to main menu
					elsif PB2 = '0' then
						NS <= Main_Menu;
					-- Checks if timer is less than 0 then game finishes
					elsif timer <= 0 then
						NS <= Game_Over;
					-- Otherwise remain in Training Mode
					else
						NS <= Training_Mode;
					end if;
				-- Game Over Screen
				when Game_Over =>
					-- Checks if push button is pressed then go to main menu
					if PB2 = '0' then
						NS <= Main_Menu;
					-- Otherwise remain in Game Over screen
					else
						NS <= Game_Over;
					end if;
			end case;
		end if;
	end process;
	---------------------End NextState Logic VHDL Code FSM---------------------
	---------------------Begin Output_logic VHDL Code FSM---------------------
	Output_logic : process (NS, CLOCK)
	begin
		if clock'event and clock = '1' then
			case NS is
				when Main_Menu => -- "000"
					-- Checks for DIP switch to move the arrow in Main Menu
					if SWITCH0 = '1' then
						MODE <= '1';
					elsif SWITCH0 = '0' then
						MODE <= '0';
					end if;
					-- Checks for where the switch is and push button is pressed to change Game Mode
					if SWITCH0 = '1' and PB1 = '0' then
						Game_Mode <= "001";
					elsif SWITCH0 = '0' and PB1 = '0' then
						Game_Mode <= "001";
					else
						Game_Mode <= "000";
					end if;
					
				when Level_1 => -- "001"
					-- Checks for the full score to go to level 2
					if full_score = 10 then
						Game_Mode <= "010";
					-- Checks for the push button is pressed to return to Main Menu
					elsif PB2 = '0' then
						Game_Mode <= "000";
					-- Checks if timer is less than 0 to go to Game Over
					elsif timer <= 0 then
						Game_Mode <= "000";
					-- Remain in the same game mode
					else
						Game_Mode <= "001";
					end if;
					
				when Level_2 => -- "010"
					-- Checks for the full score and timer to go to level 2
					if full_score = 40 and timer >= 0 then
						Game_Mode <= "011";
					-- Checks for the push button is pressed to return to Main Menu
					elsif PB2 = '0' then
						Game_Mode <= "000";
					-- Checks if timer is less than 0 to go to Game Over
					elsif timer <= 0 then
						Game_Mode <= "000";
					-- Remain in the same game mode
					else
						Game_Mode <= "010";
					end if;
					
				when Level_3 => -- "011"
					-- Checks for the full score and timer to go to Main Menu
					if full_score = 80 and timer >= 0 then
						Game_Mode <= "000";
					-- Checks for the push button is pressed to return to Main Menu
					elsif PB2 = '0' then
						Game_Mode <= "000";
					-- Checks if timer is less than 0 to go to Game Over
					elsif timer <= 0 then
						Game_Mode <= "000";
					-- Remain in the same game mode
					else
						Game_Mode <= "011";
					end if;
					
				when Training_Mode => -- "101"
					-- Checks for the full score
					if full_score = 10 then
						Game_Mode <= "000";
					-- Checks for push button is pressed to go to main menu
					elsif PB2 = '0' then
						Game_Mode <= "000";
					-- Checks if timer is less than 0 to go to Game Over
					elsif timer <= 0 then
						Game_Mode <= "000";
					-- Remain in the same game mode
					else
						Game_Mode <= "001";
					end if;
					
				when Game_Over => -- "100"
					-- Returns to Main Menui if push button 2 is pressed
					if PB2 = '0' then
						Game_Mode <= "000";
					-- Remain in the same game mode
					else
						Game_Mode <= "100";
					end if;
			end case;
		end if;
	end process;
end behavior;