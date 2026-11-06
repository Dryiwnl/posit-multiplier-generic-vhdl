
---------------------------------------
-- Packing - Generic Posit (N, ES)
-- Engineer: Matheus Vigano Schirrmann
-- Company: ProtoFPGA - UFSC
---------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity posit_component_packing_generic is
    generic (
        N  : positive := 8;
        ES : natural  := 1
    );
    port (
        k        : in signed(N-1 downto 0);
        exponent : in std_logic_vector(ES downto 1);

        mantissa : in std_logic_vector(
            2*(N-ES-2)-1 downto 0
        );

        positPacked : out std_logic_vector(N-1 downto 0);
        guardBit    : out std_logic;
        stickyBit   : out std_logic
    );
end entity posit_component_packing_generic;

architecture rtl of posit_component_packing_generic is

    constant M_WIDTH : positive := 2*(N-ES-2);
    constant F_BITS  : positive := M_WIDTH-2;

begin

    assert N >= ES + 4
        report "Invalid Posit configuration"
        severity failure;

    process(all)
        variable k_int      : integer;
        variable m          : integer;
        variable total_bits : integer;
        variable bit_value  : std_logic;

        variable packed_aux : std_logic_vector(N-1 downto 0);
        variable guard_aux  : std_logic;
        variable sticky_aux : std_logic;

        variable fraction_value : unsigned(F_BITS-1 downto 0);
        variable threshold_frac : unsigned(F_BITS-1 downto 0);
        variable threshold_pos  : natural;

        variable above_midpoint : boolean;
        variable at_midpoint    : boolean;

    begin

        k_int := to_integer(k);

        packed_aux := (others => '0');
        guard_aux  := '0';
        sticky_aux := '0';

        m := 0;
        total_bits := 0;

        fraction_value :=
            unsigned(mantissa(M_WIDTH-3 downto 0));

        threshold_frac := (others => '0');
        threshold_pos := 1;

        above_midpoint := false;
        at_midpoint := false;

        ------------------------------------------------
        -- Saturation below minpos
        ------------------------------------------------
        if k_int < -(N-2) then

            packed_aux :=
                std_logic_vector(to_unsigned(1, N));

        ------------------------------------------------
        -- Saturation above maxpos
        ------------------------------------------------
        elsif k_int >= N-2 then

            packed_aux := std_logic_vector(
                shift_left(to_unsigned(1, N), N-1) - 1
            );

        else

            ------------------------------------------------
            -- Regime length
            ------------------------------------------------
            if k_int < 0 then
                m := -k_int;
            else
                m := k_int + 1;
            end if;

            total_bits := m + 1 + ES + F_BITS;

            ------------------------------------------------
            -- Generate regime, exponent and fraction
            ------------------------------------------------
            for i in 0 to total_bits-1 loop

                bit_value := '0';

                if i < m then

                    if k_int >= 0 then
                        bit_value := '1';
                    end if;

                elsif i = m then

                    if k_int < 0 then
                        bit_value := '1';
                    end if;

                elsif i < m + 1 + ES then

                    bit_value := exponent(
                        ES - (i - (m + 1))
                    );

                else

                    bit_value := mantissa(
                        M_WIDTH-3 -
                        (i - (m + 1 + ES))
                    );

                end if;

                if i <= N-2 then

                    packed_aux(N-2-i) := bit_value;

                elsif i = N-1 then

                    guard_aux := bit_value;

                else

                    sticky_aux := sticky_aux or bit_value;

                end if;

            end loop;

            ------------------------------------------------
            -- Preserve discarded bit from normalization
            ------------------------------------------------
            sticky_aux :=
                sticky_aux or mantissa(M_WIDTH-1);

            ------------------------------------------------
            -- Extreme regime rounding
            ------------------------------------------------
            if k_int = -(N-2) or k_int = N-3 then

                guard_aux  := '0';
                sticky_aux := '0';

                threshold_pos := 1;

                for j in 1 to ES loop
                    if threshold_pos <= F_BITS then
                        threshold_pos := threshold_pos * 2;
                    end if;
                end loop;

                if exponent =
                    (exponent'range => '1') then

                    if threshold_pos <= F_BITS then

                        threshold_frac := shift_left(
                            to_unsigned(1, F_BITS),
                            F_BITS-threshold_pos
                        );

                        if fraction_value > threshold_frac then

                            above_midpoint := true;

                        elsif fraction_value = threshold_frac then

                            if mantissa(M_WIDTH-1) = '1' then
                                above_midpoint := true;
                            else
                                at_midpoint := true;
                            end if;

                        end if;

                    else

                        if fraction_value /= 0 then

                            above_midpoint := true;

                        elsif mantissa(M_WIDTH-1) = '1' then

                            if threshold_pos = F_BITS+1 then
                                at_midpoint := true;
                            else
                                above_midpoint := true;
                            end if;

                        end if;

                    end if;

                end if;

                if k_int = -(N-2) then

                    if above_midpoint or at_midpoint then
                        guard_aux := '1';
                    end if;

                else

                    if above_midpoint then
                        guard_aux  := '1';
                        sticky_aux := '1';
                    end if;

                end if;

            end if;

            ------------------------------------------------
            -- Correction for ES=2 near extreme regimes
            ------------------------------------------------
            if ES = 2 and
               (k_int = -(N-3) or k_int = N-4) then

                if exponent(1) = '1' then

                    threshold_frac := shift_left(
                        to_unsigned(1, F_BITS),
                        F_BITS-2
                    );

                    if fraction_value > threshold_frac then

                        guard_aux  := '1';
                        sticky_aux := '1';

                    elsif fraction_value = threshold_frac then

                        guard_aux := '1';
                        sticky_aux := mantissa(M_WIDTH-1);

                    else

                        guard_aux  := '0';
                        sticky_aux := '0';

                    end if;

                end if;

            end if;

        end if;

        ------------------------------------------------
        -- Outputs
        ------------------------------------------------
        positPacked <= packed_aux;
        guardBit    <= guard_aux;
        stickyBit   <= sticky_aux;

    end process;

end architecture rtl;
