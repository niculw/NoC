-- Testbench automatically generated online
-- at http://vhdl.lapinoo.net
-- Generation date : 9.4.2018 06:15:56 GMT

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_Splitter is
end tb_Splitter;

architecture tb of tb_Splitter is

    component Splitter
        port (valid    : in std_logic;
              clock    : in std_logic;
              reset    : in std_logic;
              data_in  : in unsigned (31 downto 0);
              data_out : out unsigned (31 downto 0);
              wr_en_N  : out std_logic;
              wr_en_S  : out std_logic;
              wr_en_E  : out std_logic;
              wr_en_W  : out std_logic);
    end component;

    signal valid    : std_logic;
    signal clock    : std_logic;
    signal reset    : std_logic;
    signal data_in  : unsigned (31 downto 0);
    signal data_out : unsigned (31 downto 0);
    signal wr_en_N  : std_logic;
    signal wr_en_S  : std_logic;
    signal wr_en_E  : std_logic;
    signal wr_en_W  : std_logic;

    constant TbPeriod : time := 100 ns; -- EDIT Put right period here
    signal TbClock : std_logic := '1';
    signal TbSimEnded : std_logic := '0';

begin

    dut : Splitter
    port map (valid    => valid,
              clock    => clock,
              reset    => reset,
              data_in  => data_in,
              data_out => data_out,
              wr_en_N  => wr_en_N,
              wr_en_S  => wr_en_S,
              wr_en_E  => wr_en_E,
              wr_en_W  => wr_en_W);

    -- Clock generation
    TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';

    -- EDIT: Check that clock is really your main clock signal
    clock <= TbClock;

    stimuli : process
    begin
        -- EDIT Adapt initialization as needed
        valid <= '0';
        data_in <= (others => '0');

        -- Reset generation
        -- EDIT: Check that reset is really your reset signal
        reset <= '1';
        wait for 100 ns;
        reset <= '0';
	wait for 300 ns;
        -- EDIT Add stimuli here
        data_in <= "01010101010101010101010100110011";
        valid <= '1';
        wait for 2*TbPeriod;
        data_in <= "01010101010101010101010100110010";
        wait for TbPeriod;
        ------------------------------------------------------------------------
        -- run 300
        ------------------------------------------------------------------------
        data_in <= "01010101010101010101010100110001";
        valid <= '1';
        wait for 2*TbPeriod;
        data_in <= "01010101010101010101010100110000";
        wait for TbPeriod;
        ------------------------------------------------------------------------
        -- run 300
        ------------------------------------------------------------------------
        data_in <= "01010101010101010101010100110010";
        valid <= '1';
        wait for 2*TbPeriod;
        data_in <= "01010101010101010101010100110011";
        wait for TbPeriod;
        ------------------------------------------------------------------------
        -- run 300
        ------------------------------------------------------------------------
        data_in <= "01010101010101010101010100110000";
        valid <= '1';
        wait for 2*TbPeriod;
        data_in <= "01010101010101010101010100111001";
        wait for TbPeriod;
        ------------------------------------------------------------------------
        -- run 300
        ------------------------------------------------------------------------
        valid <= '0';

        wait for 3 * TbPeriod;
        ------------------------------------------------------------------------
        -- run 300 = run 1800
        ------------------------------------------------------------------------

        -- Stop the clock and hence terminate the simulation
        TbSimEnded <= '1';
        wait;
    end process;

end tb;

-- Configuration block below is required by some simulators. Usually no need to edit.

configuration cfg_tb_Splitter of tb_Splitter is
    for tb
    end for;
end cfg_tb_Splitter;