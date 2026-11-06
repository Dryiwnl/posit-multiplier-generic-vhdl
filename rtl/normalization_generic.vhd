
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity normalization_generic is
    generic (
        N  : positive := 8;
        ES : natural  := 1
    );
    port (
        mantissaResult : in std_logic_vector(
            2*(N-ES-2)-1 downto 0
        );

        kResult : in signed(N-1 downto 0);

        exponentResult : in std_logic_vector(ES downto 1);

        mantissaNormalized : out std_logic_vector(
            2*(N-ES-2)-1 downto 0
        );

        normalizationCarry : out std_logic;

        kResultNormalized : out signed(N-1 downto 0);

        exponentResultNormalized : out std_logic_vector(
            ES downto 1
        )
    );
end entity normalization_generic;

architecture rtl of normalization_generic is

    constant M_WIDTH : positive := 2*(N-ES-2);

begin

    assert N >= ES + 4
        report "Invalid Posit configuration"
        severity failure;

    -- Normalize the mantissa.
    process(all)
        variable mantissa_aux :
            std_logic_vector(M_WIDTH-1 downto 0);
    begin
        if mantissaResult(M_WIDTH-1) = '1' then

            mantissa_aux := std_logic_vector(
                shift_right(unsigned(mantissaResult), 1)
            );

            -- Preserve the discarded bit for Sticky.
            mantissa_aux(M_WIDTH-1) := mantissaResult(0);

            mantissaNormalized <= mantissa_aux;
            normalizationCarry <= '1';

        else
            mantissaNormalized <= mantissaResult;
            normalizationCarry <= '0';
        end if;
    end process;

    -- ES = 0: normalization increments k directly.
    gen_es_zero : if ES = 0 generate
    begin

        exponentResultNormalized <= (others => '0');

        kResultNormalized <= kResult + 1
            when mantissaResult(M_WIDTH-1) = '1'
            else kResult;

    end generate;

    -- ES > 0: increment exponent and propagate overflow to k.
    gen_es_positive : if ES > 0 generate

        signal exponent_plus_one :
            unsigned(ES downto 0);

    begin

        exponent_plus_one <=
            ('0' & unsigned(exponentResult)) + 1;

        process(all)
        begin
            kResultNormalized <= kResult;
            exponentResultNormalized <= exponentResult;

            if mantissaResult(M_WIDTH-1) = '1' then

                exponentResultNormalized <=
                    std_logic_vector(
                        exponent_plus_one(ES-1 downto 0)
                    );

                if exponent_plus_one(ES) = '1' then
                    kResultNormalized <= kResult + 1;
                end if;

            end if;
        end process;

    end generate;

end architecture rtl;
