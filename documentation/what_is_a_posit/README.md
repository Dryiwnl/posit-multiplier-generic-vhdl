# What Is a Posit?

# 1. Context

---

- In most applications, floating-point numbers are handled using the IEEE 754 standard: a fixed, universally standardized representation, with 16-, 32-, 64-, and 128-bit formats, NaN handling, and generally stable behavior.
- So why develop a new floating-point representation if the most widely adopted one already handles everything? According to **John L. Gustafson**, the creator of Posit:

> We contrast two esthetics for calculation involving real numbers:
>
> 1. Non-rigorous, but cheap, fast and “good enough” for an established set of applications.
> 2. Rigorous and mathematical, even at the cost of greater execution time and storage.

- The first approach mentioned by Gustafson refers to IEEE 754, where rounding errors are tolerated, there are no representations for $+\infty$ and $-\infty$, and, most importantly, precision is fixed.

---

# 2. The Emergence of Posit

---

- In 2017, **John L. Gustafson** and **Isaac Yonemoto** published *[Beating Floating Point at its Own Game: Posit Arithmetic](http://www.johngustafson.net/pdfs/BeatingFloatingPoint.pdf)*, introducing the concept of Posits for the first time.
- This new representation emerged in response to the limitations of IEEE 754. Suppose an application needs greater precision, or the opposite: the application focuses more on range and does not care as much about precision. With IEEE 754, it is not possible to change a format's balance between precision and range because its representation is fixed. In this context, the authors introduce **tapered precision**.

*Image placeholder — generic Posit format (image.png in the original notes).*

- This is the generic Posit format. At first glance, we can see that only the sign bit has a fixed position. This means all the other fields are variable: increasing the number of regime bits decreases the number of fraction bits, and vice versa.
- Another important point is hardware efficiency. IEEE 754 is quite hardware-friendly, but Posit has the potential to be more efficient because it simplifies the handling of special numbers:

| **Case** | **IEEE 754** | **Posit** |
| --- | --- | --- |
| Zero | +0 and -0 | 0 |
| NaN | $\frac{0}{0}$, $\frac{-0}{+0}$, $\frac{\infty}{\infty}$, $\frac{-\infty}{+\infty}$, $0\times\infty$, $0\times(-\infty)$, $\infty-\infty$, $(-\infty)-(-\infty)$, $\sqrt{-x}$ for $x>0$, $x\bmod 0$, $\infty\bmod x$, $\log(-x)$ for $x>0$ | NaR |
| Infinity | $+\infty$ and $-\infty$ | Not represented |

---

# 3. Posit Structure

---

- The structure of a Posit number is given by:

$$
x=(-1)^s\cdot\mathrm{useed}^k\cdot2^e\cdot(1+f),\qquad
\text{where }\mathrm{useed}=2^{2^{ES}}.
$$

- We denote a binary Posit as **Posit($N_{\text{bits}},ES$)**. So a Posit with 32 total bits and 8 exponent bits would be written as **Posit(32,8)**.

## 3.1. Sign

- The sign has only one bit:
  - 0 = Positive
  - 1 = Negative
- Therefore:

$$
\begin{aligned}
s=0&\Rightarrow(-1)^0=1,\\
s=1&\Rightarrow(-1)^1=-1.
\end{aligned}
$$

- If the number is negative, we take its **two's complement**, which means inverting all the bits and adding 1.
- Positive magnitude $\Rightarrow$ 01001000  
  Invert the bits $\Rightarrow$ 10110111  
  Add 1 $\Rightarrow$ 10111000
- Notice that when a negative number enters the decoder, its sign bit is read by the parser and the entire word goes through two's complement so it can be interpreted as a positive magnitude. At the end of the multiplication, if necessary, we take the complement again to obtain a negative number.

## 3.2. Regime

- The regime is a sequence of zeros or ones, terminated by the opposite bit from the one that started the sequence.

**Examples:**

~~~text
0001
001
000001
1111110
110
11111111110
~~~

- All of these are valid regime values. The difference between them is the value of $k$.
- To determine $k$ from the regime, we examine the first bit of the sequence and follow this rule:

$$
k=
\begin{cases}
m-1,&\text{if the regime begins with }1,\\
-m,&\text{if the regime begins with }0.
\end{cases}
$$

Here, $m$ is the number of consecutive identical bits at the beginning of the regime.

| Regime | m | k |
| --- | ---: | ---: |
| 00001 | 4 | -4 |
| 001 | 2 | -2 |
| 01 | 1 | -1 |
| 10 | 1 | 0 |
| 110 | 2 | 1 |
| 11110 | 4 | 3 |

- $k$ represents how many binary places the point has moved, and the regime is how that information is stored in the Posit.

## 3.3. Useed

- Think about scientific notation:

$$
3500=3.5\times10^3.
$$

- The $10^3$ indicates the multiplication factor: in other words, what we multiply 3.5 by to bring it back to its original scale.
- The **useed** is part of the scale by which I multiply the mantissa. Just as with decimal scientific notation, useed determines the size of the step and $k$ tells us how many steps we take.

$$
\mathrm{useed}=2^{2^{ES}}.
$$

## 3.4. Exponent

- The parameter $ES$ defines the maximum number of exponent bits. Thus, when we define a **Posit(16,2)**, the exponent can contain at most 2 bits ($e=0,1,2,$ or $3$).
- Together with $\mathrm{useed}^k$, the exponent $e$ also defines the scale. Therefore, the Posit's final scale is:

$$
\mathrm{useed}^k\cdot2^e.
$$

- We use both terms to represent the scale because they have different roles:
  - $\mathrm{useed}^k$ $\Rightarrow$ Adjusts the scale in large steps ($2^{2^{ES}}$).
  - $2^e$ $\Rightarrow$ Adjusts the scale in smaller steps, within $\mathrm{useed}^k$.

*Image placeholders — three image.png figures from the original notes.*

- To better visualize how the total scale factor works, we will use the following figure:
- In the first arc, we have the possible representations with $\mathrm{useed}=16$. We can represent values by moving in steps of a factor of 16.
- In the second arc, we add 1 exponent bit, and intermediate values start to appear between those steps.
- In the third arc, we add 2 exponent bits (compared with the first case). With every additional bit, we fill more of the gaps between the useed steps.

## 3.5. Fraction

- The fraction, or mantissa, is the significant part of the value: the number by which the scale is multiplied.
- It always follows the $(1.f)$ form:
  - 11010.110 $\Rightarrow$ Not normalized
  - 1.1010110 $\Rightarrow$ Normalized
- We can use the concept of a mantissa in scientific notation to make a connection with the Posit mantissa:

$$
3500=\underbrace{3.5}_{\text{Mantissa}}\times10^3.
$$

---
