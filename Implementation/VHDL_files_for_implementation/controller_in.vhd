-------------------------------------------------------------------------------
-- Title       : Traffic controller
-- Project     : NoC in FPGA
-------------------------------------------------------------------------------
-- File        : controller_in.vhd
-- Author      : Nicolai Weis Hansen <s154662@student.dtu.dk>
-- Company     : DTU
-- Created     : Mon Jun 25 22:43:05 2018
-- Last update : Fri Jun 29 02:08:43 2018
-- Platform    : Nexys 4DDR
-- Standard    : <VHDL-2008>
-------------------------------------------------------------------------------
-- Copyright (c) 2018 DTU
-------------------------------------------------------------------------------
-- Description: Sends data to the network for DEMO
-------------------------------------------------------------------------------
-- Revisions:  Revisions and documentation are controlled by
-- the revision control system (RCS).  The RCS should be consulted
-- on revision history.
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.types.all;

entity controller is
	port (
		clock : in std_logic;
		reset : in std_logic;
		
		-- tx and rx are form the fsm poiont of view rx <= tx
		data_stream_tx     : out std_logic_vector(7 downto 0);
		data_stream_tx_stb : out std_logic;
		data_stream_tx_ack : in  std_logic;
		data_stream_rx     : in  std_logic_vector(7 downto 0);
		data_stream_rx_stb : in  std_logic;
		
		-- data to the network
		-- input 0,0 to 3,3
		valid_in_local : in valid;
		data_in_local  : in data;
		-- output to 0,0
		fifo_empty   : in  std_logic;
		rd_en        : out std_logic;
		wr_en        : out std_logic;
		valid_out    : out std_logic;
		data_to_fifo : out unsigned(31 downto 0);
		
		led  : out std_logic_vector(4 downto 0);
		led2 : out std_logic_vector(5 downto 0)
	);
	
end entity controller;

architecture rtl of controller is
	type state_type is (start, clear, wait_and_check_command, reply_test,
			data0, data1, data2, data3, store_data,
			upload0, upload1, upload2, upload3, uploadwait,
			upload4, upload5, upload6, upload7, upload8, upload9,
			upload10,upload11,
			send_data_to_network, send);
	type state_type2 is (storeout, storeout1, storeout2, data_out_stored);
	signal data_buffer, data_buffer_next          : unsigned(31 downto 0);
	signal data_out_buffer, data_out_buffer_next  : unsigned(95 downto 0);
	signal state2, state_next2                    : state_type2;
	signal state, state_next                      : state_type;
	signal flit_count, flit_count_next            : unsigned(1 downto 0);
	signal xvar, yvar, xvar_next, yvar_next       : unsigned(1 downto 0);
	signal have_data, stored_data, done_uploading : std_logic;
	
begin
	data_to_fifo <= data_buffer;
	
	process(all)
	begin
		flit_count_next    <= flit_count;
		data_stream_tx     <= (others => '0');
		data_stream_tx_stb <= '0';
		state_next         <= state;
		data_buffer_next   <= data_buffer;
		wr_en              <= '0';
		rd_en              <= '0';
		valid_out          <= '0';
		done_uploading     <= '0';
		led                <= "00000";
		led2               <= "000000";
		
		case state is
			when start => 
				data_buffer_next <= (others => '0');
				state_next       <= clear;
				
			when clear => 
				if (fifo_empty = '1') then
					state_next <= wait_and_check_command;
				else
					rd_en      <= '1';
					state_next <= clear;
				end if;
				
			when wait_and_check_command => 
				led <= "00001";
				if data_stream_rx_stb = '0' then
					-- nothing to read
					state_next <= wait_and_check_command;
				else
					--read the content and act
					if data_stream_rx = x"74" then --ascii = t
						state_next <= reply_test;
					elsif stored_data = '1' and data_stream_rx = x"72" then -- data_out_buffer if full
						state_next <= uploadwait;
					elsif data_stream_rx = x"77" then --ascii = w
						state_next <= data0;
					elsif data_stream_rx = x"63" then --ascii = c
						data_buffer_next <= (others => '0');
						state_next       <= clear;
					else
						state_next <= wait_and_check_command;
					end if;
				end if;
				
			when reply_test => 
				data_stream_tx     <= x"79"; --ascii = y
				data_stream_tx_stb <= '1';
				if data_stream_tx_ack = '0' then
					state_next <= reply_test;
				else
					state_next <= wait_and_check_command;
				end if;
				
			when data0 => 
				led <= "00010";
				if data_stream_rx_stb = '0' then
					--wait
					state_next <= data0;
				else
					--read
					data_buffer_next(7 downto 0) <= unsigned(data_stream_rx);
					state_next                   <= data1;
				end if;
				
			when data1 => 
				led <= "00011";
				if data_stream_rx_stb = '0' then
					--wait
					state_next <= data1;
				else
					--read
					data_buffer_next(15 downto 8) <= unsigned(data_stream_rx);
					state_next                    <= data2;
				end if;
				
			when data2 => 
				led <= "00100";
				if data_stream_rx_stb = '0' then
					--wait
					state_next <= data2;
				else
					--read
					data_buffer_next(23 downto 16) <= unsigned(data_stream_rx);
					state_next                     <= data3;
				end if;
				
			when data3 => 
				led <= "00101";
				if data_stream_rx_stb = '0' then
					--wait
					state_next <= data3;
				else
					--read
					data_buffer_next(31 downto 24) <= unsigned(data_stream_rx);
					state_next                     <= store_data;
					flit_count_next                <= flit_count + 1;
				end if;
				
			when store_data => -- stores flit recieved
				led   <= "00110";
				wr_en <= '1';
				if flit_count = 3 then -- next is at 2, so 3 flits are stored.
					state_next      <= send_data_to_network;
					flit_count_next <= (others => '0');
				else
					state_next <= data0;
				end if;
				
			when send_data_to_network => -- when all 3 are stored we send to network.
				state_next <= send;
				
			when send => -- send to network untill empty
				led <= "00111";
				if (fifo_empty = '1') then
					state_next <= wait_and_check_command;
				else
					rd_en      <= '1';
					valid_out  <= '1';
					state_next <= send;
				end if;
				
			when uploadwait => 
				led2       <= "000001";
				state_next <= upload0;
				
			when upload0 => 
				led2               <= "000010";
				data_stream_tx     <= std_logic_vector(data_out_buffer(7 downto 0));
				data_stream_tx_stb <= '1';
				if data_stream_tx_ack = '0' then
					state_next <= upload0;
				else
					state_next <= upload1;
				end if;
				
			when upload1 => 
				led2               <= "000011";
				data_stream_tx     <= std_logic_vector(data_out_buffer(15 downto 8));
				data_stream_tx_stb <= '1';
				if data_stream_tx_ack = '0' then
					state_next <= upload1;
				else
					state_next <= upload2;
				end if;
				
			when upload2 => 
				led2               <= "000100";
				data_stream_tx     <= std_logic_vector(data_out_buffer(23 downto 16));
				data_stream_tx_stb <= '1';
				if data_stream_tx_ack = '0' then
					state_next <= upload2;
				else
					state_next <= upload3;
				end if;
				
			when upload3 => 
				led2               <= "000101";
				data_stream_tx     <= std_logic_vector(data_out_buffer(31 downto 24));
				data_stream_tx_stb <= '1';
				if data_stream_tx_ack = '0' then
					state_next <= upload3;
				else
					state_next <= upload4;
				end if; 
				
			when upload4 => 
				led2               <= "000110";
				data_stream_tx     <= std_logic_vector(data_out_buffer(39 downto 32));
				data_stream_tx_stb <= '1';
				if data_stream_tx_ack = '0' then
					state_next <= upload4;
				else
					state_next <= upload5;
				end if; 
				
			when upload5 => 
				led2               <= "000111";
				data_stream_tx     <= std_logic_vector(data_out_buffer(47 downto 40));
				data_stream_tx_stb <= '1';
				if data_stream_tx_ack = '0' then
					state_next <= upload5;
				else
					state_next <= upload6;
				end if; 
				
			when upload6 => 
				led2               <= "001000";
				data_stream_tx     <= std_logic_vector(data_out_buffer(55 downto 48));
				data_stream_tx_stb <= '1';
				if data_stream_tx_ack = '0' then
					state_next <= upload6;
				else
					state_next <= upload7;
				end if; 
				
			when upload7 => 
				led2               <= "001001"; 
				data_stream_tx     <= std_logic_vector(data_out_buffer(63 downto 56));
				data_stream_tx_stb <= '1';
				if data_stream_tx_ack = '0' then
					state_next <= upload7;
				else
					state_next <= upload8;
				end if;
				
			when upload8 => 
				led2               <= "001010";
				data_stream_tx     <= std_logic_vector(data_out_buffer(71 downto 64));
				data_stream_tx_stb <= '1';
				if data_stream_tx_ack = '0' then
					state_next <= upload8;
				else
					state_next <= upload9;
				end if;
				
			when upload9 => 
				led2               <= "001011";
				data_stream_tx     <= std_logic_vector(data_out_buffer(79 downto 72));
				data_stream_tx_stb <= '1';
				if data_stream_tx_ack = '0' then
					state_next <= upload9;
				else
					state_next <= upload10;
				end if;
				
			when upload10 => 
				led2               <= "001100"; 
				data_stream_tx     <= std_logic_vector(data_out_buffer(87 downto 80));
				data_stream_tx_stb <= '1';
				if data_stream_tx_ack = '0' then
					state_next <= upload10;
				else
					state_next <= upload11;
				end if;
				
			when upload11 => 
				led2               <= "001101";
				data_stream_tx     <= std_logic_vector(data_out_buffer(95 downto 88));
				data_stream_tx_stb <= '1';
				if data_stream_tx_ack = '0' then
					state_next <= upload11;
				else
					done_uploading <= '1';
					state_next     <= wait_and_check_command;
				end if;
				
			when others => 
				state_next <= state;
		end case;
	end process;
	
	process(all) -- determine what router is valid
	begin
		have_data <= '0';
		xvar_next <= xvar;
		yvar_next <= yvar;
		validx : for i in 0 to 3 loop
			validy : for j in 0 to 3 loop
				if valid_in_local(i,j) = '1' then
					xvar_next <= to_unsigned(i,xvar_next'length);
					yvar_next <= to_unsigned(j,yvar_next'length);
					have_data <= '1';
				end if;
			end loop validy;
		end loop validx;
	end process;
	
	process(all)
	begin
		data_out_buffer_next <= data_out_buffer;
		stored_data          <= '0';
		case (state2) is
			when storeout => 
				if (have_data = '1') then
					data_out_buffer_next(3 downto 0)  <= xvar_next & yvar_next;
					data_out_buffer_next(31 downto 4) <= (others => '1');
					state_next2                       <= storeout1;
				else 
					state_next2 <= storeout;
				end if;
				
			when storeout1 => 
				data_out_buffer_next(63 downto 32) <= data_in_local(to_integer(xvar_next),to_integer(yvar_next));
				state_next2                        <= storeout2;
				
			when storeout2 => 
				data_out_buffer_next(95 downto 64) <= data_in_local(to_integer(xvar),to_integer(yvar));
				state_next2                        <= data_out_stored;
				
			when data_out_stored => 
				
				if done_uploading = '1' then
					state_next2 <= storeout;
				else
					stored_data <= '1';
					state_next2 <= data_out_stored;
				end if;
			when others => 
				state_next2 <= state2;
		end case;
		
		
		
		
	end process;
	
	process(all)
	begin
		if rising_edge(clock) then
			if reset = '1' then
				state           <= start;
				state2          <= storeout;
				data_buffer     <= (others => '0');
				data_out_buffer <= (others => '0');
				flit_count      <= (others => '0');
				xvar            <= (others => '0');
				yvar            <= (others => '0');
			else
				state           <= state_next;
				state2          <= state_next2;
				data_buffer     <= data_buffer_next;
				data_out_buffer <= data_out_buffer_next;
				flit_count      <= flit_count_next;
				xvar            <= xvar_next;
				yvar            <= yvar_next;
			end if;
		end if;
	end process;
	
end architecture rtl;