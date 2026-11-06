
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sign_and_exponent_PU_generic is
    generic (
        N  : positive := 8;
        ES : natural  := 1
    );
    port (
        sign_A : in std_logic;
        sign_B : in std_logic;

        k_A : in signed(N-2 downto 0);
        k_B : in signed(N-2 downto 0);

        exponent_A : in std_logic_vector(ES downto 1);
        exponent_B : in std_logic_vector(ES downto 1);

        sign_result : out std_logic;
        k_result    : out signed(N-1 downto 0);
        exponent_result : out std_logic_vector(ES downto 1)
    );
end entity sign_and_exponent_PU_generic;

architecture rtl of sign_and_exponent_PU_generic is
begin

    assert N >= ES + 4
        report "Invalid Posit configuration"
        severity failure;

    -- Product sign.
    sign_result <= sign_A xor sign_B;

    -- ES = 0: there is no exponent field.
    gen_es_zero : if ES = 0 generate
    begin
        k_result <= resize(k_A, N) + resize(k_B, N);
        exponent_result <= (others => '0');
    end generate;

    -- ES > 0: add exponents and propagate carry.
    gen_es_positive : if ES > 0 generate

        signal exp_sum : unsigned(ES downto 0);

    begin

        exp_sum <=
            resize(unsigned(exponent_A), ES+1)
            + resize(unsigned(exponent_B), ES+1);

        exponent_result <=
            std_logic_vector(exp_sum(ES-1 downto 0));

        k_result <= resize(k_A, N) + resize(k_B, N)
            + to_signed(1, N)
            when exp_sum(ES) = '1'
            else resize(k_A, N) + resize(k_B, N);

    end generate;

end architecture rtl;
