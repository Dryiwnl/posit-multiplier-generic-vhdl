
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity tb_posit_rounding_generic is
end entity;

architecture test of tb_posit_rounding_generic is

    -- Posit(8,0)
    signal p0, r0 : std_logic_vector(7 downto 0)
        := (others => '0');
    signal g0, t0, s0 : std_logic := '0';

    -- Posit(8,1)
    signal p1, r1 : std_logic_vector(7 downto 0)
        := (others => '0');
    signal g1, t1, s1 : std_logic := '0';

    -- Posit(16,2)
    signal p2, r2 : std_logic_vector(15 downto 0)
        := (others => '0');
    signal g2, t2, s2 : std_logic := '0';

    -- Posit(32,2)
    signal p3, r3 : std_logic_vector(31 downto 0)
        := (others => '0');
    signal g3, t3, s3 : std_logic := '0';

begin

    d0 : entity work.posit_rounding_generic
        generic map (N => 8, ES => 0)
        port map (
            positPacked => p0,
            guardBit => g0,
            stickyBit => t0,
            sign => s0,
            positRounded => r0
        );

    d1 : entity work.posit_rounding_generic
        generic map (N => 8, ES => 1)
        port map (
            positPacked => p1,
            guardBit => g1,
            stickyBit => t1,
            sign => s1,
            positRounded => r1
        );

    d2 : entity work.posit_rounding_generic
        generic map (N => 16, ES => 2)
        port map (
            positPacked => p2,
            guardBit => g2,
            stickyBit => t2,
            sign => s2,
            positRounded => r2
        );

    d3 : entity work.posit_rounding_generic
        generic map (N => 32, ES => 2)
        port map (
            positPacked => p3,
            guardBit => g3,
            stickyBit => t3,
            sign => s3,
            positRounded => r3
        );

    stimulus : process
    begin

        -- TEST 1: G=0, preserve magnitude.
        p1 <= x"45";
        wait for 1 ns;

        assert r1 = x"45"
            report "FAIL: G=0"
            severity failure;

        report "PASS: G=0";


        -- TEST 2: G=1, S=0, L=0.
        -- Exact tie, already even.
        p1 <= x"40";
        g1 <= '1';
        wait for 1 ns;

        assert r1 = x"40"
            report "FAIL: tie to even (L=0)"
            severity failure;

        report "PASS: tie L=0";


        -- TEST 3: G=1, S=0, L=1.
        -- Exact tie, increment to even.
        p1 <= x"41";
        wait for 1 ns;

        assert r1 = x"42"
            report "FAIL: tie to even (L=1)"
            severity failure;

        report "PASS: tie L=1";


        -- TEST 4: G=1, S=1.
        p1 <= x"40";
        t1 <= '1';
        wait for 1 ns;

        assert r1 = x"41"
            report "FAIL: above midpoint"
            severity failure;

        report "PASS: above midpoint";


        -- TEST 5: G=0, S=1.
        g1 <= '0';
        wait for 1 ns;

        assert r1 = x"40"
            report "FAIL: below midpoint"
            severity failure;

        report "PASS: below midpoint";


        -- TEST 6: Negative operand, no rounding.
        s1 <= '1';
        t1 <= '0';
        wait for 1 ns;

        assert r1 = x"C0"
            report "FAIL: negative without rounding"
            severity failure;

        report "PASS: negative without rounding";


        -- TEST 7: Negative operand with rounding.
        p1 <= x"41";
        g1 <= '1';
        wait for 1 ns;

        -- 0x41 rounds to 0x42, then negates to 0xBE.
        assert r1 = x"BE"
            report "FAIL: negative with rounding"
            severity failure;

        report "PASS: negative with rounding";


        -- TEST 8: Positive maximum boundary.
        s1 <= '0';
        p1 <= x"7E";
        g1 <= '1';
        t1 <= '1';
        wait for 1 ns;

        assert r1 = x"7F"
            report "FAIL: rounding to maxpos"
            severity failure;

        report "PASS: maxpos boundary";


        -- TEST 9: ES=0, tie to even.
        p0 <= x"21";
        g0 <= '1';
        t0 <= '0';
        wait for 1 ns;

        assert r0 = x"22"
            report "FAIL: Posit(8,0)"
            severity failure;

        report "PASS: Posit(8,0)";


        -- TEST 10: ES=0, negative.
        s0 <= '1';
        wait for 1 ns;

        assert r0 = x"DE"
            report "FAIL: Posit(8,0) negative"
            severity failure;

        report "PASS: Posit(8,0) negative";


        -- TEST 11: Posit(16,2), tie to even.
        p2 <= x"4001";
        g2 <= '1';
        wait for 1 ns;

        assert r2 = x"4002"
            report "FAIL: Posit(16,2) rounding"
            severity failure;

        report "PASS: Posit(16,2)";


        -- TEST 12: Posit(16,2), negative.
        s2 <= '1';
        wait for 1 ns;

        assert r2 = x"BFFE"
            report "FAIL: Posit(16,2) negative"
            severity failure;

        report "PASS: Posit(16,2) negative";


        -- TEST 13: Posit(32,2), tie to even.
        p3 <= x"40000001";
        g3 <= '1';
        wait for 1 ns;

        assert r3 = x"40000002"
            report "FAIL: Posit(32,2) rounding"
            severity failure;

        report "PASS: Posit(32,2)";


        -- TEST 14: Posit(32,2), negative.
        s3 <= '1';
        wait for 1 ns;

        assert r3 = x"BFFFFFFE"
            report "FAIL: Posit(32,2) negative"
            severity failure;

        report "PASS: Posit(32,2) negative";


        report "ALL ROUNDING TESTS PASSED"
            severity note;

        finish;
    end process;

end architecture test;
