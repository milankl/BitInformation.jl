const IEEEFloat_and_complex = Union{Float16,Float32,Float64,ComplexF16,ComplexF32,ComplexF64}

"""Shift integer to push the mantissa in the right position. Used to determine
round up or down in the tie case. `keepbits` is the number of mantissa bits to
be kept (i.e. not zero-ed) after rounding. Special case: shift is -1 for
keepbits == significand_bits(T) to avoid a round away from 0 where no rounding
should be applied."""
function get_shift(::Type{T},keepbits::Integer) where {T<:Base.IEEEFloat}
    shift = Base.significand_bits(T) - keepbits     # normal case
    shift -= keepbits == Base.significand_bits(T)   # to avoid round away from 0
    return shift
end

"""Returns for a Float-type `T` and `keepbits`, the number of mantissa bits to be
kept/non-zeroed after rounding, half of the unit in the last place as unsigned integer.
Used in round (nearest) to add ulp/2 just before round down to achieve round nearest.
Technically ulp/2 here is just smaller than ulp/2 which rounds down the ties. For 
a tie round up +1 is added in `round(T,keepbits)`."""
function get_ulp_half(  ::Type{T},
                        keepbits::Integer
                        ) where {T<:Base.IEEEFloat}
    # convert to signed for arithmetic bitshift
    # trick to push in 0s from the left and 1s from the right
    return ~unsigned(signed(~Base.significand_mask(T)) >> (keepbits+1))
end

"""Returns a mask that's 1 for all bits that are kept after rounding and 0 for the
discarded trailing bits. E.g.
```
julia> get_keep_mask(Float16,5)
0xffe0
```."""
function get_keep_mask( ::Type{T},
                        keepbits::Integer
                        ) where {T<:Base.IEEEFloat}
    # convert to signed for arithmetic bitshift
    # trick to push in 1s from the left and 0s from the right
    return unsigned(signed(~Base.significand_mask(T)) >> keepbits)
end

"""Returns a mask that's `1` for a given `mantissabit` and `0` else. Mantissa bits 
are positive for the mantissa (`mantissabit = 1` is the first mantissa bit), `mantissa = 0`
is the last exponent bit, and negative for the other exponent bits."""
function get_bit_mask(  ::Type{T},
                        mantissabit::Integer
                        ) where {T<:Base.IEEEFloat}
    # push the sign mask (1000....) in the right position
    return Base.sign_mask(T) >> (Base.exponent_bits(T) + mantissabit)
end

"""IEEE's round to nearest tie to even for Float16/32/64."""
function Base.round(x::T,               # Float to be rounded
                    ulp_half::UIntT,    # obtain from get_ulp_half,
                    shift::Integer,     # get_shift, and
                    keepmask::UIntT     # get_keep_mask
                    ) where {T<:Base.IEEEFloat,UIntT<:Unsigned}
    ui = reinterpret(UIntT,x)                       # bitpattern as uint
    ui += ulp_half + ((ui >> shift) & one(UIntT))   # add ulp/2 with tie to even
    return reinterpret(T,ui & keepmask)             # set trailing bits to zero
end

function Base.round(x::Complex,         # Complex float to be rounded
                    ulp_half::UIntT,    # obtain from get_ulp_half,
                    shift::Integer,     # get_shift, and
                    keepmask::UIntT     # get_keep_mask
                    ) where {UIntT<:Unsigned}
    a = round(real(x),ulp_half,shift,keepmask)
    b = round(imag(x),ulp_half,shift,keepmask)
    return a+im*b
end

"""Scalar version of `round(::Float,keepbits)` that first obtains
`shift, ulp_half, keep_mask` and then rounds."""
function Base.round(x::T,
                    keepbits::Integer
                    ) where {T<:Base.IEEEFloat}
    return round(x,get_ulp_half(T,keepbits),get_shift(T,keepbits),get_keep_mask(T,keepbits))
end

function Base.round(x::Complex{T},keepbits::Integer) where T
    ulp_half = get_ulp_half(T,keepbits)
    shift = get_shift(T,keepbits)
    keepmask = get_keep_mask(T,keepbits)
    return round(x,ulp_half,shift,keepmask)
end

"""IEEE's round to nearest tie to even for a float array `X` in-place. Calculates from `keepbits`
only once the variables `ulp_half`, `shift` and `keep_mask` and loops over every element of the
array."""
function round!(X::AbstractArray{T},                # any array with element type T
                keepbits::Integer                   # how many mantissa bits to keep
                ) where {T<:IEEEFloat_and_complex}  # constrain element type to (complex) Float16/32/64

    ulp_half = get_ulp_half(real(T),keepbits)       # half of unit in last place (ulp)
    shift = get_shift(real(T),keepbits)             # integer used for bitshift 
    keep_mask = get_keep_mask(real(T),keepbits)     # mask to zero trailing mantissa bits

    @inbounds for i in eachindex(X)                 # apply rounding to each element
        X[i] = round(X[i],ulp_half,shift,keep_mask)
    end

    return X
end

"""IEEE's round to nearest tie to even for a float array `X` which returns a rounded copy of `X`."""
function Base.round(X::AbstractArray{T},                # any array with element type T
                    keepbits::Integer                   # mantissa bits to keep
                    ) where {T<:IEEEFloat_and_complex}  # constrain element type to (complex) Float16/32/64

    Xcopy = copy(X)                             # copy array to avoid in-place changes
    round!(Xcopy,keepbits)                      # in-place round the copied array
    return Xcopy
end

"""Checks a given `mantissabit` of `x` for eveness. 1=odd, 0=even. Mantissa bits 
are positive for the mantissa (`mantissabit = 1` is the first mantissa bit), `mantissa = 0`
is the last exponent bit, and negative for the other exponent bits."""
function Base.iseven(x::T,
                    mantissabit::Integer
                    ) where {T<:Base.IEEEFloat}
    
    bitmask = get_bit_mask(T,mantissabit)
    return 0x0 == reinterpret(typeof(bitmask),x) & bitmask
end

"""Checks a given `mantissabit` of `x` for oddness. 1=odd, 0=even. Mantissa bits 
are positive for the mantissa (`mantissabit = 1` is the first mantissa bit), `mantissa = 0`
is the last exponent bit, and negative for the other exponent bits."""
Base.isodd(x::T,mantissabit::Integer) where {T<:Base.IEEEFloat} = ~iseven(x,mantissabit)