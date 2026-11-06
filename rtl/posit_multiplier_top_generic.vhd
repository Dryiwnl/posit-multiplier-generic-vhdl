
----------------------------------------------------------------------------------
-- Company: ProtoFPGA - UFSC
-- Engineer: Matheus Vigano Schirrmann
--
-- Module Name: posit_multiplier_top_generic
-- Description: Generic Posit (N, ES) multiplier
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity posit_multiplier_top_generic is
    generic (
        N  : positive := 8;
        ES : natural  := 1
    );
    port (
        positA      : in  std_logic_vector(N-1 downto 0);
        positB      : in  std_logic_vector(N-1 downto 0);
        positResult : out std_logic_vector(N-1 downto 0)
    );
end entity posit_multiplier_top_generic;

architecture rtl of posit_multiplier_top_generic is

    constant F_WIDTH : positive := N-ES-3;
    constant M_WIDTH : positive := 2*(N-ES-2);

    -- Operand A
    signal signA     : std_logic;
    signal kA        : signed(N-2 downto 0);
    signal exponentA : std_logic_vector(ES downto 1);
    signal fractionA : std_logic_vector(F_WIDTH-1 downto 0);
    signal zeroA, narA : std_logic;

    -- Operand B
    signal signB     : std_logic;
    signal kB        : signed(N-2 downto 0);
    signal exponentB : std_logic_vector(ES downto 1);
    signal fractionB : std_logic_vector(F_WIDTH-1 downto 0);
    signal zeroB, narB : std_logic;

    -- Sign and scale
    signal signResult     : std_logic;
    signal kResult        : signed(N-1 downto 0);
    signal exponentResult : std_logic_vector(ES downto 1);

    -- Mantissa multiplication
    signal mantissaResult : std_logic_vector(M_WIDTH-1 downto 0);

    -- Normalization
    signal mantissaNormalized : std_logic_vector(M_WIDTH-1 downto 0);
    signal normalizationCarry : std_logic;
    signal kResultNormalized  : signed(N-1 downto 0);
    signal exponentResultNormalized :
        std_logic_vector(ES downto 1);

    -- Packing and rounding
    signal positPacked  : std_logic_vector(N-1 downto 0);
    signal guardBit     : std_logic;
    signal stickyBit    : std_logic;
    signal positRounded : std_logic_vector(N-1 downto 0);

    constant POSIT_ZERO : std_logic_vector(N-1 downto 0) :=
        (others => '0');

    constant POSIT_NAR : std_logic_vector(N-1 downto 0) :=
        (N-1 => '1', others => '0');

begin

    assert N >= ES + 4
        report "Invalid Posit configuration"
        severity failure;

    ------------------------------------------------
    -- Decoder A
    ------------------------------------------------

    decoderA_inst : entity work.decoder_posit_generic
        generic map (
            N => N,
            ES => ES
        )
        port map (
            posit_in => positA,
            sign     => signA,
            k        => kA,
            exponent => exponentA,
            fraction => fractionA,
            is_zero  => zeroA,
            is_nar   => narA
        );

    ------------------------------------------------
    -- Decoder B
    ------------------------------------------------

    decoderB_inst : entity work.decoder_posit_generic
        generic map (
            N => N,
            ES => ES
        )
        port map (
            posit_in => positB,
            sign     => signB,
            k        => kB,
            exponent => exponentB,
            fraction => fractionB,
            is_zero  => zeroB,
            is_nar   => narB
        );

    ------------------------------------------------
    -- Sign and Exponent Processing Unit
    ------------------------------------------------

    sign_and_exponent_PU_inst :
        entity work.sign_and_exponent_PU_generic
        generic map (
            N => N,
            ES => ES
        )
        port map (
            sign_A => signA,
            sign_B => signB,
            k_A => kA,
            k_B => kB,
            exponent_A => exponentA,
            exponent_B => exponentB,
            sign_result => signResult,
            k_result => kResult,
            exponent_result => exponentResult
        );

    ------------------------------------------------
    -- Mantissa Multiplier
    ------------------------------------------------

    mantissa_multiplier_inst :
        entity work.mantissa_multiplier_generic
        generic map (
            N => N,
            ES => ES
        )
        port map (
            fractionA => fractionA,
            fractionB => fractionB,
            mantissaResult => mantissaResult
        );

    ------------------------------------------------
    -- Normalization
    ------------------------------------------------

    normalization_inst :
        entity work.normalization_generic
        generic map (
            N => N,
            ES => ES
        )
        port map (
            mantissaResult => mantissaResult,
            kResult => kResult,
            exponentResult => exponentResult,
            mantissaNormalized => mantissaNormalized,
            normalizationCarry => normalizationCarry,
            kResultNormalized => kResultNormalized,
            exponentResultNormalized => exponentResultNormalized
        );

    ------------------------------------------------
    -- Posit Component Packing
    ------------------------------------------------

    posit_packing_inst :
        entity work.posit_component_packing_generic
        generic map (
            N => N,
            ES => ES
        )
        port map (
            k => kResultNormalized,
            exponent => exponentResultNormalized,
            mantissa => mantissaNormalized,
            positPacked => positPacked,
            guardBit => guardBit,
            stickyBit => stickyBit
        );

    ------------------------------------------------
    -- Rounding and Sign Application
    ------------------------------------------------

    posit_rounding_inst :
        entity work.posit_rounding_generic
        generic map (
            N => N,
            ES => ES
        )
        port map (
            positPacked => positPacked,
            guardBit => guardBit,
            stickyBit => stickyBit,
            sign => signResult,
            positRounded => positRounded
        );

    ------------------------------------------------
    -- Special Values
    -- NaR has priority over zero.
    ------------------------------------------------

    positResult <= POSIT_NAR
        when narA = '1' or narB = '1'
        else POSIT_ZERO
        when zeroA = '1' or zeroB = '1'
        else positRounded;

end architecture rtl;
