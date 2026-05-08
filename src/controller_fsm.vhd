----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:42:49 PM
-- Design Name: 
-- Module Name: controller_fsm - FSM
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity controller_fsm is
    Port ( i_reset : in STD_LOGIC;
           i_adv : in STD_LOGIC;
           o_cycle : out STD_LOGIC_VECTOR (3 downto 0));
end controller_fsm;

architecture FSM of controller_fsm is

type state is (S0,S1, S2, S3);
signal f_Q, f_Q_next : state;

begin
    f_Q_next <= S1 when f_Q = S0 else
                S2 when f_Q = S1 else
                S3 when f_Q = S2 else
                S0 when f_Q = S3;
                
    o_cycle <= "0001" when f_Q = S0 else
               "0010" when f_Q = S1 else
               "0100" when f_Q = S2 else
               "1000" when f_Q = S3;
    
    -- PROCESSES --------------------------------------------------------------------
    register_proc : process (i_adv, i_reset)
    begin
        if i_reset = '1' then
            f_Q <= S0;        -- reset state is S0
        elsif rising_edge(i_adv) then
            f_Q <= f_Q_next;    -- next state becomes current state
        end if;
    end process register_proc;
	-----------------------------------------------------	
end FSM;
