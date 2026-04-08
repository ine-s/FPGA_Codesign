library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity calculateur_cable is
    port (
        clk      : in  std_logic;
        reset_n  : in  std_logic;
        data_a   : in  std_logic_vector(7 downto 0);
        data_b   : in  std_logic_vector(7 downto 0);
        op_sel   : in  std_logic_vector(1 downto 0); -- 00:add, 01:sub, 10:ampl, 11:att
        result   : out std_logic_vector(8 downto 0); -- 9 bits pour éviter overflow
        valid    : out std_logic
    );
end calculateur_cable;

architecture rtl of calculateur_cable is
    signal res : unsigned(8 downto 0);
begin
    process(clk, reset_n)
    begin
        if reset_n = '0' then
            result <= (others => '0');
            valid  <= '0';
        elsif rising_edge(clk) then
            case op_sel is
                when "00" => -- addition
                    res <= unsigned(data_a) + unsigned(data_b);
                when "01" => -- soustraction
                    res <= unsigned(data_a) - unsigned(data_b);
                when "10" => -- amplification (gain 2)
                    res <= unsigned(data_a) * 2;
                when others => -- atténuation (gain 0.5)
                    res <= unsigned(data_a) / 2;
            end case;
            result <= std_logic_vector(res);
            valid  <= '1';
        end if;
    end process;
end rtl;