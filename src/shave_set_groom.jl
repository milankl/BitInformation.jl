"""Bitshaving for floats. Sets trailing bits to 0 (round towards zero).
`keepmask` is an unsigned integer with bits being `1` for bits to be kept,
and `0` for those that are shaved off."""
function shave( x::T,
                keepmask::UIntT
                ) where {T<:Base.IEEEFloat,UIntT<:Unsigned}
    ui = reinterpret(UIntT,x)
    ui &= keepmask              # set trailing bits to zero
    return reinterpret(T,ui)
end

"""Halfshaving for floats. Replaces trailing bits with `1000...` a variant
of round nearest whereby the representable numbers are halfway between those
from shaving or IEEE's round nearest."""
function halfshave( x::T,
                    keepmask::UIntT,
                    bitmask::UIntT
                    ) where {T<:Base.IEEEFloat,UIntT<:Unsigned}
    ui = reinterpret(UIntT,x)
    ui &= keepmask      # set trailing bits to zero
    ui |= bitmask       # set first trailing bit to 1
    return reinterpret(T,ui)
end

"""Bitsetting for floats. Replace trailing bits with `1`s (round away from zero).
`setmask` is an unsigned integer with bits being `1` for those that are set to one
and `0` otherwise, such that the bits to keep are unaffected."""
function set_one(   x::T,
                    setmask::UIntT
                    ) where {T<:Base.IEEEFloat,UIntT<:Unsigned}
    ui = reinterpret(UIntT,x)
    ui |= setmask      # set trailing bits to 1
    return reinterpret(T,ui)
end

"""Bitshaving of a float `x` given `keepbits` the number of mantissa bits to keep
after shaving."""
function shave(x::T,keepbits::Integer) where {T<:Base.IEEEFloat}
    return shave(x,get_keep_mask(T,keepbits))
end

"""Halfshaving of a float `x` given `keepbits` the number of mantissa bits to keep
after halfshaving."""
function halfshave(x::T,keepbits::Integer) where {T<:Base.IEEEFloat}
    return halfshave(x,get_keep_mask(T,keepbits),get_bit_mask(T,keepbits+1))
end

"""Bitsetting of a float `x` given `keepbits` the number of mantissa bits to keep
after setting."""
function set_one(x::T,keepbits::Integer) where {T<:Base.IEEEFloat}
    return set_one(x,~get_keep_mask(T,keepbits))
end

"""In-place version of `shave` for any array `X` with floats as elements."""
function shave!(X::AbstractArray{T},            # any array with element type T
                keepbits::Integer               # how many mantissa bits to keep
                ) where {T<:Base.IEEEFloat}     # constrain element type to Float16/32/64

    keep_mask = get_keep_mask(T,keepbits)       # mask to zero trailing mantissa bits

    @inbounds for i in eachindex(X)             # apply rounding to each element
        X[i] = shave(X[i],keep_mask)
    end

    return X
end

"""In-place version of `halfshave` for any array `X` with floats as elements."""
function halfshave!(X::AbstractArray{T},        # any array with element type T
                    keepbits::Integer           # how many mantissa bits to keep
                    ) where {T<:Base.IEEEFloat} # constrain element type to Float16/32/64

    keep_mask = get_keep_mask(T,keepbits)       # mask to zero trailing mantissa bits
    bit_mask = get_bit_mask(T,keepbits+1)       # mask to set the first trailing bit to 1

    @inbounds for i in eachindex(X)             # apply rounding to each element
        X[i] = halfshave(X[i],keep_mask,bit_mask)
    end

    return X
end

"""In-place version of `set_one` for any array `X` with floats as elements."""
function set_one!(  X::AbstractArray{T},        # any array with element type T
                    keepbits::Integer           # how many mantissa bits to keep
                    ) where {T<:Base.IEEEFloat} # constrain element type to Float16/32/64

    set_mask = ~get_keep_mask(T,keepbits)       # mask to set trailing mantissa bits to 1
    
    @inbounds for i in eachindex(X)             # apply rounding to each element
        X[i] = set_one(X[i],set_mask)
    end

    return X
end

"""Bitgrooming for a float arrays `X` keeping `keepbits` mantissa bits. In-place version
that shaves/sets the elements of `X` alternatingly."""
function groom!(X::AbstractArray{T},        # any array with element type T
                keepbits::Integer           # how many mantissa bits to keep
                ) where {T<:Base.IEEEFloat} # constrain element type to Float16/32/64

    keep_mask = get_keep_mask(T,keepbits)   # mask to zero trailing mantissa bits
    set_mask = ~keep_mask                   # mask to set trailing mantissa bits to 1
    
    n = length(X)

    @inbounds for i in 1:2:n-1
        X[i] = shave(X[i],keep_mask)        # every second element is shaved
        X[i+1] = set_one(X[i+1],set_mask)   # every other 2nd element is set
    end

    # for arrays of uneven length shave last element (as exempted from loop)
    @inbounds X[end] = n % 2 == 1 ? shave(X[end],keep_mask) : X[end]

    return X
end

# Shave, halfshave, set_one, groom which returns a rounded copy of array `X` instead of
# chaning its elements in-place.
for func in (:shave,:halfshave,:set_one,:groom)
    func! = Symbol(func,:!)
    @eval begin
        function $func( X::AbstractArray{T},            # any array with element type T
                        keepbits::Integer               # how many mantissa bits to keep
                        ) where {T<:Base.IEEEFloat}     # constrain element type to Float16/32/64

            Xcopy = copy(X)                                 # copy to avoid in-place changes of X
            $func!(Xcopy,keepbits)                          # in-place on X's copy
            return Xcopy
        end
    end
end

# """Number of significant bits `nsb` given the number of significant digits `nsd`."""
# nsb(nsd::Integer) = Integer(ceil(log(10)/log(2)*nsd))