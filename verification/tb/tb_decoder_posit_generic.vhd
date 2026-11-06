
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity tb_decoder_posit_generic is
end entity;

architecture test of tb_decoder_posit_generic is

    signal a0, a1 : std_logic_vector(7 downto 0)
        := (others => '0');

    signal b2 : std_logic_vector(15 downto 0)
        := (others => '0');

    signal c2 : std_logic_vector(31 downto 0)
        := (others => '0');

    signal s0, s1, s2, s3 : std_logic;
    signal z0, z1, z2, z3 : std_logic;
    signal n0, n1, n2, n3 : std_logic;

    signal k0, k1 : signed(6 downto 0);
    signal k2 : signed(14 downto 0);
    signal k3 : signed(30 downto 0);

    signal e0 : std_logic_vector(0 downto 1);
    signal e1 : std_logic_vector(1 downto 1);
    signal e2, e3 : std_logic_vector(2 downto 1);

    signal f0 : std_logic_vector(4 downto 0);
    signal f1 : std_logic_vector(3 downto 0);
    signal f2 : std_logic_vector(10 downto 0);
    signal f3 : std_logic_vector(26 downto 0);

begin

    d0 : entity work.decoder_posit_generic
        generic map (N => 8, ES => 0)
        port map (
            posit_in => a0, sign => s0, k => k0,
            exponent => e0, fraction => f0,
            is_zero => z0, is_nar => n0
        );

    d1 : entity work.decoder_posit_generic
        generic map (N => 8, ES => 1)
        port map (
            posit_in => a1, sign => s1, k => k1,
            exponent => e1, fraction => f1,
            is_zero => z1, is_nar => n1
        );

    d2 : entity work.decoder_posit_generic
        generic map (N => 16, ES => 2)
        port map (
            posit_in => b2, sign => s2, k => k2,
            exponent => e2, fraction => f2,
            is_zero => z2, is_nar => n2
        );

    d3 : entity work.decoder_posit_generic
        generic map (N => 32, ES => 2)
        port map (
            posit_in => c2, sign => s3, k => k3,
            exponent => e3, fraction => f3,
            is_zero => z3, is_nar => n3
        );

    stimulus : process
    begin

        -- Test 1: +1 in all configurations.
        a0 <= x"40";
        a1 <= x"40";
        b2 <= x"4000";
        c2 <= x"40000000";
        wait for 1 ns;

        assert s0 = '0' and to_integer(k0) = 0
            and unsigned(f0) = 0 and e0'length = 0
            report "FAIL: Posit(8,0) +1"
            severity error;

        assert s1 = '0' and to_integer(k1) = 0
            and e1 = "0" and unsigned(f1) = 0
            report "FAIL: Posit(8,1) +1"
            severity error;

        assert s2 = '0' and to_integer(k2) = 0
            and e2 = "00" and unsigned(f2) = 0
            report "FAIL: Posit(16,2) +1"
            severity error;

        assert s3 = '0' and to_integer(k3) = 0
            and e3 = "00" and unsigned(f3) = 0
            report "FAIL: Posit(32,2) +1"
            severity error;

        report "PASS: +1";

        -- Test 2: +2 in all configurations.
        a0 <= x"60";
        a1 <= x"50";
        b2 <= x"4800";
        c2 <= x"48000000";
        wait for 1 ns;

        assert to_integer(k0) = 1
            and unsigned(f0) = 0
            report "FAIL: Posit(8,0) +2"
            severity error;

        assert to_integer(k1) = 0 and e1 = "1"
            and unsigned(f1) = 0
            report "FAIL: Posit(8,1) +2"
            severity error;

        assert to_integer(k2) = 0 and e2 = "01"
            and unsigned(f2) = 0
            report "FAIL: Posit(16,2) +2"
            severity error;

        assert to_integer(k3) = 0 and e3 = "01"
            and unsigned(f3) = 0
            report "FAIL: Posit(32,2) +2"
            severity error;

        report "PASS: +2";

        -- Test 3: -1 in all configurations.
        a0 <= x"C0";
        a1 <= x"C0";
        b2 <= x"C000";
        c2 <= x"C0000000";
        wait for 1 ns;

        assert s0 = '1' and to_integer(k0) = 0
            and unsigned(f0) = 0
            report "FAIL: Posit(8,0) -1"
            severity error;

        assert s1 = '1' and to_integer(k1) = 0
            and e1 = "0" and unsigned(f1) = 0
            report "FAIL: Posit(8,1) -1"
            severity error;

        assert s2 = '1' and to_integer(k2) = 0
            and e2 = "00" and unsigned(f2) = 0
            report "FAIL: Posit(16,2) -1"
            severity error;

        assert s3 = '1' and to_integer(k3) = 0
            and e3 = "00" and unsigned(f3) = 0
            report "FAIL: Posit(32,2) -1"
            severity error;

        report "PASS: -1";

        -- Test 4: zero.
        a0 <= x"00";
        a1 <= x"00";
        b2 <= x"0000";
        c2 <= x"00000000";
        wait for 1 ns;

        assert z0 = '1' and z1 = '1'
            and z2 = '1' and z3 = '1'
            report "FAIL: zero detection"
            severity error;

        assert n0 = '0' and n1 = '0'
            and n2 = '0' and n3 = '0'
            report "FAIL: zero incorrectly detected as NaR"
            severity error;

        report "PASS: zero";

        -- Test 5: NaR.
        a0 <= x"80";
        a1 <= x"80";
        b2 <= x"8000";
        c2 <= x"80000000";
        wait for 1 ns;

        assert n0 = '1' and n1 = '1'
            and n2 = '1' and n3 = '1'
            report "FAIL: NaR detection"
            severity error;

        assert z0 = '0' and z1 = '0'
            and z2 = '0' and z3 = '0'
            report "FAIL: NaR incorrectly detected as zero"
            severity error;

        report "PASS: NaR";

        
        -- TEST 6: Positive regime and fraction, Posit(8,1).
        -- 0 | 110 | 1 | 100 = +12
        a1 <= x"6C";
        wait for 1 ns;

        assert s1 = '0'
            and to_integer(k1) = 1
            and e1 = "1"
            and f1 = "1000"
            and z1 = '0' and n1 = '0'
            report "FAIL: Posit(8,1) +12"
            severity error;

        report "PASS: positive regime and fraction";


        -- TEST 7: Negative operand with nonzero fraction.
        -- -1.5 is encoded as B8; magnitude is 48.
        a1 <= x"B8";
        wait for 1 ns;

        assert s1 = '1'
            and to_integer(k1) = 0
            and e1 = "0"
            and f1 = "1000"
            report "FAIL: Posit(8,1) -1.5"
            severity error;

        report "PASS: negative operand and fraction";


        -- TEST 8: Negative regime, Posit(8,1).
        -- 0 | 001 | 0 | 000 = 1/16
        a1 <= x"10";
        wait for 1 ns;

        assert s1 = '0'
            and to_integer(k1) = -2
            and e1 = "0"
            and f1 = "0000"
            report "FAIL: Posit(8,1) negative regime"
            severity error;

        report "PASS: negative regime";


        -- TEST 9: ES=0, positive regime.
        -- 0 | 1110 | 000 = 4
        a0 <= x"70";
        wait for 1 ns;

        assert s0 = '0'
            and to_integer(k0) = 2
            and f0 = "00000"
            report "FAIL: Posit(8,0) positive regime"
            severity error;

        report "PASS: ES=0 positive regime";


        -- TEST 10: ES=0, negative regime.
        -- 0 | 0001 | 000 = 1/8
        a0 <= x"08";
        wait for 1 ns;

        assert to_integer(k0) = -3
            and f0 = "00000"
            report "FAIL: Posit(8,0) negative regime"
            severity error;

        report "PASS: ES=0 negative regime";


        -- TEST 11: Posit(16,2), regime +2.
        -- Sign | regime | exponent | fraction
        b2 <= '0' & "1110" & "10" & "101010101";
        wait for 1 ns;

        assert s2 = '0'
            and to_integer(k2) = 2
            and e2 = "10"
            and f2 = "10101010100"
            report "FAIL: Posit(16,2) fields"
            severity error;

        report "PASS: Posit(16,2) fields";


        -- TEST 12: Posit(32,2), regime -2.
        c2 <= '0' & "001" & "11" &
              "10101010101010101010101010";
        wait for 1 ns;

        assert s3 = '0'
            and to_integer(k3) = -2
            and e3 = "11"
            and f3 = "101010101010101010101010100"
            report "FAIL: Posit(32,2) fields"
            severity error;

        report "PASS: Posit(32,2) fields";


        -- TEST 13: Extremes, Posit(8,1).
        a1 <= x"7F"; -- maxpos
        wait for 1 ns;

        assert to_integer(k1) = 6
            and e1 = "0"
            and f1 = "0000"
            report "FAIL: Posit(8,1) maxpos"
            severity error;

        a1 <= x"01"; -- minpos
        wait for 1 ns;

        assert to_integer(k1) = -6
            and e1 = "0"
            and f1 = "0000"
            report "FAIL: Posit(8,1) minpos"
            severity error;

        report "PASS: Posit(8,1) extremes";


        -- TEST 14: Extremes, Posit(16,2).
        b2 <= x"7FFF"; -- maxpos
        wait for 1 ns;

        assert to_integer(k2) = 14
            and e2 = "00"
            and unsigned(f2) = 0
            report "FAIL: Posit(16,2) maxpos"
            severity error;

        b2 <= x"0001"; -- minpos
        wait for 1 ns;

        assert to_integer(k2) = -14
            and e2 = "00"
            and unsigned(f2) = 0
            report "FAIL: Posit(16,2) minpos"
            severity error;

        report "PASS: Posit(16,2) extremes";


        -- TEST 15: Extremes, Posit(32,2).
        c2 <= x"7FFFFFFF"; -- maxpos
        wait for 1 ns;

        assert to_integer(k3) = 30
            and e3 = "00"
            and unsigned(f3) = 0
            report "FAIL: Posit(32,2) maxpos"
            severity error;

        c2 <= x"00000001"; -- minpos
        wait for 1 ns;

        assert to_integer(k3) = -30
            and e3 = "00"
            and unsigned(f3) = 0
            report "FAIL: Posit(32,2) minpos"
            severity error;

        report "PASS: Posit(32,2) extremes";
        finish;
    end process;

end architecture test;
