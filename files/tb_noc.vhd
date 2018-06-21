-------------------------------------------------------------------------------
-- Title       : NoC testbench
-- Project     : NoC in FPGA
-------------------------------------------------------------------------------
-- File        : tb_noc.vhd
-- Author      : Nicolai Weis Hansen <s154662@student.dtu.dk>
-- Company     : DTU
-- Created     : Mon Jun 18 11:50:14 2018
-- Last update : Wed Jun 20 22:50:36 2018
-- Platform    : Nexys 4DDR
-- Standard    : <VHDL-2008>
-------------------------------------------------------------------------------
-- Copyright (c) 2018 DTU
-------------------------------------------------------------------------------
-- Description: Test of the network
-------------------------------------------------------------------------------
-- Revisions:  Revisions and documentation are controlled by
-- the revision control system (RCS).  The RCS should be consulted
-- on revision history.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;
use std.textio.all;

entity tb_noc is
end tb_noc;

architecture tb of tb_noc is
	
	component noc
		port (valid_in_local : in valid;
			data_in_local   : in  data;
			valid_out_local : out valid;
			data_out_local  : out data;
			clock           : in  std_logic;
			reset           : in  std_logic);
	end component;
	
	signal valid_in_local                        : valid;
	signal data_in_local                         : data;
	signal valid_out_local                       : valid;
	signal data_out_local                        : data;
	signal clock                                 : std_logic;
	signal reset                                 : std_logic;
	signal package_counter, package_counter_next : unsigned(3 downto 0);
	
	constant TbPeriod              : time                 := 50 ns; -- EDIT Put right period here
	signal TbClock                 : std_logic            := '0';
	signal TbSimEnded              : std_logic            := '0';
	signal test_sim, test_sim_next : unsigned(3 downto 0) := "0000";
	
begin
	dut : noc
		port map (valid_in_local => valid_in_local,
			data_in_local   => data_in_local,
			valid_out_local => valid_out_local,
			data_out_local  => data_out_local,
			clock           => clock,
			reset           => reset);
	
	-- Clock generation
	TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';
	
	-- EDIT: Check that clock is really your main clock signal
	clock <= TbClock;
	
	stimuli : process
	begin
		-- EDIT Adapt initialization as needed
		valid_in_local <= (others => (others => '0'));
		data_in_local  <= (others => (others => (others => '0')));
		
		-- Reset generation
		-- EDIT: Check that reset is really your reset signal
		reset <= '1';
		wait for 100 ns;
		reset <= '0';
		wait for 100 ns;
		
		------------------------------------------------------------------------
		-- Choose directions
		------------------------------------------------------------------------
		--Bits to concatenate to go somewhere
		--N: 00
		--S: 01
		--E: 10
		--W: 11
		
		-- To go to local you want to do the exact opposite as previous. 
		-- So if you chose N as your last move, you want to go to S, to exit
		-- the router on the Local port.
		
		
		------------------------------------------------------------------------
		-- 
		------------------------------------------------------------------------
		
		
		-- EDIT Add stimuli here
		------------------------------------------------------------------------
		-- Test 0 input
		------------------------------------------------------------------------
		-- Can signal cross over torus net? (top to bottom, N, L) (0,0 to 0,3)
		data_in_local(0,0)(31 downto 4) <= (others => '0');
		data_in_local(0,0)(3 downto 0)  <= "01" & "00";
		valid_in_local(0,0)             <= '1';
		wait for 3 * TbPeriod;
		-- Wait for signal to arrive
		valid_in_local(0,0) <= '0';
		data_in_local(0,0)  <= (others => '0');
		wait until test_sim = 1;
		report "Test 0 passed" severity failure;
		--test_sim <= '0';
		--wait for 10 * TbPeriod;
		
		------------------------------------------------------------------------
		-- Test 1 input
		------------------------------------------------------------------------
		-- Can signal move from top left to bottom right? (W, N, L) (0,0 to 3,3)
		data_in_local(0,0)(31 downto 6) <= (others => '0');
		data_in_local(0,0)(5 downto 0)  <= "01" & "00" & "11";
		valid_in_local(0,0)             <= '1';
		wait for 3 * TbPeriod;
		valid_in_local(0,0) <= '0';
		data_in_local(0,0)  <= (others => '0');
		wait until test_sim = 2;
		report "Test 1 passed" severity failure;
		
		------------------------------------------------------------------------
		-- Test 2 input
		------------------------------------------------------------------------
		-- 2 signals. One from 0,0 to 3,3 (W,N,L) and one from 3,0 to 0,3 (E,N,L)
		data_in_local(0,0)(31 downto 6) <= (others => '0');
		data_in_local(0,0)(5 downto 0)  <= "01" & "00" & "11";
		valid_in_local(0,0)             <= '1';
		
		data_in_local(3,0)(31 downto 6) <= (others => '0');
		data_in_local(3,0)(5 downto 0)  <= "01" & "00" & "10";
		valid_in_local(3,0)             <= '1';
		
		wait for 3 * TbPeriod;
		valid_in_local(0,0) <= '0';
		data_in_local(0,0)  <= (others => '0');
		valid_in_local(3,0) <= '0';
		data_in_local(3,0)  <= (others => '0');
		
		wait until test_sim = 3;
		report "Test 2 passed" severity error;
		
		
		------------------------------------------------------------------------
		-- Test 3 input
		------------------------------------------------------------------------
		-- 3 signals agaist one router. then this router sends all 3 plus its own to the next one.
		-- 0,0 1,1 0,2 goes against 0,1. the packets from 0,0 1,1 and 0,2 all goes to the west arbiter
		-- together with a packet from 0,1. All 4 packets comes out of 3,1.
		-- Test sets a unique last 32-bit in packet from each router and then checks if these are recieved.
		
		data_in_local(0,0)(31 downto 6) <= (others => '0');
		data_in_local(0,0)(5 downto 0)  <= "10" & "11" & "01";
		valid_in_local(0,0)             <= '1';
		
		data_in_local(1,1)(31 downto 6) <= (others => '0');
		data_in_local(1,1)(5 downto 0)  <= "10" & "11" & "11";
		valid_in_local(1,1)             <= '1';
		
		data_in_local(0,2)(31 downto 6) <= (others => '0');
		data_in_local(0,2)(5 downto 0)  <= "10" & "11" & "00";
		valid_in_local(0,2)             <= '1';
		
		wait for TbPeriod;
		
		data_in_local(0,1)(31 downto 4) <= (others => '0');
		data_in_local(0,1)(3 downto 0)  <= "10" & "11";
		valid_in_local(0,1)             <= '1';
		
		wait for TbPeriod;
		
		data_in_local(0,0)(31 downto 6) <= (others => '0');
		data_in_local(0,0)(5 downto 0)  <= "00" & "00" & "01";
		
		data_in_local(1,1)(31 downto 6) <= (others => '0');
		data_in_local(1,1)(5 downto 0)  <= "00" & "00" & "10";
		
		data_in_local(0,2)(31 downto 6) <= (others => '0');
		data_in_local(0,2)(5 downto 0)  <= "00" & "00" & "11";
		
		wait for TbPeriod;
		
		valid_in_local(0,0) <= '0';
		data_in_local(0,0)  <= (others => '0');
		
		valid_in_local(1,1) <= '0';
		data_in_local(1,1)  <= (others => '0');
		
		valid_in_local(0,2) <= '0';
		data_in_local(0,2)  <= (others => '0');
		
		data_in_local(0,1)(31 downto 4) <= (others => '0');
		data_in_local(0,1)(3 downto 0)  <= "01" & "00"; 
		
		wait for TbPeriod;
		
		valid_in_local(0,1) <= '0';
		data_in_local(0,1)  <= (others => '0');
		
		wait until test_sim = 4;
		report "Test 3 passed" severity failure;
		TbSimEnded <= '1';
		
		-- Stop the clock and hence terminate the simulation
		wait;
	end process;
	
	reciever : process(all) is
	begin
		package_counter_next <= package_counter;
		test_sim_next        <= test_sim;
		
		------------------------------------------------------------------------
		-- Test 0 checker
		------------------------------------------------------------------------
		if test_sim = 0 then
			if (valid_out_local(0,3) = '1' and package_counter <= 2) then
				if (package_counter = 2) then
					package_counter_next <= (others => '0');
					test_sim_next        <= test_sim + 1; 
				else
					package_counter_next <= package_counter + 1;
				end if;
			end if;
		end if;
		
		------------------------------------------------------------------------
		-- Test 1 checker
		------------------------------------------------------------------------
		if test_sim = 1 then
			if (valid_out_local(3,3) = '1' and package_counter <= 2) then
				if (package_counter = 2) then
					package_counter_next <= (others => '0');
					test_sim_next        <= test_sim + 1; 
				else
					package_counter_next <= package_counter + 1;
				end if;
			end if;
		end if;
		
		------------------------------------------------------------------------
		-- Test 2 checker
		------------------------------------------------------------------------
		if test_sim = 2 then
			if (valid_out_local(0,3) = '1' and package_counter <= 2) then
				if (package_counter = 2) then
					package_counter_next <= (others => '0');
					test_sim_next        <= test_sim + 1; 
				else
					package_counter_next <= package_counter + 1;
				end if;
			end if;
			if (valid_out_local(3,3) = '1' and package_counter <= 2) then
				if (package_counter = 2) then
					package_counter_next <= (others => '0');
					test_sim_next        <= test_sim + 1; 
				else
					package_counter_next <= package_counter + 1;
				end if;
			end if;
		end if;
		
		------------------------------------------------------------------------
		-- Test 3 checker
		------------------------------------------------------------------------
		if test_sim = 3 then
			if data_out_local(3,1) = x"00000001" then
				package_counter_next <= package_counter + 1;
			end if;
			if data_out_local(3,1) = x"00000002" then
				package_counter_next <= package_counter + 1;
			end if;
			if data_out_local(3,1) = x"00000003" then
				package_counter_next <= package_counter + 1;
			end if;
			if data_out_local(3,1) = x"00000004" then
				package_counter_next <= package_counter + 1;
			end if;
			if (package_counter = 4) then
				package_counter_next <= (others => '0');
				test_sim_next        <= test_sim + 1;
			end if;
		end if;
	
	end process;
	
	Clocking : process(all) is
	begin
		if (reset = '1') then
			package_counter <= (others => '0');
			test_sim        <= (others => '0');
			
		elsif rising_edge(clock) then
			package_counter <= package_counter_next;
			test_sim        <= test_sim_next;
		end if;
	end process; -- Clocking
end tb;