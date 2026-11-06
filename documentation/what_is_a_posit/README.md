# What Is a Posit?

An introduction to the Posit numerical representation, its motivation, structure, and components.

## 1. Context

In most applications, floating-point numbers are represented using the **IEEE 754** standard. This standard is widely adopted and specifies established formats such as 16-, 32-, 64-, and 128-bit floating-point representations, as well as the handling of special values such as NaN.

Given that IEEE 754 is so widely used, why develop another floating-point representation?

According to **John L. Gustafson**, one of the creators of Posit arithmetic, there are two contrasting approaches to numerical computation:

> We contrast two esthetics for calculation involving real numbers:
>
> 1. Non-rigorous, but cheap, fast and “good enough” for an established set of applications.
> 2. Rigorous and mathematical, even at the cost of greater execution time and storage.

The first approach discussed by Gustafson can be related to IEEE 754 arithmetic: rounding errors are accepted within numerical computations, and the precision of a particular IEEE 754 format is fixed. These characteristics motivated research into alternative number representations.

## 2. The Emergence of Posit

In **2017**, **John L. Gustafson** and **Isaac T. Yonemoto** published *[Beating Floating Point at its Own Game: Posit Arithmetic](http://www.johngustafson.net/pdfs/BeatingFloatingPoint.pdf)*, introducing the Posit number representation.

The development of this alternative was motivated, in part, by limitations of conventional fixed-format floating-point representations.

Consider an application that prioritizes precision over numerical range, or another application that prioritizes a wider numerical range over precision. Within an individual IEEE 754 format, the number of bits allocated to the exponent and significand is fixed. Posit arithmetic introduces **tapered precision**, where the available precision depends on the magnitude of the represented number.

**Figure placeholder — Generic Posit format.** The original Portuguese notes included an image here; the figure has not yet been provided for this documentation.

In a generic Posit word, only the **sign bit** has a fixed position. The sizes of the other fields vary. As the regime consumes more bits, fewer bits remain available for the fraction, and vice versa.

### Hardware considerations

IEEE 754 is well supported by existing hardware. Posit arithmetic may also offer hardware advantages in certain implementations, partly because its special-value representation is simpler.

| Case | IEEE 754 | Posit |
|---|---|---|
| Zero | Positive zero and negative zero | One zero |
| Invalid or undefined operations | NaN (for example, 0/0, infinity/infinity, infinity − infinity, or the real square root of a negative number) | NaR (*Not a Real*) |
| Infinity | Positive and negative infinity | No separate infinity representation |

This difference does not, by itself, guarantee that Posit arithmetic requires fewer hardware resources: the result depends on the arithmetic operation and the implementation.

## 3. Posit Structure

The numerical value of a finite, nonzero Posit is given by

$$
x=(-1)^s\cdot\mathrm{useed}^{k}\cdot2^e\cdot(1+f),
\qquad
\mathrm{useed}=2^{2^{ES}}.
$$

A binary Posit format is denoted by **Posit(N, ES)**, where **N** is the total number of bits and **ES** is the maximum exponent-field size.

For example, a Posit with 32 total bits and a maximum exponent field of 8 bits is denoted by **Posit(32,8)**.

### 3.1. Sign

The sign field occupies exactly **one bit**:

- **0:** positive number.
- **1:** negative number.

Therefore,

$$
\begin{aligned}
s=0 &\Rightarrow (-1)^0=1,\\
s=1 &\Rightarrow (-1)^1=-1.
\end{aligned}
$$

To decode a negative Posit value, the positive-magnitude representation is obtained by taking the **two's complement** of the entire encoded word: invert all the bits and add one.

For example:

~~~text
Positive magnitude: 01001000
Invert the bits:   10110111
Add 1:             10111000
~~~

When a negative encoded value enters the decoder, the sign bit is identified and the full word is two's-complemented before extracting the magnitude fields. After multiplication and rounding, the resulting magnitude can be two's-complemented again if the output must be negative.

### 3.2. Regime

The **regime** is a sequence of consecutive zeros or ones, terminated by the opposite bit whenever enough bits remain.

Examples of regime patterns:

~~~text
0001
001
000001
1111110
110
11111111110
~~~

All of these are valid regime patterns. What changes between them is the regime value **k**.

To determine **k**, examine the first bit and count the number **m** of consecutive identical bits:

$$
k=
\begin{cases}
m-1, & \text{if the regime begins with }1,\\
-m, & \text{if the regime begins with }0.
\end{cases}
$$

| Regime | m | k |
|---|---:|---:|
| 00001 | 4 | −4 |
| 001 | 2 | −2 |
| 01 | 1 | −1 |
| 10 | 1 | 0 |
| 110 | 2 | 1 |
| 11110 | 4 | 3 |

The regime stores the number of large scale steps applied to the significand. In the complete Posit value, these steps have a size determined by **useed**.

### 3.3. Useed

Consider scientific notation:

$$
3500=3.5\times10^3.
$$

The factor $10^3$ determines how the significand $3.5$ is scaled to obtain the original number.

The **useed** plays a related role in Posit arithmetic: it establishes the size of each large scale step, while the regime value **k** determines how many such steps are applied.

$$
\boxed{\mathrm{useed}=2^{2^{ES}}}
$$

Consequently, the regime contribution to the total scale is

$$
\mathrm{useed}^{k}.
$$

### 3.4. Exponent

The parameter **ES** defines the **maximum number of bits** available for the exponent field.

For example, a **Posit(16,2)** can contain at most two exponent bits, allowing the exponent value **e** to range from **0** to **3** when both bits are available.

Together with the regime contribution $\mathrm{useed}^k$, the exponent provides an additional scale factor:

$$
\boxed{\mathrm{scale}=\mathrm{useed}^{k}\cdot2^e}
$$

These two terms serve different purposes:

- **$\mathrm{useed}^{k}$:** changes the scale in larger steps determined by useed.
- **$2^e$:** introduces smaller adjustments within those large steps.

For **ES = 2**:

$$
\mathrm{useed}=2^{2^2}=16.
$$

The regime therefore changes the scale in powers of 16, while the exponent supplies factors of $1$, $2$, $4$, or $8$ where enough exponent bits are available.

**Figure placeholders — Scale progression.** The original Portuguese notes contained three images and an additional explanatory figure in this subsection. Those images were not supplied with the text, so they have not been reproduced here.

Conceptually, the progression is as follows:

1. With only the useed contribution, the available scales are separated by relatively large multiplicative steps.
2. Adding one exponent bit introduces intermediate scale values.
3. Adding a second exponent bit introduces further intermediate values, filling more gaps between neighboring useed powers.

This describes the role of exponent bits in the scale. The actual number of exponent bits in an encoded Posit may be smaller than **ES** when the regime occupies more space.

### 3.5. Fraction

The **fraction**, also referred to as the fractional part of the significand, contains the significant bits of the encoded number.

The normalized significand has the form

$$
\boxed{1+f}
$$

and can be written in binary as **1.fraction**, with an implicit leading one.

Examples:

~~~text
11010.110  -> Not normalized
1.1010110  -> Normalized
~~~

A similar concept appears in ordinary scientific notation:

$$
3500=\underbrace{3.5}_{\text{significand}}\times10^3.
$$

In a Posit, the significand multiplies the combined scale set by the regime and exponent:

$$
\boxed{x=(-1)^s\underbrace{\mathrm{useed}^{k}2^e}_{\text{scale}}
\underbrace{(1+f)}_{\text{significand}}}.
$$

---

## Reference

John L. Gustafson and Isaac T. Yonemoto, *Beating Floating Point at its Own Game: Posit Arithmetic* (2017). [Read the paper](http://www.johngustafson.net/pdfs/BeatingFloatingPoint.pdf).

*Translated and formatted from the author's original Portuguese study notes. Figures referred to in those notes remain pending. Minor technical clarifications are included to distinguish stored fields, scale, and implementation-dependent hardware characteristics.*
