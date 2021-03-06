LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.STD_LOGIC_ARITH.all;
USE IEEE.STD_LOGIC_UNSIGNED.all;

ENTITY game_text IS
   PORT(signal pixel_column, pixel_row	: in std_logic_vector(10 downto 0);
		  signal char_address : out std_logic_vector(5 downto 0);
		  signal char_row, char_col : out std_logic_vector(2 downto 0));
end game_text;

architecture behavior of game_text is

signal pixel_row_text, pixel_column_text : std_logic_vector(10 downto 0);

begin           

pixel_row_text <= pixel_row;
pixel_column_text <= pixel_column;

Display_text: process (pixel_column_text, pixel_row_text)
begin
	-- display A
		if (pixel_column_text >= CONV_STD_LOGIC_VECTOR(192, 10)) and
			(pixel_column_text <= CONV_STD_LOGIC_VECTOR(22, 10)) and
			(pixel_row_text >= CONV_STD_LOGIC_VECTOR(96, 10)) and
			(pixel_row_text <= CONV_STD_LOGIC_VECTOR(127, 10)) then
			char_row <= pixel_row_text(4 downto 2);
			char_col <= pixel_column_text(4 downto 2);
			char_address <= CONV_STD_LOGIC_VECTOR(1, 6);
		else
			char_row <= pixel_row_text(3 downto 1);
			char_col <= pixel_column_text(3 downto 1);
			char_address <= CONV_STD_LOGIC_VECTOR(32, 6);
		end if;
	
end process Display_text;

end architecture;