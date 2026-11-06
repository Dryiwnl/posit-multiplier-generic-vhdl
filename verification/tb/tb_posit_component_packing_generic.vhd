
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity tb_posit_component_packing_generic is
end entity;

architecture test of tb_posit_component_packing_generic is

    -- Posit(8,0)
    signal k0 : signed(7 downto 0) := (others => '0');
    signal e0 : std_logic_vector(0 downto 1);
    signal m0 : std_logic_vector(11 downto 0) := x"400";
    signal p0 : std_logic_vector(7 downto 0);
    signal g0, s0 : std_logic;

    -- Posit(8,1)
    signal k1 : signed(7 downto 0) := (others => '0');
    signal e1 : std_logic_vector(1 downto 1) := "0";
    signal m1 : std_logic_vector(9 downto 0) := "0100000000";
    signal p1 : std_logic_vector(7 downto 0);
    signal g1, s1 : std_logic;

    -- Posit(16,2)
    signal k2 : signed(15 downto 0) := (others => '0');
    signal e2 : std_logic_vector(2 downto 1) := "00";
    signal m2 : std_logic_vector(23 downto 0) := x"400000";
    signal p2 : std_logic_vector(15 downto 0);
    signal g2, s2 : std_logic;

    -- Posit(32,2)
    signal k3 : signed(31 downto 0) := (others => '0');
    signal e3 : std_logic_vector(2 downto 1) := "00";
    signal m3 : std_logic_vector(55 downto 0)
        := x"40000000000000";
    signal p3 : std_logic_vector(31 downto 0);
    signal g3, s3 : std_logic;

begin

    d0 : entity work.posit_component_packing_generic
        generic map (N => 8, ES => 0)
        port map (
            k => k0, exponent => e0, mantissa => m0,
            positPacked => p0, guardBit => g0, stickyBit => s0
        );

    d1 : entity work.posit_component_packing_generic
        generic map (N => 8, ES => 1)
        port map (
            k => k1, exponent => e1, mantissa => m1,
            positPacked => p1, guardBit => g1, stickyBit => s1
        );

    d2 : entity work.posit_component_packing_generic
        generic map (N => 16, ES => 2)
        port map (
            k => k2, exponent => e2, mantissa => m2,
            positPacked => p2, guardBit => g2, stickyBit => s2
        );

    d3 : entity work.posit_component_packing_generic
        generic map (N => 32, ES => 2)
        port map (
            k => k3, exponent => e3, mantissa => m3,
            positPacked => p3, guardBit => g3, stickyBit => s3
        );

    stimulus : process
    begin

        -- TEST 1: +1, all configurations.
        wait for 1 ns;

        assert p0 = x"40" and p1 = x"40"
            and p2 = x"4000" and p3 = x"40000000"
            report "FAIL: packing +1"
            severity failure;

        assert g0 = '0' and s0 = '0'
            and g1 = '0' and s1 = '0'
            and g2 = '0' and s2 = '0'
            and g3 = '0' and s3 = '0'
            report "FAIL: unexpected guard/sticky"
            severity failure;

        report "PASS: +1 all configurations";


        -- TEST 2: ES=0, fractional bits.
        k0 <= to_signed(0, 8);
        m0 <= x"6A0"; -- 1.10101...
        wait for 1 ns;

        assert p0 = x"55" and g0 = '0' and s0 = '0'
            report "FAIL: ES=0 fraction"
            severity failure;

        report "PASS: ES=0 fraction";


        -- TEST 3: ES=1, fractional bits.
        m1 <= "01" & "10000000";
        wait for 1 ns;

        assert p1 = x"48" and g1 = '0' and s1 = '0'
            report "FAIL: ES=1 fraction"
            severity failure;

        report "PASS: ES=1 fraction";


        -- TEST 4: Guard bit.
        m1 <= "01" & "10001000";
        wait for 1 ns;

        assert p1 = x"48" and g1 = '1' and s1 = '0'
            report "FAIL: guard bit"
            severity failure;

        report "PASS: guard bit";


        -- TEST 5: Sticky bit from normalization.
        m1 <= "11" & "10001000";
        wait for 1 ns;

        assert p1 = x"48" and g1 = '1' and s1 = '1'
            report "FAIL: sticky bit"
            severity failure;

        report "PASS: sticky bit";


        -- Restore normal mantissa.
        m1 <= "01" & "00000000";


        -- TEST 6: Positive regime, ES=2.
        k2 <= to_signed(1, 16);
        e2 <= "11";
        wait for 1 ns;

        assert p2 = x"6C00"
            report "FAIL: positive regime ES=2"
            severity failure;

        report "PASS: positive regime ES=2";


        -- TEST 7: Negative regime, ES=2.
        k2 <= to_signed(-2, 16);
        e2 <= "01";
        wait for 1 ns;

        assert p2 = x"1400"
            report "FAIL: negative regime ES=2"
            severity failure;

        report "PASS: negative regime ES=2";


        -- TEST 8: Posit(32,2).
        k3 <= to_signed(-2, 32);
        e3 <= "11";
        wait for 1 ns;

        assert p3 = x"1C000000"
            report "FAIL: Posit(32,2) fields"
            severity failure;

        report "PASS: Posit(32,2) fields";


        -- TEST 9: Saturation below minpos.
        k1 <= to_signed(-7, 8);
        wait for 1 ns;

        assert p1 = x"01" and g1 = '0' and s1 = '0'
            report "FAIL: minpos saturation"
            severity failure;

        report "PASS: minpos saturation";


        -- TEST 10: Saturation above maxpos.
        k1 <= to_signed(6, 8);
        wait for 1 ns;

        assert p1 = x"7F" and g1 = '0' and s1 = '0'
            report "FAIL: maxpos saturation"
            severity failure;

        report "PASS: maxpos saturation";


        -- TEST 11: Lower extreme ES=1, exact midpoint.
        k1 <= to_signed(-6, 8);
        e1 <= "1";
        m1 <= "01" & "01000000"; -- 1.25
        wait for 1 ns;

        assert p1 = x"01" and g1 = '1' and s1 = '0'
            report "FAIL: ES=1 lower midpoint"
            severity failure;

        report "PASS: ES=1 lower midpoint";


        -- TEST 12: Upper extreme ES=1, exact midpoint.
        k1 <= to_signed(5, 8);
        wait for 1 ns;

        assert p1 = x"7E" and g1 = '0' and s1 = '0'
            report "FAIL: ES=1 upper midpoint"
            severity failure;

        report "PASS: ES=1 upper midpoint";


        -- TEST 13: Upper extreme ES=1, above midpoint.
        m1 <= "01" & "01000001";
        wait for 1 ns;

        assert p1 = x"7E" and g1 = '1' and s1 = '1'
            report "FAIL: ES=1 above midpoint"
            severity failure;

        report "PASS: ES=1 above midpoint";


        -- TEST 14: Lower extreme ES=0, midpoint 1.5.
        k0 <= to_signed(-6, 8);
        m0 <= x"600";
        wait for 1 ns;

        assert p0 = x"01" and g0 = '1' and s0 = '0'
            report "FAIL: ES=0 lower midpoint"
            severity failure;

        report "PASS: ES=0 lower midpoint";


        -- TEST 15: Lower extreme ES=2.
        -- Maximum exponent 3, mantissa midpoint 1.0625.
        k2 <= to_signed(-14, 16);
        e2 <= "11";
        m2 <= x"440000";
        wait for 1 ns;

        assert p2 = x"0001" and g2 = '1' and s2 = '0'
            report "FAIL: ES=2 lower midpoint"
            severity failure;

        report "PASS: ES=2 lower midpoint";


        -- TEST 16: Upper extreme ES=2.
        k2 <= to_signed(13, 16);
        wait for 1 ns;

        assert p2 = x"7FFE" and g2 = '0' and s2 = '0'
            report "FAIL: ES=2 upper midpoint"
            severity failure;

        report "PASS: ES=2 upper midpoint";


        -- TEST 17: Upper extreme ES=2, above midpoint.
        m2 <= x"440001";
        wait for 1 ns;

        assert p2 = x"7FFE" and g2 = '1' and s2 = '1'
            report "FAIL: ES=2 above midpoint"
            severity failure;

        report "PASS: ES=2 above midpoint";


        report "ALL PACKING TESTS PASSED" severity note;
        finish;

    end process;

end architecture test;
