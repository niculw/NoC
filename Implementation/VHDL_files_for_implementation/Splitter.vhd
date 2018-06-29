-------------------------------------------------------------------------------
-- Title       : Splitter
-- Project     : NoC in FPGA
-------------------------------------------------------------------------------
-- File        : Splitter.vhd
-- Author      : Nicolai Weis Hansen <s154662@student.dtu.dk>
-- Company     : DTU
-- Created     : Tue Mar 27 02:15:58 2018
-- Last update : Thu Jun 21 20:15:59 2018
-- Platform    : Nexys 4DDR
-- Standard    : <VHDL-2008>
-------------------------------------------------------------------------------
-- Copyright (c) 2018 DTU
-------------------------------------------------------------------------------
-- Description: Splits input to router and decides route of packages
-------------------------------------------------------------------------------
-- Revisions:  Revisions and documentation are controlled by
-- the revision control system (RCS).  The RCS should be consulted
-- on revision history.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Splitter is
	port(
		-- valid flag
		valid : in std_logic;
		
		-- general inputs
		clock : in std_logic;
		reset : in std_logic;
		
		-- inputs
		data_in : in unsigned(31 downto 0);
		
		-- outputs
		data_out : out unsigned(31 downto 0);
		
		wr_en_N : out std_logic;
		wr_en_S : out std_logic;
		wr_en_E : out std_logic;
		wr_en_W : out std_logic
	); -- local
	
end entity Splitter;

architecture behaviour of Splitter is
	
	signal package_counter, package_counter_next : unsigned(1 downto 0);
	signal wr_en_N_curr, wr_en_N_prev            : std_logic;
	signal wr_en_S_curr, wr_en_S_prev            : std_logic;
	signal wr_en_E_curr, wr_en_E_prev            : std_logic;
	signal wr_en_W_curr, wr_en_W_prev            : std_logic;
	
begin
	
	--------------------------------------------------------------------------------
	-- FSM
	--------------------------------------------------------------------------------
	Routing : process(all) is
	begin
		wr_en_N      <= wr_en_N_curr;
		wr_en_S      <= wr_en_S_curr;
		wr_en_E      <= wr_en_E_curr;
		wr_en_W      <= wr_en_W_curr;
		wr_en_N_curr <= wr_en_N_prev;
		wr_en_S_curr <= wr_en_S_prev;
		wr_en_E_curr <= wr_en_E_prev;
		wr_en_W_curr <= wr_en_W_prev;
		wr_en_N_curr <= '0';
		wr_en_S_curr <= '0';
		wr_en_E_curr <= '0';
		wr_en_W_curr <= '0'; 
		if (valid = '1' and package_counter = 0) then
			if (data_in(1 downto 0) = "00") then
				wr_en_N_curr <= '1';
			elsif (data_in(1 downto 0) = "01") then
				wr_en_S_curr <= '1';
			elsif (data_in(1 downto 0) = "10") then
				wr_en_E_curr <= '1';
			elsif (data_in(1 downto 0) = "11") then
				wr_en_W_curr <= '1';
			end if;
			data_out <= data_in srl 2;
		elsif(valid = '1') then
			data_out <= data_in;
			if(wr_en_N_prev = '1') then
				wr_en_N_curr <= '1';
			elsif(wr_en_S_prev = '1') then
				wr_en_S_curr <= '1';
			elsif(wr_en_E_prev = '1') then
				wr_en_E_curr <= '1';
			elsif(wr_en_W_prev = '1') then
				wr_en_W_curr <= '1';
			end if;
		else
			data_out <= data_in;
		end if;
		
	end process; -- Routing
	--------------------------------------------------------------------------------
	-- Valid/Ready
	--------------------------------------------------------------------------------
	Sending : process(all) is
	begin
		package_counter_next <= package_counter;
		if (valid = '1' and package_counter <= 2) then
			if (package_counter = 2) then
				package_counter_next <= (others => '0');
			else
				package_counter_next <= package_counter + 1; 
			end if;
			
		end if;
		
	end process; -- Sending
	
	--------------------------------------------------------------------------------
	-- Clocking
	--------------------------------------------------------------------------------
	Clocking : process(all) is
	begin
		if (reset = '1') then
			package_counter <= (others => '0');
			wr_en_N_prev    <= '0';
			wr_en_S_prev    <= '0';
			wr_en_E_prev    <= '0';
			wr_en_W_prev    <= '0';
			
			
		elsif rising_edge(clock) then
			wr_en_N_prev <= wr_en_N_curr;
			wr_en_S_prev <= wr_en_S_curr;
			wr_en_E_prev <= wr_en_E_curr;
			wr_en_W_prev <= wr_en_W_curr;
			
			package_counter <= package_counter_next;
		end if;
	end process; -- Clocking
	
end architecture behaviour;