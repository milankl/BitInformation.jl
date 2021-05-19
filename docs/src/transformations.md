# Bit transformations

BitInformation.jl implements several bit transformations, meaning reversible, bitwise operations on scalars
or arrays that reorder or transform the bits. This is often used to pre-process the data to make it more suitable
for lossless compression algorithms.

!!! warning "Interpretation of transformed floats"
    BitInformation.jl will not store the information that a transformation was applied to a value. This means
    that Julia will not know about this and interpret a value incorrectly. You will have to explicitly execute
    the backtransform 
    ```julia
    julia> A = [0f0,1f0]         # 0 and 1
    julia> At = bittranspose(A)  # are transposed into 1f-35 and 0
    2-element Vector{Float32}:
    1.0026967f-35
    0.0
    ```

## Bit transpose (aka shuffle)

Bit shuffle operations re-order the bits or bytes in an array, such that bits or each element
in that array are placed next to each other in memory. Despite the name, this operation is
often called "shuffle", although there is nothing random about this, and it is perfectly reversible.
Here, we call it bit transpose, as for an array with $n$ elements of each $n$ bits, this is
equivalent to the matrix tranpose
```julia
julia> A = rand(UInt8,8);
julia> bitstring.(A)
8-element Array{String,1}:
 "10101011"
 "11100000"
 "11010110"
 "10001101"
 "10000010"
 "00011110"
 "11111100"
 "00011011"

julia> At = bittranspose(A);
julia> bitstring.(At)
8-element Array{String,1}:
 "11111010"
 "01100010"
 "11000010"
 "00100111"
 "10010111"
 "00110110"
 "10101101"
 "10010001"
```
In general, we can bittranspose $n$-element arrays with $m$ bits bits per element, which corresponds
to a reshaped transpose. For floats, bittranspose will place all the sign bits next to each
other in memory, then all the first exponent bits and so on. Often this creates a better
compressible array, as bits with similar meaning (and often the same state in correlated data)
are placed next to each other.
```julia
julia> A = rand(Float32,10);
julia> Ar = round(A,7);

julia> bitstring.(bittranspose(Ar))
10-element Array{String,1}:
 "00000000000000000000111111111111"
 "11111111111111111111111111111011"
 "11111101100001011100111010000001"
 "00111000001010001010100111101001"
 "00000101011101110110000101100010"
 "00000000000000000000000000000000"
 "00000000000000000000000000000000"
 "00000000000000000000000000000000"
 "00000000000000000000000000000000"
 "00000000000000000000000000000000"
```
Now all the sign bits are in the first row, and so on. Using `round` means that all the zeros
from rounding are now placed at the end of the array. The `bittranspose` function can be
reversed by `bitbacktranspose`:
```julia
julia> A = rand(Float32,123,234);

julia> A == bitbacktranspose(bittranspose(A))
true
```
Both accept arrays of any shape for `UInt`s as well as floats.

## XOR delta

Instead of storing every element in an array as itself, you may want to store the difference to the
previous value. For bits this "difference" generalises to the reversible xor-operation. The `xor_delta`
function applies this operation to a `UInt` or `Float` array:
```julia
julia> A = rand(UInt16,4)
4-element Array{UInt16,1}:
 0x2569
 0x97d2
 0x7274
 0x4783

julia> xor_delta(A)
4-element Array{UInt16,1}:
 0x2569
 0xb2bb
 0xe5a6
 0x35f7
```
And is reversible with `unxor_delta`.
```
julia> A == unxor_delta(xor_delta(A))
true
```
This method is interesting for correlated data, as many bits will be 0 in the XORed array:
```julia
julia> A = sort(1 .+ rand(Float32,100000));
julia> Ax = xor_delta(A);
julia> bitstring.(Ax)
100000-element Array{String,1}:
 "00111111100000000000000000000101"
 "00000000000000000000000010110011"
 "00000000000000000000000000001000"
 "00000000000000000000000001101110"
 "00000000000000000000000101101001"
 "00000000000000000000000001101100"
 "00000000000000000000001111011000"
 "00000000000000000000000010001101"
 ⋮
```

## Signed exponent

Floating-point numbers have a biased exponent. There are 
[other ways to encode the exponent](https://en.wikipedia.org/wiki/Signed_number_representations#Comparison_table)
and BitInformation.jl implements `signed_exponent` which transforms the exponent bits of a float into a 
representation where also the exponent has a sign bit (which is the first exponent bit)

```julia
julia> a = [0.5f0,1.5f0]               # smaller than 1 (exp sign -1), larger than 1 (exp sign +1)
julia> bitstring.(a,:split)
2-element Vector{String}:
 "0 01111110 00000000000000000000000"  # biased exponent: 2^(e-bias) = 2^-1 here
 "0 01111111 10000000000000000000000"  # biased exponent: 2^(e-bias) = 2^0 here

julia> bitstring.(signed_exponent(a),:split)
2-element Vector{String}:
 "0 10000001 00000000000000000000000"  # signed exponent: sign=1, magnitude=1, i.e. 2^-1
 "0 00000000 10000000000000000000000"  # signed exponent: sign=0, magnitude=0, i.e. 2^0
```

