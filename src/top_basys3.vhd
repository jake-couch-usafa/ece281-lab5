--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity top_basys3 is
    port(
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(7 downto 0); -- operands and opcode
        btnU    :   in std_logic; -- reset
        btnC    :   in std_logic; -- fsm cycle
        
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is 
    
	-- declare components and signals
	component ALU is
    Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
           i_B : in STD_LOGIC_VECTOR (7 downto 0);
           i_op : in STD_LOGIC_VECTOR (2 downto 0);
           o_result : out STD_LOGIC_VECTOR (7 downto 0);
           o_flags : out STD_LOGIC_VECTOR (3 downto 0)
          );
    end component ALU;
	
	component TDM4 is
		generic ( constant k_WIDTH : natural  := 4); -- bits in input and output
        Port ( i_clk		: in  STD_LOGIC;
           i_reset		: in  STD_LOGIC; -- asynchronous
           i_D3 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D2 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D1 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D0 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_data		: out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_sel		: out STD_LOGIC_VECTOR (3 downto 0)	-- selected data line (one-cold)
	   );
    end component TDM4;
    
    component clock_divider is
	generic ( constant k_DIV : natural := 2	); -- How many clk cycles until slow clock toggles
											   -- Effectively, you divide the clk double this 
											   -- number (e.g., k_DIV := 2 --> clock divider of 4)
	port ( 	i_clk    : in std_logic;
			i_reset  : in std_logic;		   -- asynchronous
			o_clk    : out std_logic		   -- divided (slow) clock
	);
    end component clock_divider;
    
    component controller_fsm is
        Port ( i_reset : in STD_LOGIC;
               i_adv : in STD_LOGIC;
               o_cycle : out STD_LOGIC_VECTOR (3 downto 0));
    end component controller_fsm;
    
    component twos_comp is
    port (
        i_bin: in std_logic_vector(7 downto 0);
        o_sign: out std_logic;
        o_hund: out std_logic_vector(3 downto 0);
        o_tens: out std_logic_vector(3 downto 0);
        o_ones: out std_logic_vector(3 downto 0)
    );
    end component twos_comp;
    
    component button_debounce is
        Port(
            clk: in  STD_LOGIC;
			reset : in  STD_LOGIC;
			button: in STD_LOGIC;
			action: out STD_LOGIC
		);
    end component button_debounce;
    
    component sevenseg_decoder is
    Port ( i_Hex : in STD_LOGIC_VECTOR (3 downto 0);
           o_seg_n : out STD_LOGIC_VECTOR (6 downto 0));
    end component sevenseg_decoder;
    
    --signals
    signal w_clk : STD_LOGIC; --slower clock
    signal w_cycle : std_logic_vector(3 downto 0);
    
    signal w_sign, w_hund, w_tens, w_ones : STD_LOGIC_VECTOR(3 downto 0);
    signal w_result1, w_result2 : STD_LOGIC_VECTOR(7 downto 0); --from mux
    
    signal w_data, w_sel : STD_LOGIC_VECTOR(3 downto 0);
    
    signal w_A, w_B : STD_LOGIC_VECTOR(7 downto 0);
    
    signal w_seg : STD_LOGIC_VECTOR(6 downto 0);
    
    signal w_btnC : STD_LOGIC;
begin
	-- PORT MAPS ----------------------------------------
    btn_debounce_inst : button_debounce
        Port map(
            clk => clk,
			reset =>  btnU,
			button => btnC,
			action => w_btnC
		);
    
    clock_divider_inst : clock_divider
    	generic map ( k_DIV => 125000) -- from 100 MHz
        port map (						  
            i_clk   => clk,
            i_reset => btnU,
            o_clk   => w_clk
        );
	
	controller_fsm_inst : controller_fsm
	   port map(
	       i_reset => btnU,
           i_adv => w_btnC,
           o_cycle => w_cycle
	   );
	   
	 twos_comp_inst : twos_comp
	   port map(
	       i_bin => w_result2,
           o_sign => w_sign(0),
           o_hund => w_hund,
           o_tens => w_tens,
           o_ones => w_ones
	   );
	   
	 TDM_inst : TDM4
         generic map(k_WIDTH => 4) -- bits in input and output
         port map(
           i_clk     => w_clk,
           i_reset   => btnU, -- asynchronous
           i_D3      => w_sign,
           i_D2 	 => w_hund,
           i_D1 	 => w_tens,
           i_D0 	 => w_ones,
           o_data	 => w_data,
           o_sel	 => w_sel	-- selected data line (one-cold)
         );
       
      ALU_inst : ALU
          Port map(
               i_A => w_A,
               i_B => w_B,
               i_op => sw(2 downto 0),
               o_result => w_result1,
               o_flags => led(15 downto 12)
          );
      
       sevenseg_decoder_inst : sevenseg_decoder
           Port map(
               i_Hex => w_data,
               o_seg_n => w_seg
           );
	   
	-- CONCURRENT STATEMENTS ----------------------------
    --negative sign for for segs
    seg <= "0111111" when (w_sign(0) = '1' and w_sel = "0111") else
           "1111111" when (w_sign(0) = '0' and w_sel = "0111")
            else w_seg;
	
	with w_cycle(0) select         --mux for anode
	    an <= w_sel when '0',
	         "1111" when others;
	
	with w_cycle select            --mux for 2s comp
	    w_result2 <= w_result1 when "1000",
	                 w_A when "0010",
	                 w_B when "0100",
	                 x"00" when others;
	
	led(11 downto 4) <= x"00"; --ground LEDs
	
	led(3 downto 0) <= w_cycle;
	-- PROCESSES --------------------------------------------------------------------
    register_proc : process (clk)
    begin
        if btnU = '1' then
            w_A <= x"00";
            
        elsif rising_edge(clk) then
            if w_cycle = "0010" then
                w_A <= sw(7 downto 0);
            end if;
        end if;
    end process register_proc;
    
    register_proc1 : process (clk)
    begin
        if btnU = '1' then
            w_B <= x"00";

        elsif rising_edge(clk) then
            if w_cycle = "0100" then
                w_B <= sw(7 downto 0);
            end if;
        end if;
    end process register_proc1;
	-----------------------------------------------------	
	
end top_basys3_arch;
