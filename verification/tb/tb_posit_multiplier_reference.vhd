library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;
use std.env.all;

entity tb_posit_multiplier_reference is
end entity;

architecture test of tb_posit_multiplier_reference is
    signal a80, b80, r80 : std_logic_vector(7 downto 0) := (others => '0');
    signal a81, b81, r81 : std_logic_vector(7 downto 0) := (others => '0');
    signal a16, b16, r16 : std_logic_vector(15 downto 0) := (others => '0');
    signal a32, b32, r32 : std_logic_vector(31 downto 0) := (others => '0');
begin
    u80 : entity work.posit_multiplier_top_generic
        generic map (N => 8, ES => 0)
        port map (positA => a80, positB => b80, positResult => r80);
    u81 : entity work.posit_multiplier_top_generic
        generic map (N => 8, ES => 1)
        port map (positA => a81, positB => b81, positResult => r81);
    u16 : entity work.posit_multiplier_top_generic
        generic map (N => 16, ES => 2)
        port map (positA => a16, positB => b16, positResult => r16);
    u32 : entity work.posit_multiplier_top_generic
        generic map (N => 32, ES => 2)
        port map (positA => a32, positB => b32, positResult => r32);

    stimulus : process
        file f80 : text;
        file f81 : text;
        file f16 : text;
        file f32 : text;
        variable status : file_open_status;
        variable l : line;
        variable x8, y8, expected8 : std_logic_vector(7 downto 0);
        variable x16, y16, expected16 : std_logic_vector(15 downto 0);
        variable x32, y32, expected32 : std_logic_vector(31 downto 0);
        variable count : natural;
    begin
        file_open(status, f80,
            "C:/FPGA/Posit_Generic_vivado/verification/posit8_es0_all.txt", read_mode);
        assert status = open_ok report "Cannot open posit8_es0_all.txt" severity failure;
        count := 0;
        while not endfile(f80) loop
            readline(f80, l);
            hread(l, x8); hread(l, y8); hread(l, expected8);
            a80 <= x8; b80 <= y8;
            wait for 1 ns;
            assert r80 = expected8
                report "FAIL Posit(8,0) pair " & integer'image(count) &
                       " A=" & to_hstring(x8) & " B=" & to_hstring(y8) &
                       " expected=" & to_hstring(expected8) &
                       " got=" & to_hstring(r80)
                severity failure;
            count := count + 1;
        end loop;
        file_close(f80);
        report "PASS Posit(8,0): " & integer'image(count) & " pairs";

        file_open(status, f81,
            "C:/FPGA/Posit_Generic_vivado/verification/posit8_es1_all.txt", read_mode);
        assert status = open_ok report "Cannot open posit8_es1_all.txt" severity failure;
        count := 0;
        while not endfile(f81) loop
            readline(f81, l);
            hread(l, x8); hread(l, y8); hread(l, expected8);
            a81 <= x8; b81 <= y8;
            wait for 1 ns;
            assert r81 = expected8
                report "FAIL Posit(8,1) pair " & integer'image(count) &
                       " A=" & to_hstring(x8) & " B=" & to_hstring(y8) &
                       " expected=" & to_hstring(expected8) &
                       " got=" & to_hstring(r81)
                severity failure;
            count := count + 1;
        end loop;
        file_close(f81);
        report "PASS Posit(8,1): " & integer'image(count) & " pairs";

        file_open(status, f16,
            "C:/FPGA/Posit_Generic_vivado/verification/posit16_es2_samples.txt", read_mode);
        assert status = open_ok report "Cannot open posit16_es2_samples.txt" severity failure;
        count := 0;
        while not endfile(f16) loop
            readline(f16, l);
            hread(l, x16); hread(l, y16); hread(l, expected16);
            a16 <= x16; b16 <= y16;
            wait for 1 ns;
            assert r16 = expected16
                report "FAIL Posit(16,2) pair " & integer'image(count) &
                       " A=" & to_hstring(x16) & " B=" & to_hstring(y16) &
                       " expected=" & to_hstring(expected16) &
                       " got=" & to_hstring(r16)
                severity failure;
            count := count + 1;
        end loop;
        file_close(f16);
        report "PASS Posit(16,2): " & integer'image(count) & " pairs";

        file_open(status, f32,
            "C:/FPGA/Posit_Generic_vivado/verification/posit32_es2_samples.txt", read_mode);
        assert status = open_ok report "Cannot open posit32_es2_samples.txt" severity failure;
        count := 0;
        while not endfile(f32) loop
            readline(f32, l);
            hread(l, x32); hread(l, y32); hread(l, expected32);
            a32 <= x32; b32 <= y32;
            wait for 1 ns;
            assert r32 = expected32
                report "FAIL Posit(32,2) pair " & integer'image(count) &
                       " A=" & to_hstring(x32) & " B=" & to_hstring(y32) &
                       " expected=" & to_hstring(expected32) &
                       " got=" & to_hstring(r32)
                severity failure;
            count := count + 1;
        end loop;
        file_close(f32);
        report "PASS Posit(32,2): " & integer'image(count) & " pairs";

        report "ALL REFERENCE TESTS PASSED" severity note;
        finish;
    end process;
end architecture;
