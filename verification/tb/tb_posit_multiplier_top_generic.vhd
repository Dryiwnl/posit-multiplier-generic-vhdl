
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity tb_posit_multiplier_top_generic is
end entity;

architecture test of tb_posit_multiplier_top_generic is

    -- Posit(8,0)
    signal a0, b0, r0 : std_logic_vector(7 downto 0)
        := (others => '0');

    -- Posit(8,1)
    signal a1, b1, r1 : std_logic_vector(7 downto 0)
        := (others => '0');

    -- Posit(16,2)
    signal a2, b2, r2 : std_logic_vector(15 downto 0)
        := (others => '0');

    -- Posit(32,2)
    signal a3, b3, r3 : std_logic_vector(31 downto 0)
        := (others => '0');

begin

    dut0 : entity work.posit_multiplier_top_generic
        generic map (N => 8, ES => 0)
        port map (
            positA => a0,
            positB => b0,
            positResult => r0
        );

    dut1 : entity work.posit_multiplier_top_generic
        generic map (N => 8, ES => 1)
        port map (
            positA => a1,
            positB => b1,
            positResult => r1
        );

    dut2 : entity work.posit_multiplier_top_generic
        generic map (N => 16, ES => 2)
        port map (
            positA => a2,
            positB => b2,
            positResult => r2
        );

    dut3 : entity work.posit_multiplier_top_generic
        generic map (N => 32, ES => 2)
        port map (
            positA => a3,
            positB => b3,
            positResult => r3
        );

    stimulus : process
    begin

        ------------------------------------------------
        -- TEST 1: 1 * 1 = 1
        ------------------------------------------------

        a0 <= x"40"; b0 <= x"40";
        a1 <= x"40"; b1 <= x"40";
        a2 <= x"4000"; b2 <= x"4000";
        a3 <= x"40000000"; b3 <= x"40000000";

        wait for 1 ns;

        assert r0 = x"40" and r1 = x"40"
            and r2 = x"4000" and r3 = x"40000000"
            report "FAIL: 1 * 1"
            severity failure;

        report "PASS: 1 * 1";


        ------------------------------------------------
        -- TEST 2: 2 * 1 = 2
        ------------------------------------------------

        a0 <= x"60"; b0 <= x"40";
        a1 <= x"50"; b1 <= x"40";
        a2 <= x"4800"; b2 <= x"4000";
        a3 <= x"48000000"; b3 <= x"40000000";

        wait for 1 ns;

        assert r0 = x"60" and r1 = x"50"
            and r2 = x"4800" and r3 = x"48000000"
            report "FAIL: 2 * 1"
            severity failure;

        report "PASS: 2 * 1";


        ------------------------------------------------
        -- TEST 3: 1.5 * 1 = 1.5
        ------------------------------------------------

        a0 <= x"50"; b0 <= x"40";
        a1 <= x"48"; b1 <= x"40";
        a2 <= x"4400"; b2 <= x"4000";
        a3 <= x"44000000"; b3 <= x"40000000";

        wait for 1 ns;

        assert r0 = x"50" and r1 = x"48"
            and r2 = x"4400" and r3 = x"44000000"
            report "FAIL: 1.5 * 1"
            severity failure;

        report "PASS: 1.5 * 1";


        ------------------------------------------------
        -- TEST 4: 1.5 * 1.5 = 2.25
        ------------------------------------------------

        b0 <= x"50";
        b1 <= x"48";
        b2 <= x"4400";
        b3 <= x"44000000";

        wait for 1 ns;

        assert r0 = x"62" and r1 = x"52"
            and r2 = x"4900" and r3 = x"49000000"
            report "FAIL: 1.5 * 1.5"
            severity failure;

        report "PASS: 1.5 * 1.5";


        ------------------------------------------------
        -- TEST 5: -1 * 1 = -1
        ------------------------------------------------

        a0 <= x"C0"; b0 <= x"40";
        a1 <= x"C0"; b1 <= x"40";
        a2 <= x"C000"; b2 <= x"4000";
        a3 <= x"C0000000"; b3 <= x"40000000";

        wait for 1 ns;

        assert r0 = x"C0" and r1 = x"C0"
            and r2 = x"C000" and r3 = x"C0000000"
            report "FAIL: -1 * 1"
            severity failure;

        report "PASS: -1 * 1";


        ------------------------------------------------
        -- TEST 6: -1 * -1 = 1
        ------------------------------------------------

        b0 <= x"C0";
        b1 <= x"C0";
        b2 <= x"C000";
        b3 <= x"C0000000";

        wait for 1 ns;

        assert r0 = x"40" and r1 = x"40"
            and r2 = x"4000" and r3 = x"40000000"
            report "FAIL: -1 * -1"
            severity failure;

        report "PASS: -1 * -1";


        ------------------------------------------------
        -- TEST 7: 0 * 1 = 0
        ------------------------------------------------

        a0 <= x"00"; b0 <= x"40";
        a1 <= x"00"; b1 <= x"40";
        a2 <= x"0000"; b2 <= x"4000";
        a3 <= x"00000000"; b3 <= x"40000000";

        wait for 1 ns;

        assert r0 = x"00" and r1 = x"00"
            and r2 = x"0000" and r3 = x"00000000"
            report "FAIL: zero propagation"
            severity failure;

        report "PASS: zero propagation";


        ------------------------------------------------
        -- TEST 8: NaR * 1 = NaR
        ------------------------------------------------

        a0 <= x"80";
        a1 <= x"80";
        a2 <= x"8000";
        a3 <= x"80000000";

        wait for 1 ns;

        assert r0 = x"80" and r1 = x"80"
            and r2 = x"8000" and r3 = x"80000000"
            report "FAIL: NaR propagation"
            severity failure;

        report "PASS: NaR propagation";


        ------------------------------------------------
        -- TEST 9: NaR * 0 = NaR
        ------------------------------------------------

        b0 <= x"00";
        b1 <= x"00";
        b2 <= x"0000";
        b3 <= x"00000000";

        wait for 1 ns;

        assert r0 = x"80" and r1 = x"80"
            and r2 = x"8000" and r3 = x"80000000"
            report "FAIL: NaR priority"
            severity failure;

        report "PASS: NaR priority";


        ------------------------------------------------
        -- TEST 10: minpos * 1 = minpos
        ------------------------------------------------

        a0 <= x"01"; b0 <= x"40";
        a1 <= x"01"; b1 <= x"40";
        a2 <= x"0001"; b2 <= x"4000";
        a3 <= x"00000001"; b3 <= x"40000000";

        wait for 1 ns;

        assert r0 = x"01" and r1 = x"01"
            and r2 = x"0001" and r3 = x"00000001"
            report "FAIL: minpos * 1"
            severity failure;

        report "PASS: minpos * 1";


        ------------------------------------------------
        -- TEST 11: maxpos * 1 = maxpos
        ------------------------------------------------

        a0 <= x"7F";
        a1 <= x"7F";
        a2 <= x"7FFF";
        a3 <= x"7FFFFFFF";

        wait for 1 ns;

        assert r0 = x"7F" and r1 = x"7F"
            and r2 = x"7FFF" and r3 = x"7FFFFFFF"
            report "FAIL: maxpos * 1"
            severity failure;

        report "PASS: maxpos * 1";


        report "ALL TOP LEVEL DIRECTED TESTS PASSED"
            severity note;

        finish;

    end process;

end architecture test;
