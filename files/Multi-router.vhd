-------------------------------------------------------------------------------
-- Title       : Multi Router
-- Project     : NoC in FPGA
-------------------------------------------------------------------------------
-- File        : Multi-router.vhd
-- Author      : Nicolai Weis Hansen <s154662@student.dtu.dk>
-- Company     : DTU
-- Created     : Mon Jun  4 09:50:26 2018
-- Last update : Sun Jun 17 01:00:58 2018
-- Platform    : Nexys 4DDR
-- Standard    : <VHDL-2008>
-------------------------------------------------------------------------------
-- Copyright (c) 2018 DTU
-------------------------------------------------------------------------------
-- Description: Connection of routers to make a torus network
-------------------------------------------------------------------------------
-- Revisions:  Revisions and documentation are controlled by
-- the revision control system (RCS).  The RCS should be consulted
-- on revision history.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;

entity noc is
	port (
		-- input
		valid_in_local : in valid;
		data_in_local  : in data;
		-- output
		valid_out_local : out valid;
		data_out_local  : out data;
		--generals
		clock : in std_logic;
		reset : in std_logic
		
	);
end entity noc;

architecture design of noc is
	
	component router is
		port (
			-- inputs
			valid_in_N : in std_logic;
			data_in_N  : in unsigned(31 downto 0);
			
			valid_in_S : in std_logic;
			data_in_S  : in unsigned(31 downto 0);
			
			valid_in_E : in std_logic;
			data_in_E  : in unsigned(31 downto 0);
			
			valid_in_W : in std_logic;
			data_in_W  : in unsigned(31 downto 0);
			
			valid_in_L : in std_logic;
			data_in_L  : in unsigned(31 downto 0);
			
			-- outputs
			valid_out_N : out std_logic;
			data_out_N  : out unsigned(31 downto 0);
			
			valid_out_S : out std_logic;
			data_out_S  : out unsigned(31 downto 0);
			
			valid_out_E : out std_logic;
			data_out_E  : out unsigned(31 downto 0);
			
			valid_out_W : out std_logic;
			data_out_W  : out unsigned(31 downto 0);
			
			valid_out_L : out std_logic;
			data_out_L  : out unsigned(31 downto 0);
			
			-- general signals
			clock : in std_logic;
			reset : in std_logic
		);
	end component router;
	
	signal valid_in_N : valid;
	signal valid_in_S : valid;
	signal valid_in_E : valid;
	signal valid_in_W : valid;
	--signal valid_in_L : valid;
	
	signal data_in_N : data;
	signal data_in_S : data;
	signal data_in_E : data;
	signal data_in_W : data;
	--signal data_in_L : data;
	
	signal valid_out_N : valid;
	signal valid_out_S : valid;
	signal valid_out_E : valid;
	signal valid_out_W : valid;
	--signal valid_out_L : valid;
	
	signal data_out_N : data;
	signal data_out_S : data;
	signal data_out_E : data;
	signal data_out_W : data;
	--signal data_out_L : data;
	
	
begin
	noc_x : for i in 0 to 3 generate
		noc_y : for j in 0 to 3 generate
			router_inst : router
				port map (
					-- inputs
					valid_in_N => valid_in_N(i,j),
					data_in_N  => data_in_N(i,j),
					
					valid_in_S => valid_in_S(i,j),
					data_in_S  => data_in_S(i,j),
					
					valid_in_E => valid_in_E(i,j),
					data_in_E  => data_in_E(i,j),
					
					valid_in_W => valid_in_W(i,j),
					data_in_W  => data_in_W(i,j),
					
					valid_in_L => valid_in_local(i,j),
					data_in_L  => data_in_local(i,j),
					
					-- outputs
					valid_out_N => valid_out_N(i,j),
					data_out_N  => data_out_N(i,j),
					
					valid_out_S => valid_out_S(i,j),
					data_out_S  => data_out_S(i,j),
					
					valid_out_E => valid_out_E(i,j),
					data_out_E  => data_out_E(i,j),
					
					valid_out_W => valid_out_W(i,j),
					data_out_W  => data_out_W(i,j), 
					
					valid_out_L => valid_out_local(i,j),
					data_out_L  => data_out_local(i,j), 
					
					-- general signals
					clock => clock,
					reset => reset
				);
		end generate;
	end generate;
	
	EW_connect_x : for i in 0 to 3 generate
		EW_connect_y : for j in 0 to 3 generate
			torus : if (i = 0) generate
				data_in_E(3,j)  <= data_out_W(i,j);
				valid_in_E(3,j) <= valid_out_W(i,j);
				data_in_W(i,j)  <= data_out_E(3,j);
				valid_in_W(i,j) <= valid_out_E(3,j);
			end generate torus;
			mesh : if (i = 3 or i = 1 or i = 2) generate
				data_in_E(i-1,j)  <= data_out_W(i,j);
				valid_in_E(i-1,j) <= valid_out_W(i,j);
				data_in_W(i,j)    <= data_out_E(i-1,j);
				valid_in_W(i,j)   <= valid_out_E(i-1,j);
			end generate mesh;
		end generate EW_connect_y;
	end generate EW_connect_x;

	NS_connect_x : for i in 0 to 3 generate
		NS_connect_y : for j in 0 to 3 generate
			torus : if (j = 3) generate
				data_in_N(i,0) <= data_out_S(i,j);
				valid_in_N(i,0) <= valid_out_S(i,j);
				data_in_S(i,j) <= data_out_N(i,0);
				valid_in_S(i,j) <= valid_out_N(i,0);
			end generate torus;
			mesh : if (j = 0 or j = 1 or j = 2) generate
				data_in_N(i,j+1) <= data_out_S(i,j);
				valid_in_N(i,j+1) <= valid_out_S(i,j);
				data_in_S(i,j) <= data_out_N(i,j+1);
				valid_in_S(i,j) <= valid_out_N(i,j+1);
			end generate mesh;
		end generate NS_connect_y;
	end generate NS_connect_x;

end architecture design;