# Index of functions in BitInformation.jl

### Information

```@docs
BitInformation.bitinformation(::AbstractArray)
BitInformation.mutual_information(::AbstractArray,::AbstractArray)
BitInformation.mutual_information(::Matrix)
BitInformation.redundancy(::AbstractArray,::AbstractArray)
```

### Bit counting and entropy

```@docs
BitInformation.bitpattern_entropy(::AbstractArray)
BitInformation.bitcount(::AbstractArray)
BitInformation.bitcount_entropy(::AbstractArray)
BitInformation.bitpair_count(::AbstractArray,::AbstractArray)
```

### Significance of information

```@docs
BitInformation.binom_confidence(::Int,::Real)
BitInformation.binom_free_entropy(::Int,::Real)
```

### Transformations

```@docs
BitInformation.bittranspose(::AbstractArray)
BitInformation.bitbacktranspose(::AbstractArray)
BitInformation.xor_delta(::AbstractArray)
BitInformation.unxor_delta(::AbstractArray)
BitInformation.signed_exponent(::AbstractArray)
BitInformation.signed_exponent!(::AbstractArray)
BitInformation.biased_exponent(::AbstractArray)
BitInformation.biased_exponent!(::AbstractArray)
```

### Rounding

```@docs
Base.round(::Base.IEEEFloat,::Integer)
BitInformation.round!
BitInformation.get_shift
BitInformation.get_ulp_half
BitInformation.get_keep_mask
BitInformation.get_bit_mask
Base.iseven(::Base.IEEEFloat,::Integer)
Base.isodd(::Base.IEEEFloat,::Integer)
```

### Shaving, halfshaving, setting and bit grooming

```@docs
BitInformation.shave
BitInformation.halfshave
BitInformation.set_one
BitInformation.groom!
BitInformation.nsb
```

### Printing and BitArray conversion

```@docs
Base.bitstring(::Base.IEEEFloat,::Symbol)
Base.BitArray(::AbstractArray)
```

