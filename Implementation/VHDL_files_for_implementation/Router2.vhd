-------------------------------------------------------------------------------
-- Title       : Router Top Entity
-- Project     : NoC in FPGA
-------------------------------------------------------------------------------
-- File        : Router.vhd
-- Author      : Nicolai Weis Hansen <s154662@student.dtu.dk>
-- Company     : DTU
-- Created     : Mon Apr 23 00:39:00 2018
-- Last update : Thu Jun 21 03:43:41 2018
-- Platform    : Nexys 4DDR
-- Standard    : <VHDL-2008>
-------------------------------------------------------------------------------
-- Copyright (c) 2018 DTU
-------------------------------------------------------------------------------
-- Description: Top entity to create single router
-------------------------------------------------------------------------------
-- Revisions:  Revisions and documentation are controlled by
-- the revision control system (RCS).  The RCS should be consulted
-- on revision history.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity router is
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
end entity router;

architecture comb of router is
	
	
	--------------------------------------------------------------------------------
	-- Fifo component
	--------------------------------------------------------------------------------
	
	component fifo is
		port (
			i_rst_sync : in std_logic;
			i_clk      : in std_logic;
			
			-- FIFO Write Interface
			i_wr_en   : in  std_logic;
			i_wr_data : in  std_logic_vector(31 downto 0);
			o_af      : out std_logic;
			o_full    : out std_logic;
			
			-- FIFO Read Interface
			i_rd_en   : in  std_logic;
			o_rd_data : out std_logic_vector(31 downto 0);
			o_ae      : out std_logic;
			o_empty   : out std_logic
		);
	end component fifo;
	--------------------------------------------------------------------------------
	-- Arbiter component
	--------------------------------------------------------------------------------
	
	component Arbiter is
		port (
			-- inputs
			data0  : in unsigned(31 downto 0);
			empty0 : in std_logic;
			
			data1  : in unsigned(31 downto 0);
			empty1 : in std_logic;
			
			data2  : in unsigned(31 downto 0);
			empty2 : in std_logic;
			
			data3  : in unsigned(31 downto 0);
			empty3 : in std_logic;
			
			-- general inputs
			clock : in std_logic;
			reset : in std_logic;
			
			-- outputs
			rd_en0 : out std_logic;
			rd_en1 : out std_logic;
			rd_en2 : out std_logic;
			rd_en3 : out std_logic;
			
			valid : out std_logic; -- Signal so splitter knows it needs to listen
			
			data_out : out unsigned(31 downto 0)
		);
	end component Arbiter;
	--------------------------------------------------------------------------------
	-- Splitter component
	--------------------------------------------------------------------------------
	
	component Splitter is
		port (
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
		);
	end component Splitter;
	
	signal data_fifo_N : unsigned(31 downto 0);
	signal data_fifo_S : unsigned(31 downto 0);
	signal data_fifo_E : unsigned(31 downto 0);
	signal data_fifo_W : unsigned(31 downto 0);
	signal data_fifo_L : unsigned(31 downto 0);
	
	type bit_fifo is array (natural range <>) of std_logic;
	
	signal i_wr_en : bit_fifo(19 downto 0);
	signal o_af    : bit_fifo(19 downto 0);
	signal o_full  : bit_fifo(19 downto 0);
	
	signal i_rd_en : bit_fifo(19 downto 0);
	type data_out_fifo is array (natural range <>) of std_logic_vector(31 downto 0);
	signal o_rd_data : data_out_fifo(19 downto 0);
	signal o_ae      : bit_fifo(19 downto 0);
	signal o_empty   : bit_fifo(19 downto 0);
	
begin
	
	--------------------------------------------------------------------------------
	-- Splitter
	--------------------------------------------------------------------------------
		N_splitter : Splitter port map (
			valid    => valid_in_N,
			clock    => clock,
			reset    => reset,
			data_in  => data_in_N,
			data_out => data_fifo_N,
			wr_en_N  => i_wr_en(16),
			wr_en_S  => i_wr_en(4),
			wr_en_E  => i_wr_en(8),
			wr_en_W  => i_wr_en(12) 
		);
		S_splitter : Splitter port map (
			valid    => valid_in_S,
			clock    => clock,
			reset    => reset,
			data_in  => data_in_S,
			data_out => data_fifo_S,
			wr_en_N  => i_wr_en(1),
			wr_en_S  => i_wr_en(17),
			wr_en_E  => i_wr_en(9),
			wr_en_W  => i_wr_en(13) 
		);
		E_splitter : Splitter port map (
			valid    => valid_in_E,
			clock    => clock,
			reset    => reset,
			data_in  => data_in_E,
			data_out => data_fifo_E,
			wr_en_N  => i_wr_en(2),
			wr_en_S  => i_wr_en(6),
			wr_en_E  => i_wr_en(18),
			wr_en_W  => i_wr_en(14)
		);
		W_splitter : Splitter port map (
			valid    => valid_in_W,
			clock    => clock,
			reset    => reset, 
			data_in  => data_in_W, 
			data_out => data_fifo_W, 
			wr_en_N  => i_wr_en(3), 
			wr_en_S  => i_wr_en(7), 
			wr_en_E  => i_wr_en(11), 
			wr_en_W  => i_wr_en(19) 
		);
		L_splitter : Splitter port map (
			valid    => valid_in_L, 
			clock    => clock, 
			reset    => reset, 
			data_in  => data_in_L, 
			data_out => data_fifo_L, 
			wr_en_N  => i_wr_en(0),
			wr_en_S  => i_wr_en(5), 
			wr_en_E  => i_wr_en(10),
			wr_en_W  => i_wr_en(15) 
		);
	
	--------------------------------------------------------------------------------
	-- Generate FiFos
	--------------------------------------------------------------------------------
	
	
	fifo_gen : for i in 19 downto 0 generate
	begin
		fifo_from_north : if (i = 4 or i = 8 or i = 12 or i = 16) generate
		begin
			fifo_N : fifo
				port map (
					i_rst_sync => reset,
					i_clk      => clock, 
					i_wr_en    => i_wr_en(i),
					i_wr_data  => std_logic_vector(data_fifo_N),
					o_af       => o_af(i),
					o_full     => o_full(i),
					i_rd_en    => i_rd_en(i),
					o_rd_data  => o_rd_data(i),
					o_ae       => o_ae(i),
					o_empty    => o_empty(i)
				);
		end generate fifo_from_north;
		fifo_from_south : if (i = 1 or i = 9 or i = 13 or i = 17) generate
		begin
			fifo_S : fifo
				port map (
					i_rst_sync => reset,
					i_clk      => clock, 
					i_wr_en    => i_wr_en(i),
					i_wr_data  => std_logic_vector(data_fifo_S),
					o_af       => o_af(i),
					o_full     => o_full(i),
					i_rd_en    => i_rd_en(i),
					o_rd_data  => o_rd_data(i),
					o_ae       => o_ae(i),
					o_empty    => o_empty(i)
				);
		end generate fifo_from_south;
		fifo_from_east : if (i = 2 or i = 6 or i = 14 or i = 18) generate
		begin
			fifo_E : fifo
				port map (
					i_rst_sync => reset,
					i_clk      => clock, 
					i_wr_en    => i_wr_en(i),
					i_wr_data  => std_logic_vector(data_fifo_E),
					o_af       => o_af(i),
					o_full     => o_full(i),
					i_rd_en    => i_rd_en(i),
					o_rd_data  => o_rd_data(i),
					o_ae       => o_ae(i),
					o_empty    => o_empty(i)
				);
		end generate fifo_from_east;
		fifo_from_west : if (i = 3 or i = 7 or i = 11 or i = 19) generate
		begin
			fifo_W : fifo
				port map (
					i_rst_sync => reset,
					i_clk      => clock, 
					i_wr_en    => i_wr_en(i),
					i_wr_data  => std_logic_vector(data_fifo_W),
					o_af       => o_af(i),
					o_full     => o_full(i),
					i_rd_en    => i_rd_en(i),
					o_rd_data  => o_rd_data(i),
					o_ae       => o_ae(i),
					o_empty    => o_empty(i)
				);
		end generate fifo_from_west;
		fifo_from_local : if (i = 0 or i = 5 or i = 10 or i = 15) generate
		begin
			fifo_L : fifo
				port map (
					i_rst_sync => reset,
					i_clk      => clock, 
					i_wr_en    => i_wr_en(i),
					i_wr_data  => std_logic_vector(data_fifo_L),
					o_af       => o_af(i),
					o_full     => o_full(i),
					i_rd_en    => i_rd_en(i),
					o_rd_data  => o_rd_data(i),
					o_ae       => o_ae(i),
					o_empty    => o_empty(i)
				);
		end generate fifo_from_local;
	end generate fifo_gen;
	--------------------------------------------------------------------------------
	-- Arbiter
	--------------------------------------------------------------------------------
		N_arbiter : Arbiter port map (
			data0    => unsigned(o_rd_data(0)),
			empty0   => o_empty(0),
			data1    => unsigned(o_rd_data(1)),
			empty1   => o_empty(1),
			data2    => unsigned(o_rd_data(2)),
			empty2   => o_empty(2),
			data3    => unsigned(o_rd_data(3)),
			empty3   => o_empty(3),
			clock    => clock,
			reset    => reset,
			rd_en0   => i_rd_en(0),
			rd_en1   => i_rd_en(1),
			rd_en2   => i_rd_en(2),
			rd_en3   => i_rd_en(3),
			valid    => valid_out_N, 
			data_out => data_out_N
		);
		S_arbiter : Arbiter port map (
			data0    => unsigned(o_rd_data(4)),
			empty0   => o_empty(4),
			data1    => unsigned(o_rd_data(5)),
			empty1   => o_empty(5),
			data2    => unsigned(o_rd_data(6)),
			empty2   => o_empty(6),
			data3    => unsigned(o_rd_data(7)),
			empty3   => o_empty(7),
			clock    => clock,
			reset    => reset,
			rd_en0   => i_rd_en(4),
			rd_en1   => i_rd_en(5),
			rd_en2   => i_rd_en(6),
			rd_en3   => i_rd_en(7),
			valid    => valid_out_S, 
			data_out => data_out_S
		);
		E_arbiter : Arbiter port map (
			data0    => unsigned(o_rd_data(8)),
			empty0   => o_empty(8),
			data1    => unsigned(o_rd_data(9)),
			empty1   => o_empty(9),
			data2    => unsigned(o_rd_data(10)),
			empty2   => o_empty(10),
			data3    => unsigned(o_rd_data(11)),
			empty3   => o_empty(11),
			clock    => clock,
			reset    => reset,
			rd_en0   => i_rd_en(8),
			rd_en1   => i_rd_en(9),
			rd_en2   => i_rd_en(10),
			rd_en3   => i_rd_en(11),
			valid    => valid_out_E, 
			data_out => data_out_E
		);
		W_arbiter : Arbiter port map (
			data0    => unsigned(o_rd_data(12)),
			empty0   => o_empty(12),
			data1    => unsigned(o_rd_data(13)),
			empty1   => o_empty(13),
			data2    => unsigned(o_rd_data(14)),
			empty2   => o_empty(14),
			data3    => unsigned(o_rd_data(15)),
			empty3   => o_empty(15),
			clock    => clock,
			reset    => reset,
			rd_en0   => i_rd_en(12),
			rd_en1   => i_rd_en(13),
			rd_en2   => i_rd_en(14),
			rd_en3   => i_rd_en(15),
			valid    => valid_out_W, 
			data_out => data_out_W
		);
		L_arbiter : Arbiter port map (
			data0    => unsigned(o_rd_data(16)),
			empty0   => o_empty(16),
			data1    => unsigned(o_rd_data(17)),
			empty1   => o_empty(17),
			data2    => unsigned(o_rd_data(18)),
			empty2   => o_empty(18),
			data3    => unsigned(o_rd_data(19)),
			empty3   => o_empty(19),
			clock    => clock,
			reset    => reset,
			rd_en0   => i_rd_en(16),
			rd_en1   => i_rd_en(17),
			rd_en2   => i_rd_en(18),
			rd_en3   => i_rd_en(19),
			valid    => valid_out_L, 
			data_out => data_out_L
		);
	
end architecture comb;





















