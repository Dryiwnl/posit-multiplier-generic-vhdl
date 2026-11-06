
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity decoder_posit_generic is
    generic (
        N  : positive := 8;
        ES : natural  := 1
    );
    port (
        posit_in : in  std_logic_vector(N-1 downto 0);
        sign     : out std_logic;
        k        : out signed(N-2 downto 0);
        exponent : out std_logic_vector(ES downto 1);
        fraction : out std_logic_vector(N-ES-4 downto 0);
        is_zero  : out std_logic;
        is_nar   : out std_logic
    );
end entity decoder_posit_generic;

architecture rtl of decoder_posit_generic is

    constant F : natural := N - ES - 3;

    constant ZERO_WORD : std_logic_vector(N-1 downto 0)
        := (others => '0');

    constant NAR_WORD : std_logic_vector(N-1 downto 0)
        := (N-1 => '1', others => '0');

begin

    assert N >= ES + 4
        report "Invalid configuration: N must be >= ES + 4"
        severity failure;

    sign    <= posit_in(N-1);
    is_zero <= '1' when posit_in = ZERO_WORD else '0';
    is_nar  <= '1' when posit_in = NAR_WORD else '0';

    process(all)
        variable magnitude  : std_logic_vector(N-1 downto 0);
        variable regime_bit : std_logic;
        variable run_length : integer;
        variable k_value    : integer;
        variable next_bit   : integer;

        variable exp_value  : std_logic_vector(ES downto 1);
        variable frac_value : std_logic_vector(F-1 downto 0);
    begin

        magnitude  := posit_in;
        run_length := 0;
        k_value    := 0;
        next_bit   := -1;

        exp_value  := (others => '0');
        frac_value := (others => '0');

        if posit_in /= ZERO_WORD and posit_in /= NAR_WORD then

            -- Recover the positive magnitude.
            if posit_in(N-1) = '1' then
                magnitude :=
                    std_logic_vector(-signed(posit_in));
            end if;

            -- Count consecutive regime bits.
            regime_bit := magnitude(N-2);

            for i in N-2 downto 0 loop
                if magnitude(i) /= regime_bit then
                    exit;
                end if;

                run_length := run_length + 1;
            end loop;

            -- Convert regime run length into k.
            if regime_bit = '1' then
                k_value := run_length - 1;
            else
                k_value := -run_length;
            end if;

            -- The first bit after the regime.
            next_bit := N - 3 - run_length;

            -- Extract the exponent.
            -- ES = 0 produces a null-length vector.
            for i in 0 to ES-1 loop
                if next_bit-i >= 0 then
                    exp_value(ES-i) := magnitude(next_bit-i);
                end if;
            end loop;

            -- Extract and left-align the fraction.
            for i in 0 to F-1 loop
                if next_bit-ES-i >= 0 then
                    frac_value(F-1-i) :=
                        magnitude(next_bit-ES-i);
                end if;
            end loop;

        end if;

        k        <= to_signed(k_value, k'length);
        exponent <= exp_value;
        fraction <= frac_value;

    end process;

end architecture rtl;
