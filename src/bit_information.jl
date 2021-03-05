"""Count the occurences of the 1-bit in bit position b across all elements of A."""
function bitcount(A::AbstractArray{T},b::Int) where {T<:Union{Integer,AbstractFloat}}
    N = sizeof(T)*8             # number of bits in T
    @boundscheck b <= N || throw(error("Can't count bit $b for $N-bit type $T."))
    UIntT = whichUInt(T)
    n = 0                       # counter
    shift = N-b                 # shift desired bit b
    mask = one(UIntT) << shift  # leftshift always pushes 0s
    for a in A                  # mask everything but b and shift
        n += (reinterpret(UIntT,a) & mask) >>> shift   # to have either 0x00 or 0x01
    end
    return n
end

"""Count the occurences of the 1-bit in every bit position b across all elements of A."""
function bitcount(A::AbstractArray{T}) where {T<:Union{Integer,AbstractFloat}}
    N = 8*sizeof(T)             # determine the size [bit] of elements in A
    n = fill(0,N)               # preallocate counters
    for b in 1:N                # loop over bit positions and count each
        n[b] = bitcount(A,b)
    end
    return n
end

"""Entropy [bit] for bitcount functions. Maximised to 1bit for random uniformly
distributed bits in A."""
function bitcountentropy(A::AbstractArray)
    N = prod(size(A))
    ps = bitcount(A) / N
    e = [abs(entropy([p,1-p],2)) for p in ps]
    return e
end

"""Count pairs of bits across elements of A for bit position b therein.
Returns a 4-element array with counts for 00,01,10,11."""
function bitpaircount(A::AbstractArray{T},b::Int) where {T<:Union{Integer,AbstractFloat}}
    N = sizeof(T)*8             # number of bits in T
    @boundscheck b <= N || throw(error("Can't count bit $b for $N-bit type $T."))
    UIntT = whichUInt(T)

    n = [0,0,0,0]                   # counter for 00,01,10,11
    shift = N-b-1                   # shift to the 2nd last position either 0x00,0x10
    shift2 = N-b                    # shift to last position 0x0 or 0x1
    mask = one(UIntT) << shift2     # mask everything except b

    # a1 is bit from previous entry in A, a2 is the current
    # a1 is shifted to sit in the 2nd last position
    # a2 sits in the last position
    a1 = (reinterpret(UIntT,A[1]) & mask) >>> shift
    @inbounds for i in 2:length(A)
        a2 = (reinterpret(UIntT,A[i]) & mask) >>> shift2
        n[(a1 | a2)+1] += 1
        a1 = a2 << 1
    end
    return n
end

"""Count pairs of bits across elements of A for every bit position therein.
Returns a 4xn-array with counts for 00,01,10,11 in rows and every bit position
in columns."""
function bitpaircount(A::AbstractArray{T}) where {T<:Union{Integer,AbstractFloat}}
    N = 8*sizeof(T)         # number of bits in T
    n = fill(0,4,N)         # store the 4 possible pair counts for every bit position
    for b in 1:N
        n[:,b] = bitpaircount(A,b)
    end
    return n
end

"""Calculates the conditional probabilities of pairs 00,01,10,11 in the bit sequences
of array A. Returns a 4xn array with conditional probabilities p(nextbit=0|previousbit=0),
p(1|0),p(0|1),p(1|1) in rows and every bit position in columns. Returns NaN when
all bits are either 0,1 (in which case the conditional probability is not defined)."""
function bitcondprobability(A::Array{T}) where {T<:Union{Integer,AbstractFloat}}
    N = prod(size(A[2:end]))        # elements in array (A[1] is )
    n1 = bitcount(A[1:end-1])
    n0 = N.-n1
    npair = bitpaircount(A)
    pcond = similar(npair,Float64)
    pcond[1,:] = npair[1,:] ./ n0
    pcond[2,:] = npair[2,:] ./ n0
    pcond[3,:] = npair[3,:] ./ n1
    pcond[4,:] = npair[4,:] ./ n1
    return pcond
end

"""Calculates the conditional entropy for 00,01,10,11 for every bit position across
all elements of A."""
function bitcpentropy(A::Array{T}) where {T<:Union{Integer,AbstractFloat}}
    pcond = bitcondprobability(A)
    pcond[isnan.(pcond)] .= 0
    pcond /= 2      # divide by 2 as p(0|0)+p(1|0)+p(0|1)+p(1|1)=2
    e = [abs(entropy(pcond[:,i],2)) for i in 1:size(pcond)[2]]
    return e
end

function bitinformation(A::AbstractArray,dims::Symbol)
    if dims == :all_dimensions
        N = prod(size(A))-1                     # elements in array
        n1 = bitcount(A)-bitcount([A[end]])     # occurences of bit = 1
        bi = fill(0.0,length(n1))
        permu = collect(1:ndims(A))                 # permutation
        perm0 = vcat(permu[2:end],permu[1])         # used to permute permu
        for idim in 1:ndims(A)
            Aperm = PermutedDimsArray(A,permu)
            permute!(permu,perm0)
            npair = bitpaircount(Aperm)
            bi .+= bitinformation(n1,npair,N)
        end
        # arithmetic mean of information across the dimensions
        return bi ./ ndims(A)
    else
        return bitinformation(A)
    end
end

function bitinformation(A::AbstractArray;dims::Int=1)
    N = prod(size(A))-1                         # elements in array
    n1 = bitcount(A)-bitcount([A[end]])     # occurences of bit = 1

    if dims > 1
        permu = collect(1:ndims(A))                 # permutation
        perm0 = vcat(permu[2:end],permu[1])         # used to permute permu
        for _ in 1:dims-1
            permute!(permu,perm0)
        end
        A = PermutedDimsArray(A,permu)
    end

    npair = bitpaircount(A)
    return bitinformation(n1,npair,N)
end

function bitinformation(n1::Array{Int,1},npair::Array{Int,2},N::Int)
    nbits = length(n1)
    @assert size(npair) == (4,nbits)    "npair array must be of size 4xnbits"
    @assert maximum(n1) <= N            "N cannot be smaller than maximum(n1)"

    n0 = N.-n1                      # occurences of bit = 0
    q0 = n0/N                       # respective probabilities
    q1 = n1/N

    pcond = similar(npair,Float64)      # preallocate conditional probability

    pcond[1,:] = npair[1,:] ./ n0       # p(0|0) = n(00)/n(0)
    pcond[2,:] = npair[2,:] ./ n0       # p(1|0) = n(01)/n(0)
    pcond[3,:] = npair[3,:] ./ n1       # p(0|1) = n(10)/n(1)
    pcond[4,:] = npair[4,:] ./ n1       # p(1|1) = n(11)/n(1)

    # set NaN (occurs when occurences n=0) 0*-Inf = 0 here.
    pcond[isnan.(pcond)] .= 0

    # unconditional entropy
    H = [entropy([q0i,q1i],2) for (q0i,q1i) in zip(q0,q1)]

    # conditional entropy given bit = 0, bit = 1
    H0 = [entropy([p00,p01],2) for (p00,p01) in zip(pcond[1,:],pcond[2,:])]
    H1 = [entropy([p10,p11],2) for (p10,p11) in zip(pcond[3,:],pcond[4,:])]

    # Information content, take abs as rounding errors can yield negative I
    I = @. abs(H - q0*H0 - q1*H1)

    return I
end
