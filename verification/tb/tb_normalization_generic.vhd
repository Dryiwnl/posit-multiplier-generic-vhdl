
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity tb_normalization_generic is
end entity;

architecture test of tb_normalization_generic is

    -- Posit(8,0)
    signal m0, mn0 : std_logic_vector(11 downto 0)
        := (others => '0');
    signal k0 : signed(7 downto 0) := (others => '0');
    signal kn0 : signed(7 downto 0);
    signal e0, en0 : std_logic_vector(0 downto 1);
    signal c0 : std_logic;

    -- Posit(8,1)
    signal m1, mn1 : std_logic_vector(9 downto 0)
        := (others => '0');
    signal k1 : signed(7 downto 0) := (others => '0');
    signal kn1 : signed(7 downto 0);
    signal e1 : std_logic_vector(1 downto 1) := "0";
    signal en1 : std_logic_vector(1 downto 1);
    signal c1 : std_logic;

    -- Posit(16,2)
    signal m2, mn2 : std_logic_vector(23 downto 0)
        := (others => '0');
    signal k2 : signed(15 downto 0) := (others => '0');
    signal kn2 : signed(15 downto 0);
    signal e2 : std_logic_vector(2 downto 1) := "00";
    signal en2 : std_logic_vector(2 downto 1);
    signal c2 : std_logic;

    -- Posit(32,2)
    signal m3, mn3 : std_logic_vector(55 downto 0)
        := (others => '0');
    signal k3 : signed(31 downto 0) := (others => '0');
    signal kn3 : signed(31 downto 0);
    signal e3 : std_logic_vector(2 downto 1) := "00";
    signal en3 : std_logic_vector(2 downto 1);
    signal c3 : std_logic;

begin

    d0 : entity work.normalization_generic
        generic map (N => 8, ES => 0)
        port map (
            mantissaResult => m0,
            kResult => k0,
            exponentResult => e0,
            mantissaNormalized => mn0,
            normalizationCarry => c0,
            kResultNormalized => kn0,
            exponentResultNormalized => en0
        );

    d1 : entity work.normalization_generic
        generic map (N => 8, ES => 1)
        port map (
            mantissaResult => m1,
            kResult => k1,
            exponentResult => e1,
            mantissaNormalized => mn1,
            normalizationCarry => c1,
            kResultNormalized => kn1,
            exponentResultNormalized => en1
        );

    d2 : entity work.normalization_generic
        generic map (N => 16, ES => 2)
        port map (
            mantissaResult => m2,
            kResult => k2,
            exponentResult => e2,
            mantissaNormalized => mn2,
            normalizationCarry => c2,
            kResultNormalized => kn2,
            exponentResultNormalized => en2
        );

    d3 : entity work.normalization_generic
        generic map (N => 32, ES => 2)
        port map (
            mantissaResult => m3,
            kResult => k3,
            exponentResult => e3,
            mantissaNormalized => mn3,
            normalizationCarry => c3,
            kResultNormalized => kn3,
            exponentResultNormalized => en3
        );

    stimulus : process
    begin

        -- TEST 1: No normalization needed.
        m0 <= x"400";
        m1 <= "01" & "00000000";
        m2 <= std_logic_vector(
            shift_left(to_unsigned(1, 24), 22)
        );
        m3 <= std_logic_vector(
            shift_left(to_unsigned(1, 56), 54)
        );

        k0 <= to_signed(-2, 8);
        k1 <= to_signed(3, 8);
        k2 <= to_signed(-4, 16);
        k3 <= to_signed(7, 32);

        e1 <= "1";
        e2 <= "11";
        e3 <= "10";

        wait for 1 ns;

        assert c0 = '0' and c1 = '0'
            and c2 = '0' and c3 = '0'
            report "FAIL: unnecessary normalization"
            severity failure;

        assert mn0 = m0 and mn1 = m1
            and mn2 = m2 and mn3 = m3
            report "FAIL: unchanged mantissa"
            severity failure;

        assert kn0 = k0 and kn1 = k1
            and kn2 = k2 and kn3 = k3
            report "FAIL: unchanged regime"
            severity failure;

        assert en1 = e1 and en2 = e2 and en3 = e3
            report "FAIL: unchanged exponent"
            severity failure;

        report "PASS: no normalization";


        -- TEST 2: ES=0, normalization increments k.
        m0 <= x"800";
        wait for 1 ns;

        assert c0 = '1'
            and mn0 = x"400"
            and to_integer(kn0) = -1
            and en0'length = 0
            report "FAIL: ES=0 normalization"
            severity failure;

        report "PASS: ES=0 normalization";


        -- TEST 3: ES=1, exponent without overflow.
        m1 <= "10" & "00000000";
        e1 <= "0";
        k1 <= to_signed(2, 8);
        wait for 1 ns;

        assert c1 = '1'
            and mn1 = "01" & "00000000"
            and en1 = "1"
            and to_integer(kn1) = 2
            report "FAIL: ES=1 no overflow"
            severity failure;

        report "PASS: ES=1 no overflow";


        -- TEST 4: ES=1, exponent overflow.
        e1 <= "1";
        wait for 1 ns;

        assert c1 = '1'
            and en1 = "0"
            and to_integer(kn1) = 3
            report "FAIL: ES=1 exponent overflow"
            severity failure;

        report "PASS: ES=1 exponent overflow";


        -- TEST 5: ES=2, exponent without overflow.
        m2 <= std_logic_vector(
            shift_left(to_unsigned(1, 24), 23)
        );
        e2 <= "10";
        k2 <= to_signed(-3, 16);
        wait for 1 ns;

        assert c2 = '1'
            and en2 = "11"
            and to_integer(kn2) = -3
            and unsigned(mn2) =
                shift_left(to_unsigned(1, 24), 22)
            report "FAIL: ES=2 no overflow"
            severity failure;

        report "PASS: ES=2 no overflow";


        -- TEST 6: ES=2, exponent overflow.
        e2 <= "11";
        wait for 1 ns;

        assert c2 = '1'
            and en2 = "00"
            and to_integer(kn2) = -2
            report "FAIL: ES=2 overflow"
            severity failure;

        report "PASS: ES=2 overflow";


        -- TEST 7: Posit(32,2), normalization.
        m3 <= std_logic_vector(
            shift_left(to_unsigned(1, 56), 55)
        );
        e3 <= "01";
        k3 <= to_signed(12, 32);
        wait for 1 ns;

        assert c3 = '1'
            and en3 = "10"
            and to_integer(kn3) = 12
            and unsigned(mn3) =
                shift_left(to_unsigned(1, 56), 54)
            report "FAIL: Posit(32,2) normalization"
            severity failure;

        report "PASS: Posit(32,2) normalization";


        -- TEST 8: Preserve discarded bit for Sticky.
        -- 0x201 >> 1 = 0x100.
        -- Bit 0 = 1, so bit 9 stores it.
        m1 <= "10" & "00000001";
        e1 <= "0";
        k1 <= to_signed(0, 8);
        wait for 1 ns;

        assert c1 = '1'
            and mn1 = "11" & "00000000"
            and en1 = "1"
            and to_integer(kn1) = 0
            report "FAIL: discarded bit preservation"
            severity failure;

        report "PASS: discarded bit preservation";


        report "ALL NORMALIZATION TESTS PASSED"
            severity note;

        finish;
    end process;

end architecture test;
