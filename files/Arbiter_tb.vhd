-------------------------------------------------------------------------------
-- Title       : Arbiter testbench
-- Project     : NoC in FPGA
-------------------------------------------------------------------------------
-- File        : Arbiter_tb.vhd
-- Author      : Nicolai Weis Hansen <s154662@student.dtu.dk>
-- Company     : DTU
-- Created     : Sun Apr  8 14:07:22 2018
-- Last update : Thu Apr 26 22:45:13 2018
-- Platform    : Nexys 4DDR
-- Standard    : <VHDL-2008>
-------------------------------------------------------------------------------
-- Copyright (c) 2018 DTU
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Revisions:  Revisions and documentation are controlled by
-- the revision control system (RCS).  The RCS should be consulted
-- on revision history.
-------------------------------------------------------------------------------

-- Testbench automatically generated online
-- at http://vhdl.lapinoo.net
-- Generation date : 8.4.2018 14:29:18 GMT

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Arbiter_tb is
end Arbiter_tb;

architecture tb of Arbiter_tb is
  
  component Arbiter
    port (data0 : in unsigned (31 downto 0);
      empty0   : in  std_logic;
      data1    : in  unsigned (31 downto 0);
      empty1   : in  std_logic;
      data2    : in  unsigned (31 downto 0);
      empty2   : in  std_logic;
      data3    : in  unsigned (31 downto 0);
      empty3   : in  std_logic;
      clock    : in  std_logic;
      reset    : in  std_logic;
      rd_en0   : out std_logic;
      rd_en1   : out std_logic;
      rd_en2   : out std_logic;
      rd_en3   : out std_logic;
      valid    : out std_logic;
      data_out : out unsigned (31 downto 0));
  end component;
  
  signal data0    : unsigned (31 downto 0);
  signal empty0   : std_logic;
  signal data1    : unsigned (31 downto 0);
  signal empty1   : std_logic;
  signal data2    : unsigned (31 downto 0);
  signal empty2   : std_logic;
  signal data3    : unsigned (31 downto 0);
  signal empty3   : std_logic;
  signal clock    : std_logic;
  signal reset    : std_logic;
  signal rd_en0   : std_logic;
  signal rd_en1   : std_logic;
  signal rd_en2   : std_logic;
  signal rd_en3   : std_logic;
  signal valid    : std_logic;
  signal data_out : unsigned (31 downto 0);
  
  constant TbPeriod : time      := 100 ns; -- EDIT Put right period here
  signal TbClock    : std_logic := '1';
  signal TbSimEnded : std_logic := '0';
  
begin
  
  dut : Arbiter
    port map (
      data0    => data0,
      empty0   => empty0,
      data1    => data1,
      empty1   => empty1,
      data2    => data2,
      empty2   => empty2,
      data3    => data3,
      empty3   => empty3,
      clock    => clock,
      reset    => reset,
      rd_en0   => rd_en0,
      rd_en1   => rd_en1,
      rd_en2   => rd_en2,
      rd_en3   => rd_en3,
      valid    => valid,
      data_out => data_out);
  
  -- Clock generation
  TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';
  
  -- EDIT: Check that clock is really your main clock signal
  clock <= TbClock;
  
  stimuli : process
  begin
    -- EDIT Adapt initialization as needed
    data0  <= "00000000000000000000000000000100";
    empty0 <= '1';
    data1  <= "00000000001000000000000000000000";
    empty1 <= '1';
    data2  <= "00000000000000110000000000000000";
    empty2 <= '1';
    data3  <= "00001000000000011110000000000000";
    empty3 <= '1';
    
    -- Reset generation
    -- EDIT: Check that reset is really your reset signal
    reset <= '1';
    wait for 100 ns;
    reset <= '0';
    wait for 100 ns;
    
    -- EDIT Add stimuli here
    empty0 <= '0';--
    empty1 <= '1';
    empty2 <= '1';
    empty3 <= '1';
    wait for 3 * TbPeriod;
    empty0 <= '1';
    empty1 <= '0';--
    empty2 <= '1';
    empty3 <= '1';
    wait for 3 * TbPeriod;
    empty0 <= '1';
    empty1 <= '1';
    empty2 <= '0';--
    empty3 <= '1';
    wait for 3 * TbPeriod;
    empty0 <= '1';
    empty1 <= '1';
    empty2 <= '1';
    empty3 <= '0';--
    wait for 3 * TbPeriod;
    empty0 <= '0';--
    empty1 <= '1';
    empty2 <= '0';
    empty3 <= '1';
    wait for 3 * TbPeriod;
    empty0 <= '1';
    empty1 <= '0';
    empty2 <= '0';--
    empty3 <= '1';
    wait for 3 * TbPeriod;
    empty0 <= '1';
    empty1 <= '0';--
    empty2 <= '1';
    empty3 <= '0';
    wait for 3 * TbPeriod;
    empty0 <= '0';
    empty1 <= '1';
    empty2 <= '1';
    empty3 <= '0';--
    wait for 3 * TbPeriod;
    empty0 <= '0';--
    empty1 <= '1';
    empty2 <= '0';
    empty3 <= '1';
    wait for 2 * TbPeriod;
    empty0 <= '0';--
    empty1 <= '0';
    empty2 <= '0';
    empty3 <= '1';
    wait for 1 * TbPeriod;
    empty0 <= '1';
    empty1 <= '0';--
    empty2 <= '0';
    empty3 <= '1';
    wait for 3 * TbPeriod;
    empty0 <= '1';
    empty1 <= '1';
    empty2 <= '0';--
    empty3 <= '1';
    wait for 3 * TbPeriod;
    empty0 <= '1';
    empty1 <= '1';
    empty2 <= '1';
    empty3 <= '1';
    wait for 3 * TbPeriod;
    
    -- Stop the clock and hence terminate the simulation
    TbSimEnded <= '1';
    wait;
  end process;
  
end tb;

-- Configuration block below is required by some simulators. Usually no need to edit.

configuration cfg_Arbiter_tb of Arbiter_tb is
  for tb
end for;
end cfg_Arbiter_tb;