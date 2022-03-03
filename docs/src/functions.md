# Index of functions in BitInformation.jl

### Information

```@docs
BitInformation.bitinformation
BitInformation.mutual_information
BitInformation.redundancy
```

### Bit counting and entropy

```@docs
BitInformation.bitpattern_entropy
BitInformation.bitpattern_entropy!
BitInformation.bitcount
BitInformation.bitcount_entropy
BitInformation.bitpair_count
```

### Significance of information

```@docs
BitInformation.binom_confidence
BitInformation.binom_free_entropy
```

### Transformations

```@docs
BitInformation.bittranspose
BitInformation.bitbacktranspose
BitInformation.xor_delta
BitInformation.xor_delta!
BitInformation.unxor_delta
BitInformation.unxor_delta!
BitInformation.signed_exponent
BitInformation.signed_exponent!
BitInformation.biased_exponent
BitInformation.biased_exponent!
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
BitInformation.shave!
BitInformation.halfshave
BitInformation.halfshave!
BitInformation.set_one
BitInformation.set_one!
BitInformation.groom!
BitInformation.nsb
```

### Printing and BitArray conversion

```@docs
Base.bitstring(::Base.IEEEFloat,::Symbol)
Base.BitArray(::Matrix)
```

