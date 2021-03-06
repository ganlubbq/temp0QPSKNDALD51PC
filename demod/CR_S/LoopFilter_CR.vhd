-------------------------------------------------------------------------------
--
-- Author: Zaichu Yang
-- Project: QPSK  Demodulator
-- Date: 2008.10.10
--
-------------------------------------------------------------------------------
--
-- Purpose: 
-- 	Loopfilter for  carrier recovery.
-------------------------------------------------------------------------------
--
-- Revision History: 
-- 2008.10.23 first revision
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity LoopFilter_CR is 
  generic(
  	kErrWidth   : positive := 12
  	);
  port(               
    aReset            : in std_logic;
    Clk               : in std_logic;
    
    sErrIn	      : in std_logic_vector(kErrWidth-1 downto 0);
    sEnableIn	      : in std_logic;
               
    sEnableOut        : out std_logic;
    sLoopOut          : out std_logic_vector(kErrWidth-1 downto 0)
    );
end LoopFilter_CR;

architecture rtl of LoopFilter_CR is
	constant cAccSize	: positive :=32;

	type ErrInArray is Array (natural range <>) of signed (kErrWidth-1 downto 0);
	signal sErrIn_Reg: ErrInArray (1 downto 0);
	
	signal sLoopFilter_Pre		: signed(kErrWidth-1 downto 0);
	signal sAcc_Pre			: signed(cAccSize - 1 downto 0);
	signal sAcc_Prop,sAcc_Prop_Reg,sAcc_Integ	: signed(cAccSize - 1 downto 0);	
	
	signal sAcc,sLoopOut_Reg	: signed(cAccSize - 1 downto 0); 
	signal sEnable_Reg		: std_logic_vector (6 downto 0);
begin
	process (aReset,Clk)
	begin
		if aReset='1' then
			for i in 0 to 1 loop
				sErrIn_Reg(i)	<= (others => '0');
			end loop;
			sLoopFilter_Pre		<= (others => '0');
			sAcc_Pre		<= (others => '0');
			sAcc_Prop		<= (others => '0');
			sAcc_Prop_Reg		<= (others => '0');
			sAcc_Integ		<= (others => '0');
			sAcc			<= (others => '0');
			sLoopOut_Reg		<= (others => '0');
			sEnable_Reg		<= (others => '0');
			sLoopOut		<= (others => '0');
		elsif rising_edge(Clk) then
			if sEnableIn= '1' then
				-- the first pipline
				sErrIn_Reg(0)	<= signed(sErrIn);
				sErrIn_Reg(1)	<= sErrIn_Reg(0);
				sEnable_Reg(0)	<= sEnableIn;
				for i in 1 to 6 loop
					sEnable_Reg(i) <= sEnable_Reg(i-1);
				end loop;
				
				-- the second pipline    Stop and Go
				if sErrIn_Reg(1)(kErrWidth-1)=sErrIn_Reg(0)(kErrWidth-1) then
					sLoopFilter_Pre	<= sErrIn_Reg(0) - sErrIn_Reg(1);
				end if;
				
				-- the third pipline
				sAcc_Pre	<= sLoopFilter_Pre & to_signed(0,cAccSize-kErrWidth);
				
				-- the fourth pipline
				sAcc_Integ	<= shift_right(sAcc_Pre,9);--9
				sAcc_Prop	<= shift_right(sAcc_Pre,5);--5
				
				-- the fifth pipline
				sAcc_Prop_Reg	<= sAcc_Prop;
				sAcc		<= sAcc+sAcc_Integ;
				
				-- the sixth pipline
				sLoopOut_Reg	<= sAcc_Prop_Reg+sAcc;
				
				-- the seventh pipline
				sLoopOut	<= std_logic_vector(sLoopOut_Reg(cAccSize - 1 downto cAccSize-kErrWidth));
				sEnableOut	<= sEnable_Reg(5);	
			else
				sEnableOut	<= '0';
			end if;
		end if;
	end process;
	
end rtl;  
