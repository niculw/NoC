-------------------------------------------------------------------------------
-- Title       : Router Testbench
-- Project     : NoC in FPGA
-------------------------------------------------------------------------------
-- File        : tb_router.vhd
-- Author      : Nicolai Weis Hansen <s154662@student.dtu.dk>
-- Company     : DTU
-- Created     : Mon Jun 18 11:51:26 2018
-- Last update : Mon Jun 18 21:24:34 2018
-- Platform    : Nexys 4DDR
-- Standard    : <VHDL-2008>
-------------------------------------------------------------------------------
-- Copyright (c) 2018 DTU
-------------------------------------------------------------------------------
-- Description: Test of a router
-------------------------------------------------------------------------------
-- Revisions:  Revisions and documentation are controlled by
-- the revision control system (RCS).  The RCS should be consulted
-- on revision history.
-------------------------------------------------------------------------------



library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_router is
end tb_router;

architecture tb of tb_router is

    component router
        port (valid_in_N  : in std_logic;
              data_in_N   : in unsigned (31 downto 0);
              valid_in_S  : in std_logic;
              data_in_S   : in unsigned (31 downto 0);
              valid_in_E  : in std_logic;
              data_in_E   : in unsigned (31 downto 0);
              valid_in_W  : in std_logic;
              data_in_W   : in unsigned (31 downto 0);
              valid_in_L  : in std_logic;
              data_in_L   : in unsigned (31 downto 0);
              valid_out_N : out std_logic;
              data_out_N  : out unsigned (31 downto 0);
              valid_out_S : out std_logic;
              data_out_S  : out unsigned (31 downto 0);
              valid_out_E : out std_logic;
              data_out_E  : out unsigned (31 downto 0);
              valid_out_W : out std_logic;
              data_out_W  : out unsigned (31 downto 0);
              valid_out_L : out std_logic;
              data_out_L  : out unsigned (31 downto 0);
              clock       : in std_logic;
              reset       : in std_logic);
    end component;

    signal valid_in_N  : std_logic;
    signal data_in_N   : unsigned (31 downto 0);
    signal valid_in_S  : std_logic;
    signal data_in_S   : unsigned (31 downto 0);
    signal valid_in_E  : std_logic;
    signal data_in_E   : unsigned (31 downto 0);
    signal valid_in_W  : std_logic;
    signal data_in_W   : unsigned (31 downto 0);
    signal valid_in_L  : std_logic;
    signal data_in_L   : unsigned (31 downto 0);
    signal valid_out_N : std_logic;
    signal data_out_N  : unsigned (31 downto 0);
    signal valid_out_S : std_logic;
    signal data_out_S  : unsigned (31 downto 0);
    signal valid_out_E : std_logic;
    signal data_out_E  : unsigned (31 downto 0);
    signal valid_out_W : std_logic;
    signal data_out_W  : unsigned (31 downto 0);
    signal valid_out_L : std_logic;
    signal data_out_L  : unsigned (31 downto 0);
    signal clock       : std_logic;
    signal reset       : std_logic;

    constant TbPeriod : time := 100 ns; -- EDIT Put right period here
    signal TbClock : std_logic := '1';
    signal TbSimEnded : std_logic := '0';

begin

    dut : router
    port map (valid_in_N  => valid_in_N,
              data_in_N   => data_in_N,
              valid_in_S  => valid_in_S,
              data_in_S   => data_in_S,
              valid_in_E  => valid_in_E,
              data_in_E   => data_in_E,
              valid_in_W  => valid_in_W,
              data_in_W   => data_in_W,
              valid_in_L  => valid_in_L,
              data_in_L   => data_in_L,
              valid_out_N => valid_out_N,
              data_out_N  => data_out_N,
              valid_out_S => valid_out_S,
              data_out_S  => data_out_S,
              valid_out_E => valid_out_E,
              data_out_E  => data_out_E,
              valid_out_W => valid_out_W,
              data_out_W  => data_out_W,
              valid_out_L => valid_out_L,
              data_out_L  => data_out_L,
              clock       => clock,
              reset       => reset);

    -- Clock generation
    TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';

    -- EDIT: Check that clock is really your main clock signal
    clock <= TbClock;

    stimuli : process
    begin
        -- EDIT Adapt initialization as needed
        valid_in_N <= '0';
        data_in_N <= (others => '0');
        valid_in_S <= '0';
        data_in_S <= (others => '0');
        valid_in_E <= '0';
        data_in_E <= (others => '0');
        valid_in_W <= '0';
        data_in_W <= (others => '0');
        valid_in_L <= '0';
        data_in_L <= (others => '0');

        -- Reset generation
        -- EDIT: Check that reset is really your reset signal
        reset <= '1';
        wait for 100 ns;
        reset <= '0';
        wait for 100 ns;

        data_in_N <= x"00011013";--W
        valid_in_N <= '1';
        wait for 3 * TbPeriod;
        data_in_N <= x"00011012";--E
        wait for 3 * TbPeriod;
        data_in_N <= x"00011011";--S
        wait for 3 * TbPeriod;
        data_in_N <= x"00011010";--L
        wait for 3 * TbPeriod;

        valid_in_N <= '0';
        data_in_S <= x"00011013";--W
        valid_in_S <= '1';
        wait for 3 * TbPeriod;
        data_in_S <= x"00011012";--E
        wait for 3 * TbPeriod;
        data_in_S <= x"00011011";--L
        wait for 3 * TbPeriod;
        data_in_S <= x"00011010";--N
        wait for 3 * TbPeriod;

        valid_in_S <= '0';
        data_in_E <= x"00011013";--W
        valid_in_E <= '1';
        wait for 3 * TbPeriod;
        data_in_E <= x"00011012";--L
        wait for 3 * TbPeriod;
        data_in_E <= x"00011011";--S
        wait for 3 * TbPeriod;
        data_in_E <= x"00011010";--N
        wait for 3 * TbPeriod;

        valid_in_E <= '0';
        data_in_W <= x"00011013";--L
        valid_in_W <= '1';
        wait for 3 * TbPeriod;
        data_in_W <= x"00011012";--E
        wait for 3 * TbPeriod;
        data_in_W <= x"00011011";--S
        wait for 3 * TbPeriod;
        data_in_W <= x"00011010";--N
        wait for 3 * TbPeriod;

        valid_in_W <= '0';


        
        data_in_L <= x"00011013";--W
        valid_in_L <= '1';
        wait for 3 * TbPeriod;
        data_in_L <= x"00011012";--E
        wait for 3 * TbPeriod;
        data_in_L <= x"00011011";--S
        wait for 3 * TbPeriod;
        data_in_L <= x"00011010";--N
        wait for 3 * TbPeriod;

        valid_in_L <= '0';

        data_in_S <= x"00011013";--W
        valid_in_S <= '1';
        data_in_L <= x"00011012";--E
        valid_in_L <= '1';
        wait for 3 * TbPeriod;
        data_in_S <= x"00011012";--E
        data_in_L <= x"00011013";--W
        wait for 3 * TbPeriod;
        data_in_S <= x"00011011";--L
        data_in_L <= x"00011010";--N
        wait for 3 * TbPeriod;
        data_in_S <= x"00011010";--N
        data_in_L <= x"00011011";--S
        wait for 3 * TbPeriod;

        valid_in_S <= '0';
        valid_in_L <= '0';

        

        -- EDIT Add stimuli here
        wait for 3 * TbPeriod;

        -- Stop the clock and hence terminate the simulation
        TbSimEnded <= '1';
        wait;
    end process;

end tb;

-- Configuration block below is required by some simulators. Usually no need to edit.

configuration cfg_tb_router of tb_router is
    for tb
    end for;
end cfg_tb_router;