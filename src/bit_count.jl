import StatsBase: entropy

"""Count the occurences of the 1-bit in bit position i across all elements of A."""
function bitcount(A::AbstractArray{T},i::Int) where {T<:Union{Integer,AbstractFloat}}
    nbits = sizeof(T)*8         # number of bits in T
    @boundscheck i <= nbits || throw(error("Can't count bit $b for $N-bit type $T."))
    
    UIntT = Base.uinttype(T)    # UInt corresponding to T
    c = 0                       # counter
    shift = nbits-i             # shift bit i in least significant position
    mask = one(UIntT) << shift  # mask to isolate the bit in position i
    @inbounds for a in A                  
        ui = reinterpret(UIntT,a)   # mask everything but i and shift
        c += (ui & mask) >> shift   # to have either 0x0 or 0x1 to increase counter
    end
    return c
end

"""Count the occurences of the 1-bit in every bit position b across all elements of A."""
function bitcount(A::AbstractArray{T}) where {T<:Union{Integer,AbstractFloat}}
    nbits = 8*sizeof(T)             # determine the size [bit] of elements in A
    C = zeros(Int,nbits)
    @inbounds for b in 1:nbits      # loop over bit positions and for each
        C[b] = bitcount(A,b)        # count through all elements in A
    end
    return C
end

"""Entropy [bit] for bitcount functions. Maximised to 1bit for random uniformly
distributed bits in A."""
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

"""Update counter array C of size nbits x 2 x 2 for every 00|01|10|11-bitpairing in a,b.""" 
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

"""Returns counter array C of size nbits x 2 x 2 for every 00|01|10|11-bitpairing in elements of A,B."""
function bitpair_count( A::AbstractArray{T},
                        B::AbstractArray{T}
                        ) where {T<:Union{Integer,AbstractFloat}}
    
    @assert size(A) == size(B) "Size of A=$(size(A)) does not match size of B=$(size(B))"        

    nbits = 8*sizeof(T)             # number of bits in eltype(A),eltype(B)
    C = zeros(Int,nbits,2,2)        # array of bitpair counters

    # reinterpret arrays A,B as UInt (no mem allocation required)
    Auint = reinterpret(Base.uinttype(T),A)
    Buint = reinterpret(Base.uinttype(T),B)

    for (a,b) in zip(Auint,Buint)   # run through all elements in A,B pairwise
        bitpair_count!(C,a,b)       # count the bits and update counter array C
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