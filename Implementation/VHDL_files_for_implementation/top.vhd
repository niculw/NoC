library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.types.all;

entity top is
	port (
		clock : in std_logic;
		reset : in std_logic;
		
		serial_tx : in  std_logic;
		serial_rx : out std_logic;
		
		led  : out std_logic_vector(4 downto 0);
		led2 : out std_logic_vector(5 downto 0)
	);
	
end entity top;

architecture stucture of top is
	
	-- The accelerator clock frequency will be (100MHz/CLK_DIVISION_FACTOR)
	constant CLK_DIVISION_FACTOR : integer := 2; --(1 to 7)
	type data2 is array (integer range 0 to 3, integer range 0 to 3) of std_logic_vector(31 downto 0);
	signal valid_in_local  : valid;
	signal data_in_local   : data ;
	signal valid_out_local : valid;
	signal data_out_local  : data;
	
	signal data_stream_in      : std_logic_vector(7 downto 0);
	signal data_stream_in_stb  : std_logic;
	signal data_stream_in_ack  : std_logic;
	signal data_stream_out     : std_logic_vector(7 downto 0);
	signal data_stream_out_stb : std_logic;
	
	signal data_out   : unsigned(31 downto 0);
	signal rd_en      : std_logic;
	signal fifo_empty : std_logic;
	signal wr_en      : std_logic;
	signal clk : std_logic;
	
begin
	clock_divider_inst : entity work.clock_divider
		generic map(
			DIVIDE => CLK_DIVISION_FACTOR
		)
		port map(
			clk_in  => clock,
			clk_out => clk
		);
	
	controller_inst : entity work.controller
		port map(
			clock => clk,
			reset => reset, 
			-- tx and rx are form the fsm poiont of view rx <= tx
			data_stream_tx     => data_stream_in,
			data_stream_tx_stb => data_stream_in_stb,
			data_stream_tx_ack => data_stream_in_ack,
			data_stream_rx     => data_stream_out,
			data_stream_rx_stb => data_stream_out_stb,
			
			-- data to the network
			-- input 0,0 to 3,3
			valid_in_local => valid_out_local,
			data_in_local  => data_out_local,
			-- output to 0,0
			fifo_empty   => fifo_empty,
			rd_en        => rd_en,
			wr_en        => wr_en,
			valid_out    => valid_in_local(0,0),
			data_to_fifo => data_out,
			led          => led,
			led2         => led2
		);
	
	fifo_inst : entity work.fifo
		port map(
			i_rst_sync => reset,
			i_clk      => clk,
			
			-- FIFO Write Interface
			i_wr_en   => wr_en,
			i_wr_data => std_logic_vector(data_out),
			o_af      => open,
			o_full    => open,
			
			-- FIFO Read Interface
			i_rd_en             => rd_en,
			unsigned(o_rd_data) => data_in_local(0,0),
			o_ae    => open,
			o_empty => fifo_empty
		);
	
	noc_inst : entity work.noc
		port map (
			-- input
			valid_in_local => valid_in_local,
			data_in_local  => data_in_local,
			-- output
			valid_out_local => valid_out_local,
			data_out_local  => data_out_local,
			--generals
			clock => clk,
			reset => reset
		);
	
	uart_inst : entity work.uart
		generic map(
			baud            => 115200,
			clock_frequency => positive(100_000_000/CLK_DIVISION_FACTOR)
		)
		port map(
			clock               => clk,
			reset               => reset,
			data_stream_in      => data_stream_in,
			data_stream_in_stb  => data_stream_in_stb,
			data_stream_in_ack  => data_stream_in_ack,
			data_stream_out     => data_stream_out,
			data_stream_out_stb => data_stream_out_stb,
			tx                  => serial_rx,
			rx                  => serial_tx
		);
	
end architecture stucture;