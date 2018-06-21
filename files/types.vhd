library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package types is
	type data is array (integer range 0 to 3, integer range 0 to 3) of unsigned(31 downto 0);
	type valid is array (integer range 0 to 3, integer range 0 to 3) of std_logic;
end package types;

package body types is

end package body types;
