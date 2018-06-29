-------------------------------------------------------------------------------
-- Project     : NoC in FPGA
-------------------------------------------------------------------------------
-- File        : fifo.vhd
-- Author      : Jacob Hebsgaard Jessen <s153427@student.dtu.dk>
-- Company     : DTU
-- Created     : Tue Mar 27 12:16:25 2018
-- Last update : Thu Jun 21 03:43:27 2018
-- Platform    : Nexys 4
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


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fifo is
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
end fifo;

architecture rtl of fifo is
  
  type t_FIFO_DATA is array (0 to 16-1) of std_logic_vector(31 downto 0);
  signal r_FIFO_DATA : t_FIFO_DATA := (others => (others => '0'));
  
  signal r_WR_INDEX : integer range 0 to 16-1 := 0;
  signal r_RD_INDEX : integer range 0 to 16-1 := 0;
  
  -- # Words in FIFO, has extra range to allow for assert conditions
  signal r_FIFO_COUNT : integer range -1 to 16+1 := 0;
  
  signal w_FULL  : std_logic;
  signal w_EMPTY : std_logic;
  
  attribute ram_style                : string;
  attribute ram_style of r_FIFO_DATA : signal is "distributed"; 
  -- Force LUTram
  
begin
  
  p_CONTROL : process (i_clk) is
  begin
    if rising_edge(i_clk) then
      if i_rst_sync = '1' then
        r_FIFO_COUNT <= 0;
        r_WR_INDEX   <= 0;
        r_RD_INDEX   <= 0;
      else
        
        -- Keeps track of the total number of words in the FIFO
        if (i_wr_en = '1' and i_rd_en = '0') then
          r_FIFO_COUNT <= r_FIFO_COUNT + 1;
        elsif (i_wr_en = '0' and i_rd_en = '1') then
          r_FIFO_COUNT <= r_FIFO_COUNT - 1;
        end if;
        
        -- Keeps track of the write index (and controls roll-over)
        if (i_wr_en = '1' and w_FULL = '0') then
          if r_WR_INDEX = 16-1 then
            r_WR_INDEX <= 0;
          else
            r_WR_INDEX <= r_WR_INDEX + 1;
          end if;
        end if;
        
        -- Keeps track of the read index (and controls roll-over)        
        if (i_rd_en = '1' and w_EMPTY = '0') then
          if r_RD_INDEX = 16-1 then
            r_RD_INDEX <= 0;
          else
            r_RD_INDEX <= r_RD_INDEX + 1;
          end if;
        end if;
        
        -- Registers the input data when there is a write
        if i_wr_en = '1' then
          r_FIFO_DATA(r_WR_INDEX) <= i_wr_data;
        end if;

      end if; -- sync reset
    end if; -- rising_edge(i_clk)
  end process p_CONTROL;
  
  o_rd_data <= r_FIFO_DATA(r_RD_INDEX);
  
  
  w_FULL  <= '1' when r_FIFO_COUNT = 16 else '0';
  w_EMPTY <= '1' when r_FIFO_COUNT = 0 else '0';
  
  o_af <= '1' when r_FIFO_COUNT > 13 else '0';
  o_ae <= '1' when r_FIFO_COUNT < 3 else '0';
  
  o_full  <= w_FULL;
  o_empty <= w_EMPTY;
  
  
  -- p_ASSERT : process (i_clk) is
  -- begin
  --   if rising_edge(i_clk) then
  --     if i_wr_en = '1' and w_FULL = '1' then
  --       report "ASSERT FAILURE - MODULE_REGISTER_FIFO : FIFO IS FULL AND BEING WRITTEN " severity failure;
  --     end if;
  --     
  --     if i_rd_en = '1' and w_EMPTY = '1' then
  --       report "ASSERT FAILURE - MODULE_REGISTER_FIFO : FIFO IS EMPTY AND BEING READ " severity failure;
  --     end if;
  --   end if;
  -- end process p_ASSERT;
  
  -- synthesis translate_on
end rtl;