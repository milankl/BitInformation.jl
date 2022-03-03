# Rounding

 Rounding generally replaces a value $x$ with an approximation $\hat{x}$, which is from a smaller set of
 representable values (e.g. with fewer decimal or binary places of accuracy). Binary rounding removes the
 information in the $n$ last bits by setting them to 0 (or 1). Several rounding modes exist, and
 BitInformation.jl implements them efficiently with bitwise operations, in-place or by creating a
 copy of the original array. 

!!! tip "Bitstring split into sign, exponent and mantissa bits"
    BitInformation.jl extends `Base.bitstring` with a split option to better visualise sign, exponent
    and mantissa bits for floats.
    ```julia
    julia> bitstring(1.1f0)
    "00111111100011001100110011001101"
    
    julia> bitstring(1.1f0,:split)
    "0 01111111 00011001100110011001101"
    ```


## Round to nearest

With binary round to nearest a full-precision number is replaced by the nearest representable float
with fewer mantissa bits by rounding the trailing bits to zero. BitInformation.jl implements this by
extending Julia's `round` to `round(::Array{T},n::Integer)` where `T` either `Float32` or `Float64`
and `n` the number of significant bits retained after rounding. Negative `n` are possible too, which
will round even the exponent bits.

Rounding
```julia
julia> # bitwise representation (split in sign, exp, sig bits) of some random numbers
julia> bitstring.(A,:split)             
5-element Array{String,1}:
 "0 01111101 01001000111110101001000"
 "0 01111110 01010000000101001110110"
 "0 01111110 01011101110110001000110"
 "0 01111101 00010101010111011100000"
 "0 01111001 11110000000000000000101"
```
to `n=3` significant bits via `round(A,3)` yields
```julia
julia> bitstring.(round(A,3),:split)
5-element Array{String,1}:
 "0 01111101 01000000000000000000000"
 "0 01111110 01100000000000000000000"  # round up, flipping the third significant bit
 "0 01111110 01100000000000000000000"  # same here
 "0 01111101 00100000000000000000000"  # and here
 "0 01111010 00000000000000000000000"  # note how the carry bits correctly carries into the exponent
```
This rounding function is IEEE compatible as it also implements tie-to-even, meaning that `01` which is
exactly halway between `0` and `1` is round to `0` which is the *even* number (a bit sequence ending in
a `0` is even). Similarly, `11` is round up to `100` and not down to `10`. Rounding to 1 signficant bit
means that only `1,1.5,2,3,4,6...` are representable.

```julia
julia> A = Float32[1.25,1.5,1.75]
julia> bitstring.(A,:split)
3-element Vector{String}:
 "0 01111111 01000000000000000000000"  
 "0 01111111 10000000000000000000000"
 "0 01111111 11000000000000000000000"

julia> bitstring.(round(A,1),:split)
3-element Vector{String}:
 "0 01111111 00000000000000000000000"  # 1.25 is tie between 1.0 and 1.5, round down to even
 "0 01111111 10000000000000000000000"  # 1.5 is representable, no rounding
 "0 10000000 00000000000000000000000"  # 1.75 is tie between 1.5 and 2.0, round up to even
```

## Bit shave

In contrast to round to nearest, `shave` will always round to zero by *shaving* the trailing
significant bits off (i.e. set them to zero). This rounding mode therefore introduces
a bias towards 0 and the rounding error can be twice as large as for round to nearest.

```julia
julia> bitstring.(shave(A,3),:split)
5-element Array{String,1}:
 "0 01111101 01000000000000000000000"  # identical to round here
 "0 01111110 01000000000000000000000"  # round down here, whereas `round` would round up
 "0 01111110 01000000000000000000000"
 "0 01111101 00000000000000000000000"
 "0 01111001 11100000000000000000000"  # no carry bit for `shave`
```

## Bit set

Similar to `shave`, `set_one` will always set the trailing significant bits to `1`. This rounding
mode therefore introduces a bias away from 0 and the rounding error can be twice as large as for
round to nearest.

```julia
julia> bitstring.(set_one(A,3),:split)
5-element Array{String,1}:
 "0 01111101 01011111111111111111111"  # all trailing bits are always 1
 "0 01111110 01011111111111111111111"
 "0 01111110 01011111111111111111111"
 "0 01111101 00011111111111111111111"
 "0 01111001 11111111111111111111111"
```

## Bit groom

Combining `shave` and `set_one`, by alternating both removes the bias from both. This method is called
*grooming* and is implemented via the `groom` function

```julia
julia> bitstring.(groom(A,3),:split)
5-element Array{String,1}:
 "0 01111101 01000000000000000000000"   # shave
 "0 01111110 01011111111111111111111"   # set to one
 "0 01111110 01000000000000000000000"   # shave
 "0 01111101 00011111111111111111111"   # etc.
 "0 01111001 11100000000000000000000"
```

## Bit halfshave

Another way to remove the bias from `shave` is to replace the trailing significant bits with `100...` which
is equivalent to round to nearest, but uses representable values that are always halfway between.
This also removes the bias of `shave` or `set_one` and yields on average a rounding error that is as
large as from round to nearest

```julia
julia> bitstring.(halfshave(A,3),:split)
5-element Array{String,1}:
 "0 01111101 01010000000000000000000"   # set all discarded bits to 1000...
 "0 01111110 01010000000000000000000"
 "0 01111110 01010000000000000000000"
 "0 01111101 00010000000000000000000"
 "0 01111001 11110000000000000000000"
```

