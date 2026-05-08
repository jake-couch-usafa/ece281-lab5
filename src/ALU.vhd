----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:50:18 PM
-- Design Name: 
-- Module Name: ALU - Behavioral
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

entity ALU is
    Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
           i_B : in STD_LOGIC_VECTOR (7 downto 0);
           i_op : in STD_LOGIC_VECTOR (2 downto 0);
           o_result : out STD_LOGIC_VECTOR (7 downto 0);
           o_flags : out STD_LOGIC_VECTOR (3 downto 0));
end ALU;

architecture Behavioral of ALU is
    
    component ripple_adder is
    Port ( A : in STD_LOGIC_VECTOR (3 downto 0);
           B : in STD_LOGIC_VECTOR (3 downto 0);
           Cin : in STD_LOGIC;
           S : out STD_LOGIC_VECTOR (3 downto 0);
           Cout : out STD_LOGIC);
    end component ripple_adder;
    
    signal w_carry       : STD_LOGIC_VECTOR(1 downto 0);
    signal w_B           : STD_LOGIC_VECTOR(7 downto 0);
    signal w_s           : STD_LOGIC_VECTOR(7 downto 0);
    signal w_and, w_or   : STD_LOGIC_VECTOR(7 downto 0);
    signal w_carryIn     : STD_LOGIC; --1 when subtracting, 0 otherwise
    signal w_result      : STD_LOGIC_VECTOR(7 downto 0);
    
begin
    --Addition and subtraction
    w_B <= NOT i_B when i_op = "001"
    else i_B;
    w_carryIn <= '1' when i_op = "001"
    else '0';
        
    ripple_adder_0: ripple_adder -- lower 4 bits
    port map(
        A     => i_A(3 downto 0),
        B     => w_B(3 downto 0),
        Cin   => w_carryIn,
        S     => w_s(3 downto 0),
        Cout  => w_carry(0)
    );
    
    ripple_adder_1: ripple_adder -- upper 4 bits
    port map(
        A     => i_A(7 downto 4),
        B     => w_B(7 downto 4),
        Cin   => w_carry(0),  -- from first adder
        S     => w_s(7 downto 4),
        Cout  => w_carry(1)
    );
    
    
    --Concurrent statements
    --AND / OR
    w_and <= i_A AND i_B;
    w_or  <= i_A OR i_B;
    
    --Outputs
    with i_op select
        w_result <= w_s when "000",
                    w_s when "001",
                    w_and when "010",
                    w_or when "011",
                    "00000000" when others;
    o_flags(3) <= w_result(7);                                          --sign
    o_flags(2) <= '1' when w_result = "00000000" else '0';              --zero
    o_flags(1) <= w_carry(1);                                           --carry out
    o_flags(0) <= NOT(i_A(7) XOR w_B(7)) AND (w_B(7) XOR w_result(7));      --overflow
    
    o_result <= w_result;
end Behavioral;
