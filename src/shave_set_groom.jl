"""Creates a UInt32-mask for the trailing non-significant bits of a
Float32 number. `nsb` are the number of significant bits in the mantissa.
E.g. mask(3) returns `00000000000011111111111111111111`,
such that all but the first 3 significant bits can be masked."""
mask32(nsb::Integer) = UInt32(2^(23-nsb)-1)

"""Creates a UInt64-mask for the trailing non-significant bits of a
Float64 number. `nsb` are the number of significant bits in the mantissa."""
mask64(nsb::Integer) = UInt64(2^(52-nsb)-1)

halfshavemask32(nsb::Integer) = UInt32(2^(23-nsb-1))
halfshavemask64(nsb::Integer) = UInt64(2^(52-nsb-1))


"""Shave trailing bits of a Float32 number to zero.
Mask is UInt32 with 1 for the shaved bits, 0 for the retained bits."""
function shave(x::Float32,mask::UInt32)
    ui = reinterpret(UInt32,x)
    ui &= mask
    return reinterpret(Float32,ui)
end

"""Shave trailing bits of a Float32 number to zero.
Mask is UInt32 with 1 for the shaved bits, 0 for the retained bits."""
function shave(x::Float64,mask::UInt64)
    ui = reinterpret(UInt64,x)
    ui &= mask
    return reinterpret(Float64,ui)
end

function halfshave(x::Float32,mask::UInt32,hsmask::UInt32)
    ui = reinterpret(UInt32,x)
    ui &= mask      # set tail bits to zero
    ui |= hsmask    # set most significant tail bit to one
    return reinterpret(Float32,ui)
end

function halfshave(x::Float64,mask::UInt64,hsmask::UInt64)
    ui = reinterpret(UInt64,x)
    ui &= mask      # set tail bits to zero
    ui |= hsmask    # set most significant tail bit to one
    return reinterpret(Float64,ui)
end

"""Shave trailing bits of a Float32 number to zero.
Providing `nsb` the number of retained significant bits, a mask is created
and applied."""
shave(x::Float32,nsb::Integer) = shave(x,~mask32(nsb))
shave(x::Float64,nsb::Integer) = shave(x,~mask64(nsb))

halfshave(x::Float32,nsb::Integer) = halfshave(x,~mask32(nsb),halfshavemask32(nsb))
halfshave(x::Float64,nsb::Integer) = halfshave(x,~mask64(nsb),halfshavemask64(nsb))

"""Shave trailing bits of a Float32 number to zero.
In case no `sb` argument is applied for `shave`, shave 16 bits, retain 7."""
shave(x::Float32) = shave(x,7)
shave(x::Float64) = shave(x,12)

halfshave(x::Float32) = halfshave(x,7)
halfshave(x::Float64) = halfshave(x,12)

"""Shave trailing bits of a Float32 array to zero.
Creates the shave-mask only once and applies it to every element in `X`."""
shave(X::AbstractArray{Float32},nsb::Integer) = shave.(X,~mask32(nsb))
shave(X::AbstractArray{Float64},nsb::Integer) = shave.(X,~mask64(nsb))

halfshave(X::AbstractArray{Float32},nsb::Integer) = halfshave.(X,~mask32(nsb),halfshavemask32(nsb))
halfshave(X::AbstractArray{Float64},nsb::Integer) = halfshave.(X,~mask64(nsb),halfshavemask64(nsb))

"""Set trailing bits of a Float32 number to one.
Provided a UInt32 mask with 1 for bits to be set to one, and 0 else."""
function set_one(x::Float32,mask::UInt32)
    ui = reinterpret(UInt32,x)
    ui |= mask
    return reinterpret(Float32,ui)
end

function set_one(x::Float64,mask::UInt64)
    ui = reinterpret(UInt64,x)
    ui |= mask
    return reinterpret(Float64,ui)
end

"""Set trailing bits of Float32 number to one, given `nsb` number of significant
bits retained. A mask is created and applied."""
set_one(x::Float32,nsb::Integer) = set_one(x,mask32(nsb))
set_one(x::Float64,nsb::Integer) = set_one(x,mask64(nsb))

"""Set trailing bits of a Float32 number to one.
In case no `sb` argument is applied for `set_one`, set 16 bits, retain 7."""
set_one(x::Float32) = set_one(x,7)
set_one(x::Float64) = set_one(x,12)

"""Set trailing bits of a Float32 number to one.
Creates the setting-mask only once and applies it to every element in `X`."""
set_one(X::AbstractArray{Float32},nsb::Integer) = set_one.(X,mask32(nsb))
set_one(X::AbstractArray{Float64},nsb::Integer) = set_one.(X,mask64(nsb))

"""Bit-grooming. Alternatingly apply bit-shaving and setting to a Float32 array."""
function groom(X::AbstractArray{Float32},nsb::Integer)

    Y = similar(X)          # preallocate output of same size and type
    mask1 = mask32(nsb)     # mask for setting
    mask0 = ~mask1          # mask for shaving
    n = length(X)


    @inbounds for i in 1:2:length(X)-1
        Y[i] = shave(X[i],mask0)            # every second element is shaved
        Y[i+1] = set_one(X[i+1],mask1)      # every other 2nd element is set
    end

    # for arrays of uneven length shave last element (as exempted from loop)
    Y[end] = n % 2 == 1 ? shave(X[end],mask0) : Y[end]

    return Y
end

function groom(X::AbstractArray{Float64},nsb::Integer)

    Y = similar(X)          # preallocate output of same size and type
    mask1 = mask64(nsb)     # mask for setting
    mask0 = ~mask1          # mask for shaving
    n = length(X)

    @inbounds for i in 1:2:n-1
        Y[i] = shave(X[i],mask0)            # every second element is shaved
        Y[i+1] = set_one(X[i+1],mask1)      # every other 2nd element is set
    end

    # for arrays of uneven length shave last element (as exempted from loop)
    Y[end] = n % 2 == 1 ? shave(X[end],mask0) : Y[end]

    return Y
end
