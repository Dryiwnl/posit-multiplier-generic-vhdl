# Generic Posit (N, ES) Multiplier — VHDL

A combinational, parameterized Posit multiplier written in VHDL-2008. It exposes `N` (total bits) and `ES` (maximum exponent bits, including `ES=0`) and implements round-to-nearest, ties-to-even (RNE). NaR has priority over zero.

**Status:** functionally validated for the configurations listed below. **Synthesis on the Nexys A7-100T with Vivado 2025.1 is pending.** Other parameter combinations, including 64-bit formats, have not yet been validated.

## Architecture

The synthesizable modules are in [`rtl/`](rtl/):

1. `decoder_posit_generic.vhd` — operand sign, regime, exponent and fraction.
2. `sign_and_exponent_PU_generic.vhd` — combines signs and scales.
3. `mantissa_multiplier_generic.vhd` — multiplies significands.
4. `normalization_generic.vhd` — normalizes the product and adjusts scale.
5. `posit_component_packing_generic.vhd` — builds the positive Posit and computes guard/sticky.
6. `posit_rounding_generic.vhd` — RNE rounding and sign application.
7. `posit_multiplier_top_generic.vhd` — top-level integration and NaR/zero selection.

**Top entity:** `posit_multiplier_top_generic`. Generics: `N` (default `8`), `ES` (default `1`). Ports: `positA`, `positB`, and `positResult`, all `N` bits wide.

## Functional verification

The integrated RTL was compared with reference vectors produced using exact rational arithmetic in Python:

| Format | Operand pairs | Coverage |
|---|---:|---|
| Posit(8,0) | 65,536 | Exhaustive |
| Posit(8,1) | 65,536 | Exhaustive |
| Posit(16,2) | 20,000 | Reproducible directed/random sample |
| Posit(32,2) | 20,000 | Reproducible directed/random sample |
| **Total** | **171,072** | **All passed in Vivado XSim 2026.1** |

These results do not establish exhaustive correctness for 16- or 32-bit formats or arbitrary `N,ES`.

### Files

- [`verification/tb/`](verification/tb/) — seven module-level testbenches and the integrated reference-comparison testbench.
- [`verification/test_vectors/`](verification/test_vectors/) — four tested text-vector files, each line containing input A, input B and expected output in hexadecimal.
- [`verification/generate_vectors.py`](verification/generate_vectors.py) — independent Posit decoder/encoder and vector generator, relying only on Python's standard library.

### Reproduce the simulation

1. Create a Vivado RTL project and add the seven `rtl/*_generic.vhd` files as **VHDL 2008** Design Sources.
2. Add `verification/tb/*.vhd` as **VHDL 2008** Simulation Sources.
3. Set `tb_posit_multiplier_reference` as the simulation top.
4. The testbench opens paths such as `verification/test_vectors/posit8_es0_all.txt` **relative to XSim's working directory**. Start XSim from the repository root, copy the `verification/` folder to the simulator working directory, **or adapt the file paths for your local Vivado setup**.
5. Run the simulation to completion using `run all` in XSim's Tcl console; Vivado's default `run 1000ns` does not cover every pair.

To regenerate the vector files (Python 3):

```sh
python verification/generate_vectors.py
```

## Target FPGA and synthesis

Target board: **Digilent Nexys A7-100T**, Artix-7 **`xc7a100tcsg324-1`**. Planned tool: **Vivado 2025.1**.

Hardware utilization, timing and power numbers on this board are **not yet available**. Existing simulations were performed with Vivado 2026.1. A synthesis top is the `posit_multiplier_top_generic` entity; configure `N` and `ES` for each run.

## Scope

Experimental research RTL. The parameter interface permits additional `N,ES` choices, but they must be individually simulated and synthesized. This repository deliberately excludes Vivado build caches, old non-generic modules, and synthesis reports from different target devices.
