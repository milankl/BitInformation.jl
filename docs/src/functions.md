# Index of functions in BitInformation.jl

### Significance of information

```@docs
BitInformation.binom_confidence(::Int,::Real)
BitInformation.binom_free_entropy(::Int,::Real)
```

### Transformations

```@docs
bittranspose(::AbstractArray)
bitbacktranspose(::AbstractArray)
xor_delta(::Array{AbstractFloat,1})
unxor_delta(::Array{AbstractFloat,1})
signed_exponent(::Array{Float32})
signed_exponent!(::Array{Float32})
```