library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;
use std.env.all;

entity tb_posit_multiplier_64_reference is
end entity;

architecture test of tb_posit_multiplier_64_reference is
    constant N : positive := 64;
    constant ES : natural := 2;
    signal a, b, result_posit : std_logic_vector(N-1 downto 0) := (others => '0');
begin
    dut : entity work.posit_multiplier_top_generic
        generic map (N => N, ES => ES)
        port map (positA => a, positB => b, positResult => result_posit);

    stimulus : process
        file vectors : text;
        variable status : file_open_status;
        variable row_data : line;
        variable operand_a, operand_b, expected : std_logic_vector(N-1 downto 0);
        variable count : natural := 0;
    begin
        file_open(status, vectors,
            "verification/test_vectors/posit64_es2_samples.txt", read_mode);
        if status /= open_ok then
            file_open(status, vectors,
                "C:/FPGA/Posit_Generic_vivado/verification/posit64_es2_samples.txt",
                read_mode);
        end if;
        assert status = open_ok
            report "Cannot open posit64_es2_samples.txt: save it in C:/FPGA/Posit_Generic_vivado/verification"
            severity failure;

        while not endfile(vectors) loop
            readline(vectors, row_data);
            hread(row_data, operand_a);
            hread(row_data, operand_b);
            hread(row_data, expected);
            a <= operand_a;
            b <= operand_b;
            wait for 1 ns;
            assert result_posit = expected
                report "FAIL Posit(64,2) pair " & integer'image(count) &
                       " A=" & to_hstring(operand_a) &
                       " B=" & to_hstring(operand_b) &
                       " expected=" & to_hstring(expected) &
                       " got=" & to_hstring(result_posit)
                severity failure;
            count := count + 1;
        end loop;
        file_close(vectors);
        report "PASS Posit(64,2): " & integer'image(count) & " pairs" severity note;
        finish;
    end process;
end architecture;