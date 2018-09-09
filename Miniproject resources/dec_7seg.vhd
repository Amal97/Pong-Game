LIBRARY IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity dec_7seg is
	port(Data_In: in std_logic_vector(3 downto 0);
		  Data_Out : out std_logic_vector (6 downto 0));
	end entity dec_7seg;
	
	architecture behaviour of dec_7seg is
			
	
	begin
		Seven_Segment_Decoder: process(Data_In)
		begin
				case Data_In(3 downto 0) is
					when "0000"=> Data_Out<="0000001"; --0
					when "0001"=> Data_Out<="1001111"; --1
					when "0010"=> Data_Out<="0010010"; --2
					when "0011"=> Data_Out<="0000110"; --3
					when "0100"=> Data_Out<="1001100"; --4
					when "0101"=> Data_Out<="0100100"; --5
					when "0110"=> Data_Out<="0100000"; --6
					when "0111"=> Data_Out<="0001111"; --7
					when "1000"=> Data_Out<="0000000"; --8
					when "1001"=> Data_Out<="0000100"; --9
--					when "1010"=> Data_Out<="0001000"; --A
					when others=> Data_Out<="0111110"; -- X
					end case;
			end process;									
	end architecture behaviour;
	
	