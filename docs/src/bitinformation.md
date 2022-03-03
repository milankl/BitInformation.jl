# Bitwise information content analysis

## Bit pattern entropy

An $n$-bit number format has $2^n$ bit patterns available to encode a real number. 
For most data arrays, not all bit pattern occur at equal probability. 
The bit pattern entropy is the 
[Shannon information entropy](https://en.wikipedia.org/wiki/Entropy_(information_theory))
$H$, in units of bits, calculated from the probability $p_i$ of each bit pattern 

```math
H = -\sum_{i=1}^{2^n}p_i \log_2(p_i)
```

The bitpattern entropy is $H \leq n$ and maximised to $n$ bits for a uniform distribution,
i.e. all bit pattern occur equally frequent. The free entropy $H_f$ is the difference $n-H$.

In BitInformation.jl, the bitpattern entropy is calculated via `bitpattern_entropy(::AbstractArray)`
```julia
julia> A = rand(Float32,100000000) .+ 1;

julia> bitpattern_entropy(A)
22.938590744784577
```
Here, the entropy is about 23 bit, meaning that `9` bits are effectively unused.
This is because all elements of A are in `[1,2)`, so that the sign and exponent bits are
always `0 01111111` followed by 23 random significant bits, each contributing about 1 bit.

!!! note "Implementation details"
    The function `bitpattern_entropy` is based on sorting the array `A`. While this
    avoids the allocation of a bitpattern histogram (which would make the function
    unsuitable for anything larger than 32 bits) it has to allocate a sorted version of `A`.
    If you don't mind the sorting in-place use `bitpattern_entropy!(::AbstractArray)`.

## Bit count entropy

The Shannon information entropy $H$, in unit of bits, takes for a bitstream $b=b_1b_2...b_k...b_l$,
i.e. a sequence of bits of length $l$, the form

```math
H(b) = -p_0 \log_2(p_0) - p_1\log_2(p_1)
```

with $p_0,p_1$ being the probability of a bit $b_k$ in $b$ being 0 or 1. The entropy is maximised to
1 bit for equal probabilities $p_0 = p_1 = \tfrac{1}{2}$ in $b$. The function `bitcount(A::Array)`
counts all occurences of the 1-bit in every bit-position in every element of `A`. E.g.

```julia
julia> bitstring.(A)        # 5-element Vector{UInt8}
5-element Array{String,1}:
 "10001111"
 "00010111"
 "11101000"
 "10100100"
 "11101011"

julia> bitcount(A)
8-element Array{Int64,1}:
 4                          # number of 1-bits in the first bit of UInt8
 2                          # in the second bit position
 3                          # etc.
 1
 3
 3
 3
 3
```

The first bit of elements (here: `UInt8`) in `A` is 4x `1` and hence 1x `0`.
In contrast, elements drawn from a uniform distribution U(0,1)

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
have never a sign bit that is `1`, but the 2nd and third exponent bit is always `1`.
The last significant bits in `rand` do not occur at 50% chance, which is due to the
pseudo-random number generator (see a discussion
[here](https://sunoru.github.io/RandomNumbers.jl/dev/man/basics/#Conversion-to-Float)).

Once the bits in an array are counted, the respective probabilities $p_0,p_1$ can be calculated
and the entropy derived. The function `bitcount_entropy(A::Array)` does that
```julia
julia> A = rand(UInt8,100000);          # entirely random bits
julia> bitcount_entropy(A)
8-element Array{Float64,1}:             # entropy is for every bit position ≈ 1
 0.9999998727542938
 0.9999952725717266
 0.9999949724904816
 0.9999973408228667
 0.9999937649515901
 0.999992796900212
 0.9999970566115759
 0.9999998958374157
```
This converges to 1 for larger arrays.

## Bit pair count

The `bitpair_count(A::AbstractArray,B::AbstractArray)` function returns a `nx2x2` array,
with `n` being the number of bits elements of `A,B`. The array contains counts the
occurrences of bit pairs between A,B, i.e. `00`,`01`,`10`,`11` for all bit positions.
E.g.

```julia
julia> A = rand(UInt8,5)
julia> B = rand(UInt8,5)
julia> bitstring.(A)
5-element Array{String,1}:
 "01000010"
 "11110110"
 "01010110"
 "01111111"
 "00010100"

julia> C = bitpair_count(A,B)
julia> C[1,:,:]         # bitpairs of A,B in 1st bit position
2×2 Matrix{Int64}:
 2  1
 1  1
```

Here, among the 5 element pairs in `A,B` there are 2 which both have a `0` in the first bit
position. One element pair is `01`, one `10` and one `11`.

## Mutual information

The mutual information of two bitstreams (which can be, for example, two arrays, or adjacent 
elements in one array) $r = r_1r_2...r_k...r_l$ and $s = s_1s_2...s_k...s_l$ is defined via
the joint probability mass function $p_{rs}$ which here takes the form of a 2x2 matrix

```math
p_{rs} = \begin{pmatrix}p_{00} & p_{01} \\ p_{10} & p_{11} \end{pmatrix}
```

with $p_{ij}$ being the probability that the bits are in the state $r_k=i$ and $s_k = j$
simultaneously and $p_{00}+p_{01}+p_{10}+p_{11} = 1$. The marginal probabilities follow as
column or row-wise additions in $p_{rs}$, e.g. the probability that $r_k = 0$ is
$p_{r=0} = p_{00} + p_{01}$. The mutual information $M(r,s)$ of the two bitstreams
$r,s$ is then

```math
M(r,s) = \sum_{r=0}^1 \sum_{s=0}^1 p_{rs} \log_2 \left( \frac{p_{rs}}{p_{r=r}p_{s=s}}\right)
```

The function `mutual_information(::AbstractArray,::AbstractArray)` calculates $M$ as

```julia
julia> r = rand(Float32,100_000)    # [0,1) random float32s
julia> s = shave(r,15)              # remove information in sbit 16-23 by setting to 0
julia> mutual_information(r,s)
32-element Vector{Float64}:
 0.0
 ⋮
 0.9999935941359982                 # sbit 12: 1 bit of mutual information
 0.9999912641753561                 # sbit 13: same
 0.9999995383375376                 # sbit 14: same
 0.9999954191498579                 # sbit 15: same
 0.0                                # sbit 16: always 0 in s, but random in r: M=0 bits
 0.0                                # sbit 17: same
 0.0
 0.0
 0.0
 0.0
 0.0
 0.0                                # sbit 23
```
The mutual information approaches 1 bit for unchaged bits between `r,s`, but bits that have
been shaved off do not contain any information, hence the mutual information also drops
as there is no entropy to start with.

## Real bitwise information

The mutual information of bits from adjacent bits is the `bitwise real information content` and
derived as follows. For the two bitstreams $r,s$ being the preceding and succeeding bits
(for example in space or time) in a single bitstream $b$, i.e. $r=b_1b_2...b_{l-1}$ and
$s=b_2b_3...b_l$ the unconditional entropy is then effectively $H = H(r) = H(s)$ for
$l$ being very large. We then can write the mutual information $M(r,s)$ between adjacent
bits also as 

```math
I = H - q_0H_0 - q_1H_1
```

which is the real information content $I$. This definition is similar to Jeffress et al. (2017) [^1],
but avoids an additional assumption of an uncertainty measure. This defines the real information
as the entropy minus the false information. For bitstreams with either $p_0 = 1$ or $p_1 = 1$,
i.e. all bits are either 0 or 1, the entropies are zero $H = H_0 = H_1 = 0$ and we may refer to
the bits in the bitstream as being unused. In the case where $H > p_0H_0 + p_1H_1$, the preceding bit
is a predictor for the succeeding bit which means that the bitstream contains real information ($I > 0$).

The computation of $I$ is implemented in `bitinformation(::AbstractArray)` 

```julia
julia> A = rand(UInt8,1000000)  # fully random bits
julia> bitinformation(A)
8-element Array{Float64,1}:
 0.0                            # real information = 0
 0.0
 0.0
 0.0
 0.0
 0.0
 0.0
 0.0
```
The information of random uniform bits is 0 as the knowledge of a given bit does
not provide any information for the succeeding bits. However, correlated arrays
(which we achieve here by sorting)
```julia
julia> A = rand(Float32,1000000)
julia> sort!(A)
julia> bitinformation(A)
32-element Vector{Float64}:
 0.0
 0.0
 0.0
 0.0
 0.00046647589813905157
 0.06406479945998214
 0.5158447841492068
 0.9704486460488391
 0.9150881582169795
 0.996120575536068
 0.9931335810218149
 ⋮
 0.15992667263039423
 0.0460430997651915
 0.006067325343418917
 0.0008767479258913191
 0.00033132201520535975
 0.0007048623462190817
 0.0025481588434255187
 0.0087191715755926
 0.028826838913308506
 0.07469492765760763
 0.0
```
have only zero information in the sign (unused for random uniform distribution
U(0,1)), and in the first exponent bits (also unused due to limited range) and
in the last significant bit (flips randomly). The information is maximised to
1 bit for the last exponent and the first significant bits, as knowing the state
of such a bit one can expect the next (or previous) bit to be the same due to
the correlation.

## Multi-dimensional real information

The real information content $I_m$  for an $m$-dimensional array $A$ is the sum of the
real information along the  dimensions. Let $b_j$ be a bitstream obtained by unravelling
a given bitposition in along its $j$-th dimension. Although the unconditional entropy $H$
is unchanged along the $m$-dimensions, the conditional entropies $H_0,H_1$ change as the
preceding and succeeding bit is found in another dimension, e.g. $b_2$ is obtained by
re-ordering $b_1$. Normalization by $\tfrac{1}{m}$ is applied to $I_m$ such that the
maximum information is 1 bit in $I_m^*$

```math
I_m^* = H - \frac{p_0}{m}\sum_{j=1}^mH_0(b_j) - \frac{p_1}{m}\sum_{j=1}^mH_1(b_j)
```

This is implemented in BitInformation.jl as `bitinformation(::AbstractArray,dim::int)`, e.g.

```julia
julia> A = rand(Float32,100,200,300)    # a 3D array
julia> sort!(A,dims=2)                  # sort to create some auto-corelation
julia> bitinformation(A,dim=2)          # information along 2nd dimension
32-element Vector{Float64}:
 0.9284529526801016
 0.12117292341467487
 0.12117292341467487
 0.12117292341467487
 0.12097216822084497
 0.11085252207817117
 0.31618374026691876
 0.5342647349810241
 0.44490628938885407
 0.2420859244356707
 0.08943278228929732
 0.01870979798293037
 0.00221913365831955
 0.0
 0.0
 ⋮
 0.0
 0.0
```
The keyword `dim` will permute the dimensions in `A` to calcualte the information
in the specified dimensions. By default `dim=1`, which uses the ordering of the bits
as they are layed out in memory.

## Redundancy

Redundancy $R$ is defined as the symmetric normalised mutual information $M(r,s)$

```math
R(r,s) = \frac{2M(r,s)}{H(r) + H(s)}
```
`R` is the redundancy of information of $r$ in $s$ (and vice versa). $R = 1$ for identical
bitstreams $r = s$, but $R = 0$ for statistically independent bitstreams.

BitInformation.jl implements the redundancy calculation via `redundancy(::AbstractArray,::AbstractArray)`
where the inputs have to be of same size and element type. For example, shaving off some of
the last significant bits will set the redundancy for those to 0, but redundancy is 1 for all
bitstreams which are identical

```julia
julia> r = rand(Float32,100_000)    # random data
julia> s = shave(r,7)               # keep only sign, exp and sbits 1-7
julia> redundancy(r,s)
32-element Vector{Float64}:
 1.0                                # redundancy 1 as bitstreams are identical
 1.0
 1.0
 1.0
 0.9999999999993566                 # rounding errors can yield ≈1    
 0.9999999999999962
 1.0
 1.0000000000000002
  ⋮
 0.0                                # redundancy 0 as information lost in shave
 0.0
 0.0
 0.0
 0.0
 0.0
 0.0
 0.0
```

## Preserved information

The preserved information $P(r,s)$ between two bitstreams $r,s$ where $s$ approximates $r$
is the information-weighted redundancy $I$

```math
P(r,s) = R(r,s)I(r)
```

The information loss $L$ is $1-P$ and represents the unpreserved information of $r$ in $s$.
In most cases we are interested in the preserved information of an array $X = (x_1,x_2,...,x_q,...,x_n)$
of bitstreams  when approximated by a previously compressed array $Y = (y_1,y_2,...,y_q,...,y_n)$.
For an array $A$ of floats with $n=32$ bit, for example, $x_1 is the bitstream of all sign bits
unravelled along a given dimension (e.g. longitudes) and $x_{32}$ is the bitstream of the last mantissa bits.
The redundancy $R(X,Y)$ and the real information $I(X)$ is then calculated for each bit position $q$
individually, and the preserved information $P$ is the redundancy-weighted mean of the real information
in $X$

```math
P(X,Y) = \frac{\sum_{q=1}^n R(x_q,y_q)I(x_q)}{\sum_{q=1}^n I(x_q)}
```

The quantity $\sum_{q=1}^n I(x_q)$ is the total information in $X$ and therefore also in $A$. 
The redundancy is $R=1$ for bits that are unchanged during rounding and $R=0$ for bits that are
round to zero. Example

```julia
julia> r = rand(Float32,100_000)    # random bits
julia> sort!(r)                     # sort to introduce auto-correlation & statistical dependence of bits
julia> s = shave(r,7)               # s is an approximation to r, shaving off sbits 8-23
julia> R = redundancy(r,s)          
julia> I = bitinformation(r)
julia> P = (R'*I)/sum(I)            # preserved information of r in s
0.9087255894613658                  # = 91%
```

## Significance of information

For an entirely independent and approximately equal occurrence of bits in a bitstream of length $l$,
the probabilities $p_0,p_1$ of a bit being 0 or 1 approach $p_0\approxp_1\approx\tfrac{1}{2}$, but
they are in practice not equal for $l < \infty$. Consequently, the entropy is smaller than 1,
but only insignificantly. The probability $p_1$ of successes in the binomial distribution
(with parameter $p=\tfrac{1}{2}$) with $l$ trials (using the normal approximation for large $l$) is

```math
p_1 = \frac{1}{2} + \frac{z}{2\sqrt{l}}
```

where $z$ is the $1-\tfrac{1}{2}(1-c)$ quantile at confidence level $c$ of the standard normal distribution.
For $c=0.99$, corresponding to a 99%-confidence level which is used as default here, $z=2.58$ and for $l=10^7$
a probability $\tfrac{1}{2} \leq p \leq p_1 = 0.5004$ is considered insignificantly different from equal
occurrence $p_0 = p_1$. This is implemented as `binom_confidence(l,c)`

```julia
julia> BitInformation.binom_confidence(10_000_000,0.99)
0.500407274373151
```

The associated free entropy $H_f$ in units of bits follows as

```math
H_f = 1 - p_1\log_2(p_1) - (1-p_1)\log_2(1-p_1)
```

And we consider real information below $H_f$ as insignificantly different from 0 and
set the real information $I = 0$. The calculation of $H_f$ is implemented as
`binom_free_entropy(l,c,base=2)`

```julia
julia> BitInformation.binom_free_entropy(10_000_000,0.99)
4.786066739592698e-7
```

## References

[^1]: Jeffress, S., Düben, P. & Palmer, T. _Bitwise efficiency in chaotic models_. *Proc. R. Soc. Math. Phys. Eng. Sci.* 473, 20170144 (2017).

