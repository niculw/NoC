-------------------------------------------------------------------------------
-- Title       : Arbiter
-- Project     : NoC in FPGA
-------------------------------------------------------------------------------
-- File        : Arbiter.vhd
-- Author      : Nicolai Weis Hansen <s154662@student.dtu.dk>
-- Company     : DTU
-- Created     : Tue Mar 27 02:14:34 2018
-- Last update : Thu Jun 21 03:43:37 2018
-- Platform    : Nexys 4
-- Standard    : <VHDL-2008>
-------------------------------------------------------------------------------
-- Copyright (c) 2018 DTU
-------------------------------------------------------------------------------
-- Description: Controls fairness on output of router.
-------------------------------------------------------------------------------
-- Revisions:  Revisions and documentation are controlled by
-- the revision control system (RCS).  The RCS should be consulted
-- on revision history.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Arbiter is
	port(
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
		
		data_out : out unsigned(31 downto 0));
end Arbiter;

architecture behaviour of Arbiter is
	
	type state_type is (idle,fifo0,fifo1,fifo2,fifo3);
	signal package_counter, package_counter_next : unsigned(1 downto 0);
	signal state, state_next                     : state_type;
	
	
	
	
	
begin
	
	--------------------------------------------------------------------------------
	-- FSM
	--------------------------------------------------------------------------------
	FSM : process(all) is
	begin
		rd_en0               <= '0';
		rd_en1               <= '0';
		rd_en2               <= '0';
		rd_en3               <= '0';
		valid                <= '0';
		data_out             <= (others => '0');
		state_next           <= state;
		package_counter_next <= package_counter;
		case (state) is
				------------------------------------------------------------------------
				-- Idle
				------------------------------------------------------------------------
			when idle => 
				if (empty0 = '0') then 
						state_next           <= fifo0; 
						data_out             <= data0;
						rd_en0               <= '1';
						valid                <= '1'; 
						package_counter_next <= package_counter + 1;
					elsif (empty1 = '0') then
						state_next           <= fifo1;
						data_out             <= data1;
						rd_en1               <= '1';
						valid                <= '1'; 
						package_counter_next <= package_counter + 1;
					elsif (empty2 = '0') then
						state_next           <= fifo2;
						data_out             <= data2;
						rd_en2               <= '1';
						valid                <= '1'; 
						package_counter_next <= package_counter + 1;
					elsif (empty3 = '0') then
						state_next           <= fifo3;
						data_out             <= data3;
						rd_en3               <= '1';
						valid                <= '1'; 
						package_counter_next <= package_counter + 1;
					else
						state_next <= idle;
					end if; 
				
				------------------------------------------------------------------------
				-- fifo0
				------------------------------------------------------------------------
			when fifo0 => 
				data_out <= data0;
				if (empty0 = '1') then 	-- if empty becomes high as another becomes low
					rd_en0               <= '0';
					valid                <= '0';
					package_counter_next <= (others => '0');
					if (empty1 = '0') then 
						state_next           <= fifo1;
						valid                <= '1';
						data_out             <= data1;
						rd_en1               <= '1';
						package_counter_next <= package_counter + 1;
					elsif (empty2 = '0') then
						state_next           <= fifo2;
						valid                <= '1';
						data_out             <= data2;
						rd_en2               <= '1';
						package_counter_next <= package_counter + 1;
					elsif (empty3 = '0') then
						state_next           <= fifo3;
						valid                <= '1';
						data_out             <= data3;
						rd_en3               <= '1';
						package_counter_next <= package_counter + 1;
					elsif (empty0 = '0') then
						state_next           <= fifo0;
						valid                <= '1';
						data_out             <= data0;
						rd_en0               <= '1';
						package_counter_next <= package_counter + 1;
					else
						state_next <= idle;
					end if;
				end if;
				if (package_counter <= 2 and empty0 <= '0') then -- if ready and counter below 3
					rd_en0 <= '1'; -- enable read
					valid  <= '1';
					
					if (package_counter = 2) then
						package_counter_next <= (others => '0');
						if (empty1 = '0') then 
							state_next <= fifo1; 
						elsif (empty2 = '0') then
							state_next <= fifo2;
						elsif (empty3 = '0') then
							state_next <= fifo3;
						elsif (empty0 = '0') then
							state_next <= fifo0;
						else
							state_next <= idle;
						end if;
					else
						package_counter_next <= package_counter + 1;
						state_next           <= fifo0;
					end if;
				end if;
				
				------------------------------------------------------------------------
				-- fifo1
				------------------------------------------------------------------------
			when fifo1 => 
				data_out <= data1;
				if (empty1 = '1') then
					rd_en1               <= '0';
					valid                <= '0';
					package_counter_next <= (others => '0');
					if (empty2 = '0') then 
						state_next           <= fifo2; 
						data_out             <= data2;
						rd_en2               <= '1';
						valid                <= '1';
						package_counter_next <= package_counter + 1;
					elsif (empty3 = '0') then
						state_next           <= fifo3;
						data_out             <= data3;
						rd_en3               <= '1';
						valid                <= '1'; 
						package_counter_next <= package_counter + 1;
					elsif (empty0 = '0') then
						state_next           <= fifo0;
						data_out             <= data0;
						rd_en0               <= '1';
						valid                <= '1'; 
						package_counter_next <= package_counter + 1;
					elsif (empty1 = '0') then
						state_next           <= fifo1;
						data_out             <= data1;
						rd_en1               <= '1';
						valid                <= '1';
						package_counter_next <= package_counter + 1;
					else
						state_next <= idle;
					end if;
				end if;
				if (package_counter <= 2 and empty1 <= '0') then -- if ready and counter below 3
					rd_en1 <= '1'; -- enable read
					valid  <= '1';
					if (package_counter = 2) then
						package_counter_next <= (others => '0');
						if (empty2 = '0') then 
							state_next <= fifo2; 
						elsif (empty3 = '0') then
							state_next <= fifo3;
						elsif (empty0 = '0') then
							state_next <= fifo0;
						elsif (empty1 = '0') then
							state_next <= fifo1;
						else
							state_next <= idle;
						end if;
					else
						package_counter_next <= package_counter + 1;
						state_next           <= fifo1;
					end if;
				end if;
				
				------------------------------------------------------------------------
				-- fifo2
				------------------------------------------------------------------------
			when fifo2 => 
				data_out <= data2;
				if (empty2 = '1') then
					rd_en2               <= '0';
					valid                <= '0';
					package_counter_next <= (others => '0');
					if (empty3 = '0') then 
						state_next           <= fifo3;
						data_out             <= data3;
						rd_en3               <= '1';
						valid                <= '1'; 
						package_counter_next <= package_counter + 1;
					elsif (empty0 = '0') then
						state_next           <= fifo0; 
						data_out             <= data0;
						rd_en0               <= '1';
						valid                <= '1';
						package_counter_next <= package_counter + 1;
					elsif (empty1 = '0') then
						state_next           <= fifo1; 
						data_out             <= data1;
						rd_en1               <= '1';
						valid                <= '1';
						package_counter_next <= package_counter + 1;
					elsif (empty2 = '0') then
						state_next           <= fifo2;
						data_out             <= data2;
						rd_en2               <= '1';
						valid                <= '1';
						package_counter_next <= package_counter + 1;
					else
						state_next <= idle;
					end if; 
				end if;
				
				
				if (package_counter <= 2 and empty2 <= '0') then -- if ready and counter below 3
					rd_en2 <= '1'; -- enable read
					valid  <= '1';
					
					if (package_counter = 2) then
						package_counter_next <= (others => '0');
						if (empty3 = '0') then 
							state_next <= fifo3; 
						elsif (empty0 = '0') then
							state_next <= fifo0;
						elsif (empty1 = '0') then
							state_next <= fifo1;
						elsif (empty2 = '0') then
							state_next <= fifo2;
						else
							state_next <= idle;
						end if; 
					else
						package_counter_next <= package_counter + 1;
						state_next           <= fifo2;
					end if;
				end if;
				
				------------------------------------------------------------------------
				-- fifo3
				------------------------------------------------------------------------
			when fifo3 => 
				data_out <= data3;
				if (empty3 = '1') then
					rd_en3               <= '0';
					valid                <= '0';
					package_counter_next <= (others => '0');
					if (empty0 = '0') then 
						state_next           <= fifo0; 
						data_out             <= data0;
						rd_en0               <= '1';
						valid                <= '1'; 
						package_counter_next <= package_counter + 1;
					elsif (empty1 = '0') then
						state_next           <= fifo1;
						data_out             <= data1;
						rd_en1               <= '1';
						valid                <= '1'; 
						package_counter_next <= package_counter + 1;
					elsif (empty2 = '0') then
						state_next           <= fifo2;
						data_out             <= data2;
						rd_en2               <= '1';
						valid                <= '1'; 
						package_counter_next <= package_counter + 1;
					elsif (empty3 = '0') then
						state_next           <= fifo3;
						data_out             <= data3;
						rd_en3               <= '1';
						valid                <= '1'; 
						package_counter_next <= package_counter + 1;
					else
						state_next <= idle;
					end if; 
				end if;
				if (package_counter <= 2 and empty3 <= '0') then -- if ready and counter below 3
					rd_en3 <= '1'; -- enable read
					valid  <= '1';
					if (package_counter = 2) then
						package_counter_next <= (others => '0');
						if (empty0 = '0') then 
							state_next <= fifo0; 
						elsif (empty1 = '0') then
							state_next <= fifo1;
						elsif (empty2 = '0') then
							state_next <= fifo2;
						elsif (empty3 = '0') then
							state_next <= fifo3;
						else
							state_next <= idle;
						end if; 
					else
						package_counter_next <= package_counter + 1;
						state_next           <= fifo3;
					end if;
				end if; 
		end case;
	end process; -- FSM
	
	--------------------------------------------------------------------------------
	-- Clocking
	--------------------------------------------------------------------------------
	Clocking : process (all) is
	begin
		if (reset = '1') then
			state           <= idle;
			package_counter <= (others => '0');
		elsif rising_edge(clock) then
			state           <= state_next;
			package_counter <= package_counter_next;
		end if;
	end process; -- Clocking
	
	
end behaviour;






	