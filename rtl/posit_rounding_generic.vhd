
---------------------------------------
-- Rounding - Generic Posit (N, ES)
-- Engineer: Matheus Vigano Schirrmann
-- Company: ProtoFPGA - UFSC
---------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity posit_rounding_generic is
    generic (
        N  : positive := 8;
        ES : natural  := 1
    );
    port (
        positPacked  : in  std_logic_vector(N-1 downto 0);
        guardBit     : in  std_logic;
        stickyBit    : in  std_logic;
        sign         : in  std_logic;
        positRounded : out std_logic_vector(N-1 downto 0)
    );
end entity posit_rounding_generic;

architecture rtl of posit_rounding_generic is
begin

    assert N >= ES + 4
        report "Invalid Posit configuration"
        severity failure;

    process(all)
        variable roundUp     : std_logic;
        variable rounded_aux : std_logic_vector(N-1 downto 0);
    begin

        -- Round to Nearest, Ties to Even.
        --
        -- L = positPacked(0)
        -- G = guardBit
        -- S = stickyBit
        --
        -- G=0: preserve magnitude
        -- G=1, S=1: round up
        -- G=1, S=0: tie; round to even

        roundUp := guardBit and
                   (stickyBit or positPacked(0));

        -- Round the positive magnitude.
        if roundUp = '1' then
            rounded_aux := std_logic_vector(
                unsigned(positPacked) + 1
            );
        else
            rounded_aux := positPacked;
        end if;

        -- Apply the sign after rounding.
        if sign = '0' then
            positRounded <= rounded_aux;
        else
            positRounded <= std_logic_vector(
                unsigned(not rounded_aux) + 1
            );
        end if;

    end process;

end architecture rtl;
