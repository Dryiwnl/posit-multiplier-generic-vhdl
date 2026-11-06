# Generic Posit (N, ES) Multiplier — VHDL

A **parameterized, combinational Posit multiplier** developed in VHDL-2008. The design includes Posit decoding, sign/scale processing, significand multiplication, normalization, packing and **round-to-nearest, ties-to-even (RNE)**.

**Author:** Matheus Viganó Schirrmann  
**Research group:** ProtoFPGA — Universidade Federal de Santa Catarina (UFSC)  
**Planned FPGA:** Digilent Nexys A7-100T, Artix-7 (xc7a100tcsg324-1)  
**Planned synthesis tool:** Vivado 2025.1

The implementation is parameterized by total bit width **N** and exponent size **ES**, including ES = 0. Functional verification is complete for the configurations shown below; results for the target Artix-7 are pending.

## Understanding Posit arithmetic

A finite, nonzero Posit contains four logical fields:

~~~text
| sign | regime (variable length) | exponent (up to ES bits) | fraction |
~~~

The represented number is

$$
x=(-1)^s\,\mathrm{useed}^{k}\,2^e(1+f),
\qquad \mathrm{useed}=2^{2^{ES}}.
$$

Equivalently,

$$
\boxed{x=(-1)^s\,2^{k\,2^{ES}+e}(1+f)}
$$

Here **s** is the sign bit, **k** the regime value, **e** the exponent, and **f** the fractional part of the significand. The implicit leading bit gives the significand **1 + f**.

The regime is formed by a run of identical bits followed, when space permits, by the opposite bit:

$$
k=\begin{cases}
m-1, & \text{run of }m\text{ ones},\\
-m,  & \text{run of }m\text{ zeros}.
\end{cases}
$$

Because the regime length varies, fewer bits may remain for exponent and fraction. This gives Posit its **tapered precision**. For negative encodings, the decoder first obtains the magnitude through two's complement.

There are two reserved encodings: zero (all zero bits) and **NaR** (sign bit one, remaining bits zero). In this multiplier, NaR takes precedence over zero.

### Posit multiplication

For two finite nonzero values:

$$
A=(-1)^{s_A}2^{k_A2^{ES}+e_A}(1+f_A)
$$

$$
B=(-1)^{s_B}2^{k_B2^{ES}+e_B}(1+f_B)
$$

the unrounded product is

$$
\boxed{AB=(-1)^{s_A\oplus s_B}
2^{(k_A+k_B)2^{ES}+e_A+e_B}
(1+f_A)(1+f_B)}
$$

**Sign processing:**

$$s_{\mathrm{prod}}=s_A\oplus s_B$$

**Exponent addition and carry propagation (ES > 0):**

$$
e_{\mathrm{sum}}=e_A+e_B,\qquad
k_{\mathrm{tmp}}=k_A+k_B+
\left\lfloor\frac{e_{\mathrm{sum}}}{2^{ES}}\right\rfloor
$$

$$e_{\mathrm{tmp}}=e_{\mathrm{sum}}\bmod 2^{ES}$$

For ES = 0, no exponent bits are stored and the regime values are added directly.

**Mantissa multiplication:**

$$M=(1+f_A)(1+f_B),\qquad 1\le M<4$$

If the product has **M >= 2**, the normalization stage divides the significand by two and adds one to the combined scale, carrying into the regime if needed.

The packing stage assembles the variable-length regime, exponent and fraction and supplies guard/sticky bits for rounding. For the ordinary RNE case, with **L** the retained least-significant bit, **G** the guard bit and **S** the sticky bit:

$$\mathrm{roundUp}=G\land(S\lor L)$$

Extreme regime boundaries require additional rounding handling in the packing module. The final sign is applied to the rounded magnitude.

## Hardware architecture

The diagram below is the **Posit multiplier architecture image provided for this project**, depicting the component extraction, parallel scale/mantissa paths, normalization, packing and rounding.

![Posit multiplier architecture](docs/images/posit_architecture.png)

The synthesizable code is organized as follows:

| VHDL module | Responsibility |
|---|---|
| [decoder_posit_generic.vhd](rtl/decoder_posit_generic.vhd) | Decode sign, regime, exponent, fraction, zero and NaR |
| [sign_and_exponent_PU_generic.vhd](rtl/sign_and_exponent_PU_generic.vhd) | XOR signs, add exponents and propagate carries |
| [mantissa_multiplier_generic.vhd](rtl/mantissa_multiplier_generic.vhd) | Multiply significands |
| [normalization_generic.vhd](rtl/normalization_generic.vhd) | Normalize the product and adjust its scale |
| [posit_component_packing_generic.vhd](rtl/posit_component_packing_generic.vhd) | Assemble Posit fields and generate guard/sticky |
| [posit_rounding_generic.vhd](rtl/posit_rounding_generic.vhd) | Apply RNE rounding and sign |
| [posit_multiplier_top_generic.vhd](rtl/posit_multiplier_top_generic.vhd) | Integrate the datapath and handle NaR/zero |

**Top-level entity:** posit_multiplier_top_generic. Generics: N (default 8), ES (default 1). Inputs: positA and positB. Output: positResult, each N bits wide. The design has no clock or internal pipeline registers.

## Repository layout

~~~text
rtl/                       7 synthesizable generic VHDL modules
verification/
  tb/                      7 unit testbenches + 1 reference testbench
  test_vectors/            4 exact-reference operand/result vector sets
  generate_vectors.py      independent Python reference generator
docs/images/               image slots (to be uploaded)
README.md
.gitignore
~~~

## Functional verification

The complete multiplier was compared against independently generated Posit results using **exact rational arithmetic**. Simulation was carried out using **Vivado XSim 2026.1**.

| Format | Number of pairs | Verification | Result |
|---|---:|---|---|
| Posit(8,0) | 65,536 | All possible operand pairs | PASS |
| Posit(8,1) | 65,536 | All possible operand pairs | PASS |
| Posit(16,2) | 20,000 | Directed/random sampling | PASS |
| Posit(32,2) | 20,000 | Directed/random sampling | PASS |
| **Total** | **171,072** | | **PASS** |

These results validate the tested configurations, **not arbitrary widths**. In particular, Posit(64,ES) has not yet been validated.

### Vivado simulation waveform — to be added

A waveform screenshot will be inserted here after capture in Vivado.

<!-- Future image: ![Vivado waveform](docs/images/vivado_waveform.png) -->

### Reproducing the tests

1. Add all seven files from rtl/ to a Vivado project as **VHDL 2008 Design Sources**.
2. Add the files from verification/tb/ as **VHDL 2008 Simulation Sources**.
3. Select **tb_posit_multiplier_reference** as simulation top.
4. The testbench loads relative paths under verification/test_vectors/. Ensure the simulator working directory resolves these paths, or adjust the paths for your local setup.
5. Run the XSim Tcl command **run all** instead of stopping at the default 1000 ns.

To regenerate the reference vector sets:

~~~bash
python verification/generate_vectors.py
~~~

## FPGA synthesis and hardware resources

### Posit(8,1) — historical resource results

The following values come from the **earlier Posit(8,1) synthesis table supplied for this project**. They have **not** been measured on the requested Artix-7 device with Vivado 2025.1, so they must not be presented as Nexys A7 benchmark results.

| Resource | Used |
|---|---:|
| **Slice LUTs** | **986** |
| **CARRY4** | **163** |
| **DSP blocks** | **0** |
| **Flip-flops** | **36** |
| **Block RAM** | **0** |
| **Slices** | **281** |

The supplied table does not establish power consumption, critical-path delay or Fmax. Those values are deliberately left unreported here.

### Future synthesis results — Nexys A7-100T

**FPGA:** xc7a100tcsg324-1  
**Tool:** Vivado 2025.1  
**Status:** not yet measured.

| Posit format | Slice LUTs | CARRY4 | DSPs | FFs | BRAM | Slices | Critical path (ns) | Fmax (MHz) | Power (mW) |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| (8,0) | — | — | — | — | — | — | — | — | — |
| (8,1) | — | — | — | — | — | — | — | — | — |
| (16,2) | — | — | — | — | — | — | — | — | — |
| (32,2) | — | — | — | — | — | — | — | — | — |
| (64,2) — not yet verified | — | — | — | — | — | — | — | — | — |

For a timing-constrained implementation, a simple approximation using the measured critical-path delay is

$$F_{\max}\,(\mathrm{MHz})\approx\frac{1000}{T_{\mathrm{critical}}\,(\mathrm{ns})}.$$

**Measurement note:** the current top is purely combinational. A meaningful frequency comparison needs a consistent I/O timing model or registered measurement wrapper. Power estimates also depend on switching activity, constraints and implementation conditions. Record the methodology together with each result.

### Vivado hardware schematic — to be added

The actual **post-synthesis technology schematic** generated in Vivado 2025.1 will be shown here when available.

<!-- Future image: ![Vivado post-synthesis schematic](docs/images/vivado_post_synthesis_schematic.png) -->

## Status and next steps

- **Complete:** seven generic VHDL modules and module-level tests.
- **Complete:** 171,072 reference comparisons in XSim 2026.1.
- **Pending:** synthesis/implementation on Nexys A7-100T in Vivado 2025.1.
- **Pending:** waveform screenshot and synthesized hardware schematic.
- **Pending:** LUT, carry, DSP, FF, timing, and power measurements across further N/ES combinations.

## References and attribution

- J. L. Gustafson and I. T. Yonemoto, *Beating Floating Point at its Own Game: Posit Arithmetic*, Supercomputing Frontiers and Innovations (2017).
- [LeticiaVeran/takum-multiplier-vhdl](https://github.com/LeticiaVeran/takum-multiplier-vhdl) — inspiration for README structure and reporting style; **the arithmetic and RTL here implement Posit, not Takum**.

**Author:** Matheus Viganó Schirrmann — ProtoFPGA / UFSC.
