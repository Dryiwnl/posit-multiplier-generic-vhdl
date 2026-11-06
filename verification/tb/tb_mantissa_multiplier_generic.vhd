
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity tb_mantissa_multiplier_generic is
end entity;

architecture test of tb_mantissa_multiplier_generic is

    -- Posit(8,0): fraction = 5 bits, product = 12 bits
    signal fa0, fb0 : std_logic_vector(4 downto 0)
        := (others => '0');
    signal mr0 : std_logic_vector(11 downto 0);

    -- Posit(8,1): fraction = 4 bits, product = 10 bits
    signal fa1, fb1 : std_logic_vector(3 downto 0)
        := (others => '0');
    signal mr1 : std_logic_vector(9 downto 0);

    -- Posit(16,2): fraction = 11 bits, product = 24 bits
    signal fa2, fb2 : std_logic_vector(10 downto 0)
        := (others => '0');
    signal mr2 : std_logic_vector(23 downto 0);

    -- Posit(32,2): fraction = 27 bits, product = 56 bits
    signal fa3, fb3 : std_logic_vector(26 downto 0)
        := (others => '0');
    signal mr3 : std_logic_vector(55 downto 0);

begin

    dut0 : entity work.mantissa_multiplier_generic
        generic map (N => 8, ES => 0)
        port map (
            fractionA => fa0,
            fractionB => fb0,
            mantissaResult => mr0
        );

    dut1 : entity work.mantissa_multiplier_generic
        generic map (N => 8, ES => 1)
        port map (
            fractionA => fa1,
            fractionB => fb1,
            mantissaResult => mr1
        );

    dut2 : entity work.mantissa_multiplier_generic
        generic map (N => 16, ES => 2)
        port map (
            fractionA => fa2,
            fractionB => fb2,
            mantissaResult => mr2
        );

    dut3 : entity work.mantissa_multiplier_generic
        generic map (N => 32, ES => 2)
        port map (
            fractionA => fa3,
            fractionB => fb3,
            mantissaResult => mr3
        );

    stimulus : process
        variable expected : integer;
        variable a, b : integer;
    begin

        -- TEST 1: 1.0 * 1.0
        wait for 1 ns;

        assert unsigned(mr0) = 1024
            and unsigned(mr1) = 256
            and unsigned(mr2) = 4194304
            and unsigned(mr3) =
                shift_left(to_unsigned(1, 56), 54)
            report "FAIL: 1.0 * 1.0"
            severity failure;

        report "PASS: 1.0 * 1.0";


        -- TEST 2: Posit(8,0), exhaustive fractions.
        -- Every possible pair of 5-bit fractions.
        for i in 0 to 31 loop
            for j in 0 to 31 loop

                fa0 <= std_logic_vector(to_unsigned(i, 5));
                fb0 <= std_logic_vector(to_unsigned(j, 5));

                wait for 1 ns;

                a := 32 + i;
                b := 32 + j;
                expected := a * b;

                assert to_integer(unsigned(mr0)) = expected
                    report "FAIL: Posit(8,0), i="
                        & integer'image(i)
                        & ", j=" & integer'image(j)
                    severity failure;

            end loop;
        end loop;

        report "PASS: Posit(8,0) exhaustive (1024 pairs)";


        -- TEST 3: Posit(8,1), exhaustive fractions.
        -- Every possible pair of 4-bit fractions.
        for i in 0 to 15 loop
            for j in 0 to 15 loop

                fa1 <= std_logic_vector(to_unsigned(i, 4));
                fb1 <= std_logic_vector(to_unsigned(j, 4));

                wait for 1 ns;

                a := 16 + i;
                b := 16 + j;
                expected := a * b;

                assert to_integer(unsigned(mr1)) = expected
                    report "FAIL: Posit(8,1), i="
                        & integer'image(i)
                        & ", j=" & integer'image(j)
                    severity failure;

            end loop;
        end loop;

        report "PASS: Posit(8,1) exhaustive (256 pairs)";


        -- TEST 4: Posit(16,2), both fractions = 0.5
        -- Integer mantissas: 3072 * 3072 = 9437184
        fa2 <= std_logic_vector(to_unsigned(1024, 11));
        fb2 <= std_logic_vector(to_unsigned(1024, 11));

        wait for 1 ns;

        assert to_integer(unsigned(mr2)) = 9437184
            report "FAIL: Posit(16,2), 1.5 * 1.5"
            severity failure;

        report "PASS: Posit(16,2), 1.5 * 1.5";


        -- TEST 5: Posit(16,2), maximum fractions.
        -- 4095 * 4095 = 16769025
        fa2 <= (others => '1');
        fb2 <= (others => '1');

        wait for 1 ns;

        assert to_integer(unsigned(mr2)) = 16769025
            report "FAIL: Posit(16,2), maximum fractions"
            severity failure;

        report "PASS: Posit(16,2), maximum fractions";


        -- TEST 6: Posit(32,2), 1.5 * 1.5 = 2.25
        fa3 <= std_logic_vector(
            shift_left(to_unsigned(1, 27), 26)
        );
        fb3 <= std_logic_vector(
            shift_left(to_unsigned(1, 27), 26)
        );

        wait for 1 ns;

        assert unsigned(mr3) =
            shift_left(to_unsigned(9, 56), 52)
            report "FAIL: Posit(32,2), 1.5 * 1.5"
            severity failure;

        report "PASS: Posit(32,2), 1.5 * 1.5";


        -- TEST 7: Posit(32,2), maximum fractions.
        -- (2^28 - 1)^2
        fa3 <= (others => '1');
        fb3 <= (others => '1');

        wait for 1 ns;

        assert unsigned(mr3) =
    unsigned'(x"FFFFFFE0000001")
            report "FAIL: Posit(32,2), maximum fractions"
            severity failure;

        report "PASS: Posit(32,2), maximum fractions";


        report "ALL MANTISSA MULTIPLIER TESTS PASSED"
            severity note;

        finish;

    end process;

end architecture test;
