# Index of functions in BitInformation.jl

### Information

```@docs
BitInformation.bitinformation(::Array)
BitInformation.mutual_information(::Array,::Array)
BitInformation.mutual_information(::Matrix)
BitInformation.redundancy(::Array,::Array)
```

### Bit counting and entropy

```@docs
BitInformation.bitpattern_entropy(::Array)
BitInformation.bitcount(::Array)
BitInformation.bitcount_entropy(::Array)
BitInformation.bitpair_count(::Array,::Array)
```

### Significance of information

```@docs
BitInformation.binom_confidence(::Int,::Real)
BitInformation.binom_free_entropy(::Int,::Real)
```

### Transformations

```@docs
BitInformation.bittranspose(::Array)
BitInformation.bitbacktranspose(::Array)
BitInformation.xor_delta(::Array)
BitInformation.unxor_delta(::Array)
BitInformation.signed_exponent(::Array)
BitInformation.signed_exponent!(::Array)
BitInformation.biased_exponent(::Array)
BitInformation.biased_exponent!(::Array)
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
Base.BitArray(::Array)
```

