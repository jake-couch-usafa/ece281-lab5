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

signal f_Q, f_Q_next : STD_LOGIC_VECTOR(1 downto 0);

begin
    o_cycle(0) <= f_Q(0) AND f_Q(1);
    o_cycle(1) <= f_Q(0) AND NOT f_Q(1);
    o_cycle(2) <= NOT f_Q(0) AND f_Q(1);
    o_cycle(3) <= NOT (f_Q(1) OR f_Q(0));
    
    f_Q_next(0) <= f_Q(0) XOR f_Q(1);
    f_Q_next(1) <= NOT f_Q(1);
    -- PROCESSES --------------------------------------------------------------------
    register_proc : process (i_adv, i_reset)
    begin
        if i_reset = '1' then
            f_Q <= "00";        -- reset state is S0
        elsif (i_adv = '1') then
            f_Q <= f_Q_next;    -- next state becomes current state
        end if;
    end process register_proc;
	-----------------------------------------------------	
end FSM;
