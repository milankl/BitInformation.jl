# Bitwise information content analysis

## Bitpattern entropy

An $n$-bit number format has  bitpatterns available to encode a real number. 
For most data arrays, not all bitpatterns are used at uniform probability. 
The bitpattern entropy is the [Shannon information entropy](https://en.wikipedia.org/wiki/Entropy_(information_theory)) $H$, in units of bits,
calculated from the probability $p_i$ of each bitpattern 

```math
H = -\sum_{i=1}^{2^n}p_i \log_2(p_i)
```

The bitpattern entropy is $H \leq n$ and maximised to $n$ bits for a uniform distribution. The free entropy is the difference $n-H$.

In BitInformation.jl, the bitpattern entropy is calculated via `bitpattern_entropy(::Array)`
```julia
julia> A = rand(Float32,100000000);

julia> bitpattern_entropy(A)
22.938590744784577
```
Here, the entropy is about 23 bit, meaning that `9` bits are effectively unused. This is because `rand` samples in `[1,2)`, so that the sign and exponent bits are always `0 01111111` followed by some random significant bits.

The function `bitpattern_entropy` is based on sorting the array `A`. While this avoids the allocation of a bitpattern histogram (which would make the function unsuitable for anything larger than 32 bits) it has to allocate a sorted version of `A`.

## Information content

To calculate the information content of an n-dimensional array (any typ `T` is
supported that can be reinterpreted as `8,16,24,32,40,48,56` or `64-bit`
unsigned integer) the following functions are provided:

**bitcount**. The function `bitcount(A::Array)` counts all occurences of the
1-bit in every bit-position in every element of `A`. E.g.

```julia
julia> bitstring.(A)
5-element Array{String,1}:
 "10001111"
 "00010111"
 "11101000"
 "10100100"
 "11101011"

julia> bitcount(A)
8-element Array{Int64,1}:
 4
 2
 3
 1
 3
 3
 3
 3
 ```
The first bit of elements (here: `UInt8`) in `A` are 4 times `1` and 1 times
`0`, etc. In contrast, elements drawn from a uniform distribution U(0,1)
 ```julia
julia> A = rand(Float32,100000);

julia> bitcount(A)
32-element Array{Int64,1}:
      0
      0
 100000
 100000
      ⋮
  37411
  25182
      0
```
have never a sign bit that is `0`, but the 2nd and third exponent bit is always `1`.

**bitcountentropy**. The `bitcountentropy(A::Array)` calculates the entropy of
bit occurences in `A`. For random bits occuring at probabilities p(0) = 0.5, p(1) = 0.5
the entropy for every bit is maximised to 1 bit:
```julia
julia> A = rand(UInt8,100000);

julia> Elefridge.bitcountentropy(A)
8-element Array{Float64,1}:
 0.9999998727542938
 0.9999952725717266
 0.9999949724904816
 0.9999973408228667
 0.9999937649515901
 0.999992796900212
 0.9999970566115759
 0.9999998958374157
 ```
The converges to 1 for larger arrays.

**bitpaircount**. The `bitpaircount(A::Array)` function returns a `4xn` (with `n`
being the number of bits in every element of `A`) array, the counts the occurrences
of `00`,`01`,`10`,`11` for all bit-positions in `a in A` across all elements `a` in `A`.
For a length `N` of array `A` (one or multi-dimensional) the maximum occurrence
is `N-1`. E.g.
```julia
julia> A = rand(UInt8,5);
julia> bitstring.(A)
5-element Array{String,1}:
 "01000010"
 "11110110"
 "01010110"
 "01111111"
 "00010100"

julia> bitpaircount(A)
4×8 Array{Int64,2}:
 2  0  0  0  2  0  0  2    # occurences of `00` in the n-bits of UInt8
 1  0  2  1  1  1  0  1    # occurences of `01`
 1  1  2  0  1  0  1  1    # occurences of `10`
 0  3  0  3  0  3  3  0    # occurences of `11`
 ```
The first bit of elements in `A` is as a sequence `01000`. Consequently,
`00` occurs 2x, `01` and `10` once each, and `11` does not occur.
Multi-dimensional arrays are unravelled into a vector, following Julia's
memory layout (column-major).

**bitcondprobability**. Based on `bitpaircount` we can calculate the conditional
entropy of the state of one bit given the state of the previous bit (previous
meaning in the same bit position but in the previous element in the array `A`).
In the previous example we obtain
```julia
julia> Elefridge.bitcondprobability(A)
4×8 Array{Float64,2}:
 0.666667  NaN     0.0  0.0  0.666667  0.0  NaN     0.666667
 0.333333  NaN     1.0  1.0  0.333333  1.0  NaN     0.333333
 1.0         0.25  1.0  0.0  1.0       0.0    0.25  1.0
 0.0         0.75  0.0  1.0  0.0       1.0    0.75  0.0
```
Given the previous bit being `0` there is a 2/3 chance that th next bit is a `0`
too, and a 1/3 change that the next bit is a `1`, i.e. p(next=0|previous=0) = 2/3,
p(1|0), such that p(0|0)+p(1|0)=1 always, if not NaN, and similarly for p(0|1)
and p(1|1).

**bitinformation**. Base on the previous functions, the bitwise information
content defined as
```
Ic = H - q0*H0 - q1*H1
```
for any sequence of bits. `H` is the uncoditional entropy (calculated similarly
to `bitcountentropy` on `A[1:end-1]`), `q0/q1` is the probability of the `0/1`
bit in the sequence and `H0/H1` are the conditional entropies.
`H0 = entropy(p(0|0),p(1|0))` and `H1 = entropy(p(0|1),p(1|1))`.
The bitwise inforamtion content can be calculated with `bitinformation(A::Array)`, e.g.
```julia
julia> A = rand(UInt8,1000000);

julia> bitinformation(A)
8-element Array{Float64,1}:
 2.2513712005789444e-9
 4.3346579969849586e-7
 1.2269593584468552e-6
 1.71376803870249e-6
 1.035394191328809e-6
 2.0511669801548393e-6
 3.1941966260884413e-7
 1.1631417273783029e-7
```
The information of random uniform bits is 0 as the knowledge of a given bit does
not provide any information for the succeeding bits. However, correlated arrays
(which we achieve here by sorting)
```julia
julia> A = rand(Float32,1000000);

julia> sort!(A);

julia> bitinformation(A)
32-element Array{Float64,1}:
 0.0
 0.0
 0.0
 0.0
 0.0005324203865138733
 0.0654345833904318
 0.5219048602771518
 0.9708027628747311
 0.9180796560925731
 0.9993719214848099
 0.9989466303997855
 0.9980955861347737
 0.996610924254921
 0.9941803365302689
 0.989869550776399
 0.9828792401091413
 0.9710813685504847
 0.9515753574258816
 0.9209285439473764
 0.8726093489385611
 0.8010696825274235
 0.6983323983355056
 0.5597023618984831
 0.3923518757327869
 0.21652879399986952
 0.08053181875714122
 0.019144066375869684
 0.00712349142391111
 0.010814913217907396
 0.02885101299472209
 0.0728553098975398
 0.0
 ```
have only zero information in the sign (unused for random uniform distribution
U(0,1)), and in the first exponent bits (also unused due to limited range) and
in the last significant bit (flips randomly). The information is maximised to
1bit for the last exponent and the first significant bits, as knowing the state
of such a bit one can expect the next (or previous) bit to be the same due to
the correlation.