"""Calculates an integeer as argument for a bitshift operation
required to move the least significant bit (after rounding) to
the last bit."""
shift32(nsb::Integer) = 23-nsb  # Float32 version
shift64(nsb::Integer) = 52-nsb  # Float64 version

"""Creates a mask for bit-setting given `nsb` bits to be retained in the
significand. Does not mask the first significant bit for rounding."""
setmask32(nsb::Integer) = 0x003f_ffff >> nsb
setmask64(nsb::Integer) = 0x0007_ffff_ffff_ffff >> nsb

"""Round to nearest for Float32 arithmetic, using only integer
arithmetic. `setmask`,`shift`,`shavemask` have to be provided that depend
on the number of significant bits that will be retained."""
function Base.round(x::Float32,
                    setmask::UInt32,
                    shift::Integer,
                    shavemask::UInt32)
    ui = reinterpret(UInt32,x)
    ui += setmask + ((ui >> shift) & 0x0000_0001)
    return reinterpret(Float32,ui & shavemask)
end

"""Round to nearest for Float64 arithmetic, using only integer
arithmetic. `setmask`,`shift`,`shavemask` have to be provided that depend
on the number of significant bits that will be retained."""
function Base.round(x::Float64,
                    setmask::UInt64,
                    shift::Integer,
                    shavemask::UInt64)
    ui = reinterpret(UInt64,x)
    ui += setmask + ((ui >> shift) & 0x0000_0000_0000_0001)
    return reinterpret(Float64,ui & shavemask)
end

"""Round to nearest for Float32, given `nsb` number of signifcant bits, that
will be retained. E.g. round(x,7) will round the trailing 16 bits and retain
the 7 significant bits (which might be subject to change by a carry bit)."""
Base.round(x::Float32,nsb::Integer) = round(x,setmask32(nsb),shift32(nsb),~mask32(nsb))

"""Round to nearest for Float64, given `nsb` number of signifcant bits, that
will be retained. E.g. round(x,7) will round the trailing 48 bits and retain
the 7 significant bits (which might be subject to change by a carry bit)."""
Base.round(x::Float64,nsb::Integer) = round(x,setmask64(nsb),shift64(nsb),~mask64(nsb))

"""Round to nearest for a Float32 array `X`. The bit-masks are only created once
and then applied to every element in `X`."""
function Base.round(X::AbstractArray{Float32},nsb::Integer)
    semask = setmask32(nsb)
    s = shift32(nsb)
    shmask = ~mask32(nsb)

    Y = similar(X)                              # preallocate
    for i in eachindex(X)
        Y[i] = round(X[i],semask,s,shmask)
    end
    
    return Y
end

"""In-place version of round(X::AbstractArray,nsb::Integer)."""
function round!(X::AbstractArray{Float32},nsb::Integer)
    semask = setmask32(nsb)
    s = shift32(nsb)
    shmask = ~mask32(nsb)

    for i in eachindex(X)
        X[i] = round(X[i],semask,s,shmask)
    end

    return X
end

"""Round to nearest for a Float64 array `X`. The bit-masks are only created once
and then applied to every element in `X`."""
function Base.round(X::AbstractArray{Float64},nsb::Integer)
    semask = setmask64(nsb)
    s = shift64(nsb)
    shmask = ~mask64(nsb)

    Y = similar(X)
    for i in eachindex(X)
        Y[i] = round(X[i],semask,s,shmask)
    end

    return Y
end

"""In-place version of round(X::AbstractArray,nsb::Integer)."""
function round!(X::AbstractArray{Float64},nsb::Integer)
    semask = setmask64(nsb)
    s = shift64(nsb)
    shmask = ~mask64(nsb)

    for i in eachindex(X)
        X[i] = round(X[i],semask,s,shmask)
    end

    return X
end

"""Number of significant bits `nsb` given the number of significant digits `nsd`."""
nsb(nsd::Integer) = Integer(ceil(log(10)/log(2)*nsd))

kouzround(x::Union{Float32,Float64},nsb::Integer) = shave(2x-shave(x,nsb),nsb)

function kouzround(x::AbstractArray{Float32},nsb::Integer)
    y = similar(x)
    mask = ~mask32(nsb)
    for i in eachindex(x)
        y[i] = shave(2x[i]-shave(x[i],mask),mask)
    end
    return y
end