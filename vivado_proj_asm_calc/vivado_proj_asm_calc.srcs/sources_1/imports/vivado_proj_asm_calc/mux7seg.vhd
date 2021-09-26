----------------------------------------------------------------------------------
-- Company: 			Engs 31 16X
-- Engineer: 			E.W. Hansen
-- 
-- Create Date:    	    17:56:35 07/25/2008
-- Design Name: 	
-- Module Name:    	    mux7seg - Behavioral 
-- Project Name: 		
-- Target Devices: 	    Digilent Basys 3 board (Artix 7)
-- Tool versions: 	    Vivado 2016.1
-- Description: 		Multiplexed seven-segment decoder for the display on the Basys3
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Revision 1.00 (07/17/2015) --- drop the clock divider, run on a 1000 Hz clock
-- Revision 2.00 (07/17/2016) --- put the clock divider back in
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity mux7seg is
    Port ( clk_iport 	: in  std_logic;						-- runs on a fast (1 MHz or so) clock
	       y3_iport 	: in  std_logic_vector (3 downto 0);	-- digits
		   y2_iport 	: in  std_logic_vector (3 downto 0);	-- digits
		   y1_iport 	: in  std_logic_vector (3 downto 0);	-- digits
           y0_iport 	: in  std_logic_vector (3 downto 0);	-- digits
           dp_set_iport : in  std_logic_vector(3 downto 0);     -- decimal points
		   
           seg_oport 	: out  std_logic_vector(0 to 6);		-- segments (a...g)
           dp_oport 	: out  std_logic;						-- decimal point
           an_oport 	: out  std_logic_vector (3 downto 0) );	-- anodes
end mux7seg;

architecture Behavioral of mux7seg is
	constant NCLKDIV:     integer := 15;                     -- 1 MHz / 2^18 = 381 Hz
    constant MAXCLKDIV:   integer := 2**NCLKDIV-1;           -- max count of clock divider
    signal cdcount:       unsigned(NCLKDIV-1 downto 0);      -- clock divider counter register
    signal CE :           std_logic;                         -- clock enable

	signal adcount : unsigned(1 downto 0) := "00";		     -- anode / mux selector count
	signal anb: std_logic_vector(3 downto 0);
	signal muxy : std_logic_vector(3 downto 0);			     -- mux output
	signal segh : std_logic_vector(0 to 6);				     -- segments (high true)

begin			
-- Clock divider sets the rate at which the display hops from one digit to the next.  A larger value of
-- MAXCLKDIV results in a slower clock-enable (CE)
ClockDivider:
process(clk_iport)		
begin 
	if rising_edge(clk_iport) then 
	   if cdcount < MAXCLKDIV then
	        CE <= '0';
			cdcount <= cdcount+1;	
	   else 
			CE <= '1';
	        cdcount <= (others => '0');
	   end if;
	end if;
end process ClockDivider;

AnodeDriver:
process(clk_iport, adcount)
begin	
	if rising_edge(clk_iport) then
	   if CE='1' then
		  adcount <= adcount + 1;
	   end if;
	end if;
	
	case adcount is
		when "00" => anb <= "1110"; 
		when "01" => anb <= "1101"; 
		when "10" => anb <= "1011"; 
		when "11" => anb <= "0111"; 
		when others => anb <= "1111";
	end case;
end process AnodeDriver;

an_oport <= anb;

Multiplexer:
process(adcount, y0_iport, y1_iport, y2_iport, y3_iport, dp_set_iport)
begin
	case adcount is
		when "00" => muxy <= y0_iport; dp_oport <= not(dp_set_iport(0));
		when "01" => muxy <= y1_iport; dp_oport <= not(dp_set_iport(1));
		when "10" => muxy <= y2_iport; dp_oport <= not(dp_set_iport(2));
		when "11" => muxy <= y3_iport; dp_oport <= not(dp_set_iport(3));
		when others => muxy <= x"0"; dp_oport <= '1';
	end case;
end process Multiplexer;

-- Seven segment decoder
with muxy select segh <=
	"1111110" when x"0",		-- active-high definitions
	"0110000" when x"1",
	"1101101" when x"2",
	"1111001" when x"3",
	"0110011" when x"4",
	"1011011" when x"5",
	"1011111" when x"6",
	"1110000" when x"7",
	"1111111" when x"8",
	"1111011" when x"9",
	"1110111" when x"a",	
	"0011111" when x"b",	
	-- "1001110" when x"c",(original version to display c)
	"0000001" when x"c", -- display a negative sign when c is given
	"0111101" when x"d",	
	"1001111" when x"e",	
	"1000111" when x"f",	
	"0000000" when others;	
seg_oport <= not(segh);				-- Convert to active-low

end Behavioral;
