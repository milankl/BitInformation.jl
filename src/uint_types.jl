# define the uints for various formats
Base.uinttype(::Type{UInt8}) = UInt8
Base.uinttype(::Type{UInt16}) = UInt16
Base.uinttype(::Type{UInt32}) = UInt32
Base.uinttype(::Type{UInt64}) = UInt64

Base.uinttype(::Type{Int8}) = UInt8
Base.uinttype(::Type{Int16}) = UInt16
Base.uinttype(::Type{Int32}) = UInt32
Base.uinttype(::Type{Int64}) = UInt64

# uints for other types are identified by their byte size
Base.uinttype(::Type{T}) where T = Base.uinttype(sizeof(T)*8)

# or return the UInt type based on the number of bits 
function Base.uinttype(nbits::Integer)
    nbits == 8 && return UInt8
    nbits == 16 && return UInt16
    nbits == 32 && return UInt32
    nbits == 64 && return UInt64
    throw(error("Only n=8,16,32,64 bits supported."))
end