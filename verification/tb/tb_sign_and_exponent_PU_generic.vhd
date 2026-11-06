
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity tb_sign_and_exponent_PU_generic is
end entity;

architecture test of tb_sign_and_exponent_PU_generic is

    -- Posit(8,0)
    signal sa0, sb0, sr0 : std_logic := '0';
    signal ka0, kb0 : signed(6 downto 0) := (others => '0');
    signal kr0 : signed(7 downto 0);
    signal ea0, eb0, er0 : std_logic_vector(0 downto 1);

    -- Posit(8,1)
    signal sa1, sb1, sr1 : std_logic := '0';
    signal ka1, kb1 : signed(6 downto 0) := (others => '0');
    signal kr1 : signed(7 downto 0);
    signal ea1, eb1 : std_logic_vector(1 downto 1) := "0";
    signal er1 : std_logic_vector(1 downto 1);

    -- Posit(16,2)
    signal sa2, sb2, sr2 : std_logic := '0';
    signal ka2, kb2 : signed(14 downto 0) := (others => '0');
    signal kr2 : signed(15 downto 0);
    signal ea2, eb2 : std_logic_vector(2 downto 1) := "00";
    signal er2 : std_logic_vector(2 downto 1);

    -- Posit(32,2)
    signal sa3, sb3, sr3 : std_logic := '0';
    signal ka3, kb3 : signed(30 downto 0) := (others => '0');
    signal kr3 : signed(31 downto 0);
    signal ea3, eb3 : std_logic_vector(2 downto 1) := "00";
    signal er3 : std_logic_vector(2 downto 1);

begin

    dut0 : entity work.sign_and_exponent_PU_generic
        generic map (N => 8, ES => 0)
        port map (
            sign_A => sa0, sign_B => sb0,
            k_A => ka0, k_B => kb0,
            exponent_A => ea0, exponent_B => eb0,
            sign_result => sr0,
            k_result => kr0,
            exponent_result => er0
        );

    dut1 : entity work.sign_and_exponent_PU_generic
        generic map (N => 8, ES => 1)
        port map (
            sign_A => sa1, sign_B => sb1,
            k_A => ka1, k_B => kb1,
            exponent_A => ea1, exponent_B => eb1,
            sign_result => sr1,
            k_result => kr1,
            exponent_result => er1
        );

    dut2 : entity work.sign_and_exponent_PU_generic
        generic map (N => 16, ES => 2)
        port map (
            sign_A => sa2, sign_B => sb2,
            k_A => ka2, k_B => kb2,
            exponent_A => ea2, exponent_B => eb2,
            sign_result => sr2,
            k_result => kr2,
            exponent_result => er2
        );

    dut3 : entity work.sign_and_exponent_PU_generic
        generic map (N => 32, ES => 2)
        port map (
            sign_A => sa3, sign_B => sb3,
            k_A => ka3, k_B => kb3,
            exponent_A => ea3, exponent_B => eb3,
            sign_result => sr3,
            k_result => kr3,
            exponent_result => er3
        );

    stimulus : process
    begin

        -- TEST 1: ES=0, positive + negative regime.
        sa0 <= '1';
        sb0 <= '0';
        ka0 <= to_signed(2, 7);
        kb0 <= to_signed(-3, 7);
        wait for 1 ns;

        assert sr0 = '1'
            and to_integer(kr0) = -1
            and er0'length = 0
            report "FAIL: Posit(8,0)"
            severity failure;

        report "PASS: Posit(8,0)";


        -- TEST 2: ES=1, exponent carry.
        -- k = 1 + (-2) + 1 = 0
        -- e = 1 + 1 = 2 -> carry 1, remainder 0
        sa1 <= '1';
        sb1 <= '1';
        ka1 <= to_signed(1, 7);
        kb1 <= to_signed(-2, 7);
        ea1 <= "1";
        eb1 <= "1";
        wait for 1 ns;

        assert sr1 = '0'
            and to_integer(kr1) = 0
            and er1 = "0"
            report "FAIL: Posit(8,1) carry"
            severity failure;

        report "PASS: Posit(8,1) carry";


        -- TEST 3: ES=2, exponent carry.
        -- k = 1 + (-2) + 1 = 0
        -- e = 3 + 2 = 5 -> carry 1, remainder 1
        sa2 <= '0';
        sb2 <= '1';
        ka2 <= to_signed(1, 15);
        kb2 <= to_signed(-2, 15);
        ea2 <= "11";
        eb2 <= "10";
        wait for 1 ns;

        assert sr2 = '1'
            and to_integer(kr2) = 0
            and er2 = "01"
            report "FAIL: Posit(16,2) carry"
            severity failure;

        report "PASS: Posit(16,2) carry";


        -- TEST 4: ES=2, extreme regime values.
        -- k = -30 + 30 + 1 = 1
        -- e = 3 + 3 = 6 -> carry 1, remainder 2
        sa3 <= '1';
        sb3 <= '1';
        ka3 <= to_signed(-30, 31);
        kb3 <= to_signed(30, 31);
        ea3 <= "11";
        eb3 <= "11";
        wait for 1 ns;

        assert sr3 = '0'
            and to_integer(kr3) = 1
            and er3 = "10"
            report "FAIL: Posit(32,2) carry"
            severity failure;

        report "PASS: Posit(32,2) carry";


        -- TEST 5: No carry, ES=2.
        -- k = -1 + 2 = 1
        -- e = 1 + 2 = 3
        ka2 <= to_signed(-1, 15);
        kb2 <= to_signed(2, 15);
        ea2 <= "01";
        eb2 <= "10";
        wait for 1 ns;

        assert to_integer(kr2) = 1
            and er2 = "11"
            report "FAIL: Posit(16,2) no carry"
            severity failure;

        report "PASS: no exponent carry";


        -- TEST 6: No carry, ES=1.
        -- k = -2 + 3 = 1
        -- e = 0 + 1 = 1
        ka1 <= to_signed(-2, 7);
        kb1 <= to_signed(3, 7);
        ea1 <= "0";
        eb1 <= "1";
        wait for 1 ns;

        assert to_integer(kr1) = 1
            and er1 = "1"
            report "FAIL: Posit(8,1) no carry"
            severity failure;

        report "PASS: ES=1 no carry";


        report "ALL SIGN/EXPONENT TESTS PASSED"
            severity note;

        finish;
    end process;

end architecture test;
