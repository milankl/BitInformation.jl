"""
    n = bitcount(A::AbstractArray{T},i::Int) where {T<:Unsigned}

Counts the occurences of the 1-bit in bit position i across all elements of A."""
function bitcount(A::AbstractArray{T},i::Int) where {T<:Unsigned}
    nbits = sizeof(T)*8         # number of bits in T
    @boundscheck i <= nbits || throw(error("Can't count bit $b for $N-bit type $T."))
    
    c = 0                       # counter
    shift = nbits-i             # shift bit i in least significant position
    mask = one(T) << shift      # mask to isolate the bit in position i
    @inbounds for a in A                  
        c += (a & mask) >> shift   # to have either 0x0 or 0x1 to increase counter
    end
    return c
end

"""
    C = bitcount(A::AbstractArray{T}) where {T<:Union{Integer,AbstractFloat}}

Counts the occurences of the 1-bit in every bit position across all elements of `A`.
Returns a counter array `C::Vector{Int}` such that the first entries represents
the first bit in elements of type `T`, e.g. the sign bit for floats."""
function bitcount(A::AbstractArray{T}) where {T<:Union{Integer,AbstractFloat}}
    nbits = 8*sizeof(T)             # determine the size [bit] of elements in A
    C = zeros(Int,nbits)
    Auint = reinterpret(Base.uinttype(T),A)

    # loop over bit positions and for each count through all elements in A
    # outer loop: bit position, inner loop: all elements in a
    # note this is faster than swapping inner & outer loop
    @inbounds for i in 1:nbits      
        C[i] = bitcount(Auint,i)
    end
    return C
end

"""
    H = bitcount_entropy(A::AbstractArray{T},base::Real=2) where {T<:Union{Integer,AbstractFloat}}

Returns a vector `H` of entropies for the occurence of 0,1 in every bit position in `T` across elements of `A`.
Makes use of the `bitcount` functions and calculates the entropy from the probability of the 0 and 1 bit.
The base `base` is by default 2, such that the unit of entropy is bit."""
function bitcount_entropy(  A::AbstractArray{T},    # input array
                            base::Real=2            # entropy with base
                            ) where {T<:Union{Integer,AbstractFloat}}
    
    nbits = 8*sizeof(T)                 # number of bits in T
    nelements = length(A)

    C = bitcount(A)                     # count 1 bits for each bit position
    H = zeros(nbits)                    # allocate entropy for each bit position

    @inbounds for i in 1:nbits          # loop over bit positions
        p = C[i]/nelements              # probability of bit 1
        H[i] = entropy([p,1-p],base)    # entropy based on p
    end

    return H
end

"""
    bitpair_count!(C::Array{Int,3},a::T,b::T) where {T<:Integer}

Update counter array C of size nbits x 2 x 2 for every 00|01|10|11-bitpairing in a,b.
`nbits` is the number of bits in type `T`.""" 
function bitpair_count!(C::Array{Int,3},a::T,b::T) where {T<:Integer}
    nbits = 8*sizeof(T)
    mask = one(T)                   # start with least significant bit
    @inbounds for i in 0:nbits-1    # loop from least to most significant bit
        j = 1+((a & mask) >>> i)    # isolate that bit in a,b
        k = 1+((b & mask) >>> i)    # and move to 0x0 or 0x1s
        C[nbits-i,j,k] += 1         # to be used as index j,k to increase counter C
        mask <<= 1                  # shift mask to get the next significant bit
    end
end

"""
    C = bitpair_count(A::AbstractArray{T},B::AbstractArray{T}) where {T<:Union{Integer,AbstractFloat}}

Returns counter array C of size nbits x 2 x 2 for every 00|01|10|11-bitpairing in elements of A,B.
`nbits` is the number of bits in type `T`."""
function bitpair_count( A::AbstractArray{T},
                        B::AbstractArray{T}
                        ) where {T<:Union{Integer,AbstractFloat}}
    
    @assert size(A) == size(B) "Size of A=$(size(A)) does not match size of B=$(size(B))"        

    nbits = 8*sizeof(T)             # number of bits in eltype(A),eltype(B)
    C = zeros(Int,nbits,2,2)        # array of bitpair counters

    # reinterpret arrays A,B as UInt (no mem allocation required)
    Auint = reinterpret(Base.uinttype(T),A)
    Buint = reinterpret(Base.uinttype(T),B)

    # loop over all elements in A,B pairwise, inner loop (within bitpair_count!): bit positions
    # note this is faster than swapping inner & outer loop
    for (a,b) in zip(Auint,Buint)
        bitpair_count!(C,a,b)       # count the bits and update counter array C
    end

    return C
end

"""
    C = bitpair_count(A::AbstractArray{T},mask::AbstractArray{Bool}) where {T<:Union{Integer,AbstractFloat}}

Returns counter array C of size nbits x 2 x 2 for every 00|01|10|11-bitpairing in elements of A,B where neither
are masked as determined from `mask`. `nbits` is the number of bits in type `T`."""
function bitpair_count( A::AbstractArray{T},
                        mask::AbstractArray{Bool}
                        ) where {T<:Union{Integer,AbstractFloat}}
    
    @assert size(A) == size(mask) "Size of A=$(size(A)) does not match size of its mask=$(size(mask))"        

    nbits = 8*sizeof(T)             # number of bits in eltype(A)
    C = zeros(Int, nbits, 2, 2)     # array of bitpair counters

    # reinterpret arrays A,B as UInt (no mem allocation required)
    Auint = reinterpret(Base.uinttype(T), A)

    # always mask the last element in every column to avoid counting bitpairs across boundaries
    n = size(A, 1)

    @inbounds for jk in CartesianIndices(size(A)[2:end])  # 2nd, 3rd, ... dimension
        for i in 1:n-1                          # first dimension but skip the last element
            if ~(mask[i, jk] | mask[i+1, jk])   # if neither entry is masked
                bitpair_count!(C, Auint[i, jk], Auint[i+1, jk])   # count all bits and increase counter C
            end
        end
    end

    return C
end

# """Update counter array C of size nbits x 2 x 2 for every 00|01|10|11-bitpairing in a,b.""" 
# function bitpair_count!(C::Array{Int,3},        # counter array nbits x 2 x 2
#                         A::AbstractArray{T},    # input array A
#                         B::AbstractArray{T},    # input array B
#                         i::Int                  # bit position
#                         ) where {T<:Integer}

#     nbits = 8*sizeof(T)                 # number of bits in T
#     shift = nbits-i                     # shift bit i in least significant position
#     mask = one(T) << shift              # mask to isolate the bit in position i

#     @inbounds for (a,b) in zip(A,B)     # loop over all elements in A,B pairwise
#         j = 1+((a & mask) >>> shift)    # isolate bit i in a,b
#         k = 1+((b & mask) >>> shift)    # and move to 0x0 or 0x1
#         C[i,j,k] += 1                   # to be used as index j,k to increase counter C
#     end
# end

# """Returns counter array C of size nbits x 2 x 2 for every 00|01|10|11-bitpairing in elements of A,B."""
# function bitpair_count( A::AbstractArray{T},
#                         B::AbstractArray{T}
#                         ) where {T<:Union{Integer,AbstractFloat}}
    
#     @assert size(A) == size(B) "Size of A=$(size(A)) does not match size of B=$(size(B))"        

#     nbits = 8*sizeof(T)             # number of bits in eltype(A),eltype(B)
#     C = zeros(Int,nbits,2,2)        # array of bitpair counters

#     # reinterpret arrays A,B as UInt (no mem allocation required)
#     Auint = reinterpret(Base.uinttype(T),A)
#     Buint = reinterpret(Base.uinttype(T),B)

#     for i in 1:nbits
#         bitpair_count!(C,Auint,Buint,i)       # count the bits and update counter array C
#     end

#     return C
# end