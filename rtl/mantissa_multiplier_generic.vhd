
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mantissa_multiplier_generic is
    generic (
        N  : positive := 8;
        ES : natural  := 1
    );
    port (
        fractionA : in std_logic_vector(N-ES-4 downto 0);
        fractionB : in std_logic_vector(N-ES-4 downto 0);

        mantissaResult : out std_logic_vector(
            2*(N-ES-2)-1 downto 0
        )
    );
end entity mantissa_multiplier_generic;

architecture rtl of mantissa_multiplier_generic is
begin

    assert N >= ES + 4
        report "Invalid Posit configuration"
        severity failure;

    process(all)
        variable mantissaA : unsigned(N-ES-3 downto 0);
        variable mantissaB : unsigned(N-ES-3 downto 0);
    begin

        mantissaA := unsigned('1' & fractionA);
        mantissaB := unsigned('1' & fractionB);

        mantissaResult <= std_logic_vector(
            mantissaA * mantissaB
        );

    end process;

end architecture rtl;
