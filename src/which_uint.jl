function whichUInt(n::Integer)
    n == 8 && return UInt8
    n == 16 && return UInt16
    n == 32 && return UInt32
    n == 64 && return UInt64
    throw(error("Only n=8,16,32,64 supported."))
end

whichUInt(::Type{T}) where T = whichUInt(sizeof(T)*8)
