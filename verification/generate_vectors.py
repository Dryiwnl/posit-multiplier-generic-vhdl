from fractions import Fraction
from functools import lru_cache
from pathlib import Path
import random

ROOT = Path(__file__).resolve().parent / "test_vectors"
ROOT.mkdir(parents=True, exist_ok=True)

@lru_cache(maxsize=100000)
def decode(bits, n, es):
    mask = (1 << n) - 1
    bits &= mask
    if bits == 0: return Fraction(0)
    if bits == (1 << (n - 1)): return None
    negative = bool(bits >> (n-1))
    p = ((-bits) & mask) if negative else bits
    idx = n - 2
    regime = (p >> idx) & 1
    run = 0
    while idx >= 0 and ((p >> idx) & 1) == regime:
        run += 1
        idx -= 1
    k = run - 1 if regime else -run
    idx -= 1  # terminating regime bit, if present
    exp = 0
    for _ in range(es):
        exp <<= 1
        if idx >= 0:
            exp |= (p >> idx) & 1
            idx -= 1
    frac = 0
    count = 0
    while idx >= 0:
        frac = (frac << 1) | ((p >> idx) & 1)
        count += 1
        idx -= 1
    scale = (1 << es) * k + exp
    significand = Fraction((1 << count) + frac, 1 << count)
    value = significand * (Fraction(2**scale) if scale >= 0 else Fraction(1,2**(-scale)))
    return -value if negative else value

def encode(product, n, es):
    if product == 0: return 0
    neg = product < 0
    magnitude = -product if neg else product
    maxcode = (1 << (n-1)) - 1
    low, high = 1, maxcode
    if magnitude <= decode(1,n,es): winner = 1
    elif magnitude >= decode(maxcode,n,es): winner = maxcode
    else:
        while low < high:
            mid = (low + high) // 2
            if decode(mid,n,es) < magnitude: low = mid + 1
            else: high = mid
        upper = low
        lower = upper-1
        da = magnitude - decode(lower,n,es)
        db = decode(upper,n,es) - magnitude
        winner = lower if da < db else upper if db < da else (lower if lower % 2 == 0 else upper)
    return (-winner) & ((1 << n)-1) if neg else winner

def special_pairs(n):
    allbits = (1 << n)-1
    signbit = 1 << (n-1)
    one = 1 << (n-2)
    seeds = [0, 1, 2, 3, 4, 5, 7, 8, 15, 16, 31, 32, 63, 64, 127, 128,
             one-2, one-1, one, one+1, one+2, signbit-2, signbit-1,
             signbit, signbit+1, signbit+2, allbits-2, allbits-1, allbits]
    seeds = sorted({v for v in seeds if 0 <= v <= allbits})
    for a in seeds:
        for b in seeds:
            yield a,b

def output(filename,n,es,total=None,seed=20261106):
    path=ROOT/filename
    digits=(n+3)//4
    rng = random.Random(seed + n*100 + es)
    if total is None:
        pairs = ((a,b) for a in range(1<<n) for b in range(1<<n))
        count=(1<<n)**2
    else:
        pairs0=list(special_pairs(n))
        if len(pairs0)>total: pairs0=pairs0[:total]
        seen=set(pairs0)
        while len(pairs0)<total:
            pair=(rng.getrandbits(n),rng.getrandbits(n))
            if pair not in seen:
                pairs0.append(pair); seen.add(pair)
        pairs=iter(pairs0)
        count=total
    cache={}
    def dec(value):
        if value not in cache:cache[value]=decode(value,n,es)
        return cache[value]
    with path.open('w',encoding='ascii',newline='\n') as f:
        for a,b in pairs:
            va,vb=dec(a),dec(b)
            result=(1<<(n-1)) if va is None or vb is None else encode(va*vb,n,es)
            f.write(f'{a:0{digits}X} {b:0{digits}X} {result:0{digits}X}\n')
    print(f'{filename}: {count} vectors, {path.stat().st_size} bytes',flush=True)

def output64_es2(filename='posit64_es2_samples.txt', total=2000):
    # Deterministic 64-bit edge cases and pseudo-random pairs.
    n, es = 64, 2
    mask = (1 << n) - 1
    one, signbit = 1 << (n-2), 1 << (n-1)
    seeds = sorted({v for v in
        [0, 1, 2, 3, 4, 5, 7, 8, 15, 16, 31, 32, 63, 64, 127, 128,
         one-2, one-1, one, one+1, one+2, signbit-2, signbit-1, signbit,
         signbit+1, signbit+2, mask-2, mask-1, mask]
        if 0 <= v <= mask})
    pairs = [(a,b) for a in seeds for b in seeds]
    seen = set(pairs)
    state = 20261106 + 64*100 + es
    def rand64():
        nonlocal state
        state = (state * 6364136223846793005 + 1442695040888963407) & mask
        return state
    while len(pairs) < total:
        pair = (rand64(), rand64())
        if pair not in seen:
            pairs.append(pair)
            seen.add(pair)
    path = ROOT / filename
    with path.open('w', encoding='ascii', newline='\\n') as f:
        for a,b in pairs[:total]:
            va, vb = decode(a,n,es), decode(b,n,es)
            result = (1 << (n-1)) if va is None or vb is None else encode(va*vb,n,es)
            f.write(f'{a:016X} {b:016X} {result:016X}\\n')
    print(f'{filename}: {min(total,len(pairs))} vectors', flush=True)

if __name__=='__main__':
    output('posit8_es0_all.txt',8,0)
    output('posit8_es1_all.txt',8,1)
    output('posit16_es2_samples.txt',16,2,20000)
    output('posit32_es2_samples.txt',32,2,20000)
    output64_es2()
