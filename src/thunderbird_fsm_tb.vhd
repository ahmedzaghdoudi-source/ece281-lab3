--+----------------------------------------------------------------------------
--| 
--| COPYRIGHT 2017 United States Air Force Academy All rights reserved.
--| 
--| United States Air Force Academy     __  _______ ___    _________ 
--| Dept of Electrical &               / / / / ___//   |  / ____/   |
--| Computer Engineering              / / / /\__ \/ /| | / /_  / /| |
--| 2354 Fairchild Drive Ste 2F6     / /_/ /___/ / ___ |/ __/ / ___ |
--| USAF Academy, CO 80840           \____//____/_/  |_/_/   /_/  |_|
--| 
--| ---------------------------------------------------------------------------
--|
--| FILENAME      : thunderbird_fsm_tb.vhd (TEST BENCH)
--| AUTHOR(S)     : Capt Phillip Warner
--| CREATED       : 03/2017
--| DESCRIPTION   : This file tests the thunderbird_fsm modules.
--|
--|
--+----------------------------------------------------------------------------
--|
--| REQUIRED FILES :
--|
--|    Libraries : ieee
--|    Packages  : std_logic_1164, numeric_std
--|    Files     : thunderbird_fsm_enumerated.vhd, thunderbird_fsm_binary.vhd, 
--|				   or thunderbird_fsm_onehot.vhd
--|
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
  
entity thunderbird_fsm_tb is
end thunderbird_fsm_tb;

architecture test_bench of thunderbird_fsm_tb is 
	
	component thunderbird_fsm is 
	   port (
        i_clk, i_reset  : in    std_logic;
        i_left, i_right : in    std_logic;

        o_lights_L      : out   std_logic_vector(2 downto 0);
        o_lights_R      : out   std_logic_vector(2 downto 0)
       );
    
	end component thunderbird_fsm;

	-- test I/O signals
	signal i_clk_tb         : std_logic := '0' ;
	signal i_reset_tb       : std_logic := '0' ;
	signal i_left_tb        : std_logic := '0' ;
	signal i_right_tb       : std_logic := '0' ;
	signal o_lights_L_tb    : std_logic_vector(2 downto 0) :=(others => '0');
	signal o_lights_R_tb    : std_logic_vector(2 downto 0) :=(others => '0');
	
	-- constants
	constant clk_period : time := 10 ns;
	
	
begin
	-- PORT MAPS ----------------------------------------
	utt: thunderbird_fsm
	   port map(
	       i_clk       => i_clk_tb,
	       i_reset     => i_reset_tb,
	       i_left      => i_left_tb,
	       i_right     => i_right_tb,
	       o_lights_L  => o_lights_L_tb,
	       o_lights_R  => o_lights_R_tb
	   );
	-----------------------------------------------------
	
	-- PROCESSES ----------------------------------------	
    -- Clock process ------------------------------------
    clk_process : process
    begin
          
        i_clk_tb <= '0';
        wait for clk_period / 2;
        i_clk_tb <= '1';
        wait for clk_period / 2;
        
    end process;
    
	-----------------------------------------------------
	
	-- Test Plan Process --
	test_proc : process
	begin
	   -- test1
	   i_reset_tb <= '1';
	   wait for clk_period*2;
	   i_reset_tb <= '0';
	   wait for clk_period*2;
	   assert (o-lights_L_tb ="000" and o_lights_R_tb = "000")
	        report "RESET failed" severity error;

        -- TEST 2
        i_left_tb <= '1';
        wait for clk_period; -- L1
        assert (o_lights_L_tb = "001") report "Left L1 failed" severity error;

        wait for clk_period; -- L2
        assert (o_lights_L_tb = "011") report "Left L2 failed" severity error;

        wait for clk_period; -- L3
        assert (o_lights_L_tb = "111") report "Left L3 failed" severity error;

        wait for clk_period; -- OFF
        assert (o_lights_L_tb = "000") report "Left OFF failed" severity error;
        i_left_tb <= '0';

        -- TEST 3
        i_right_tb <= '1';
        wait for clk_period; -- R1
        assert (o_lights_R_tb = "001") report "Right R1 failed" severity error;

        wait for clk_period; -- R2
        assert (o_lights_R_tb = "011") report "Right R2 failed" severity error;

        wait for clk_period; -- R3
        assert (o_lights_R_tb = "111") report "Right R3 failed" severity error;

        wait for clk_period; -- OFF
        assert (o_lights_R_tb = "000") report "Right OFF failed" severity error;
        i_right_tb <= '0';

        -- TEST 4
        i_left_tb <= '1';
        i_right_tb <= '1';
        wait for clk_period; -- ON
        assert (o_lights_L_tb = "111" and o_lights_R_tb = "111") 
        report "Hazard ON failed" severity error;

        wait for clk_period; -- OFF
        assert (o_lights_L_tb = "000" and o_lights_R_tb = "000") 
        report "Hazard OFF failed" severity error;
        i_left_tb <= '0';
        i_right_tb <= '0';

        -- TEST 5
        i_left_tb <= '1';
        wait for clk_period; -- L1
        i_left_tb <= '0';  -- release early
        wait for clk_period; -- L2
        assert (o_lights_L_tb = "011") 
        report "Left mid-release L2 failed" severity error;
        wait for clk_period; -- L3
        assert (o_lights_L_tb = "111") 
        report "Left mid-release L3 failed" severity error;
        wait for clk_period; -- OFF
        assert (o_lights_L_tb = "000") 
        report "Left mid-release OFF failed" severity error;

        -- TEST 6
        i_right_tb <= '1';
        wait for clk_period; -- R1
        i_right_tb <= '0'; -- release early
        wait for clk_period; -- R2
        assert (o_lights_R_tb = "011")
        report "Right mid-release R2 failed" severity error;
        wait for clk_period; -- R3
        assert (o_lights_R_tb = "111") 
        report "Right mid-release R3 failed" severity error;
        wait for clk_period; -- OFF
        assert (o_lights_R_tb = "000")
        report "Right mid-release OFF failed" severity error;
        -- TEST 7
        i_left_tb <= '1';
        i_right_tb <= '1';
        wait for clk_period; -- on
        i_left_tb <= '0';
        i_right_tb <= '0';
        wait for clk_period; -- of
        assert (o_lights_L_tb = "000" and o_lights_R_tb = "000") 
        report "Hazard mid-release failed" severity error;
        -- End simulation
        wait;
    end process;

end test_bench;
	   
	

