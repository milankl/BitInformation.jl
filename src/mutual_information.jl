
"""Mutual information from the joint probability mass function p
of two variables X,Y. p is an NxM array which elements represent
the probabilities of observing x~X and y~Y.""" 
function mutual_information(p::AbstractArray{T,2},base::Real=2) where T
    @assert sum(p) ≈ one(T)  "Entries in p have to sum to 1"
    @assert all(p .>= zero(T))  "Entries in p have to be >= 1"
    
    nx,ny = size(p)
    
    mpx = sum(p,dims=2)     # marginal probabilities of x
    mpy = sum(p,dims=1)
    
    M = zero(T)
    for j in 1:ny
        for i in 1:nx
            if p[i,j] > zero(T)
                M += p[i,j]*log(p[i,j]/mpx[i]/mpy[j])
            end
        end
    end

    M /= log(base)
end

"""Mutual bitwise information of the elements in input arrays A,B.
A and B have to be of same size and eltype."""
function bitinformation(A::AbstractArray{T},
                        B::AbstractArray{T}) where {T<:Union{Integer,AbstractFloat}}
    
    @assert size(A) == size(B)
    nelements = length(A)
    nbits = 8*sizeof(T)

    # array of counters, first dim is from last bit to first
    C = zeros(Int,nbits,2,2)

    for (a,b) in zip(A,B)   # run through all elements in A,B pairwise
        bitcount!(C,a,b)    # count the bits and update counter array C
    end

    # P is the join probabilities mass function
    # invert the order of C's first dimension
    P = [C[i,:,:]/nelements for i in nbits:-1:1]
    M = [mutual_information(p) for p in P]
    return M
end

"""Update counter array of size nbits x 2 x 2 for every 
00|01|10|11-bitpairing in a,b.""" 
function bitcount!(C::Array{Int,3},a::T,b::T) where {T<:AbstractFloat}
    uia = reinterpret(Base.uinttype(T),a)
    uib = reinterpret(Base.uinttype(T),b)
    bitcount!(C,uia,uib)
end

"""Update counter array of size nbits x 2 x 2 for every 
00|01|10|11-bitpairing in a,b.""" 
function bitcount!(C::Array{Int,3},a::T,b::T) where {T<:Integer}
    nbits = 8*sizeof(T)
    mask = one(T)
    for i in 1:nbits
        j = 1+((a & mask) >>> (i-1))
        k = 1+((b & mask) >>> (i-1))
        C[i,j,k] += 1
        mask <<= 1
    end
end

"""Calculate the bitwise redundancy of two arrays A,B. redundancy
is a normalised measure of the mutual information 1 for always
identical/opposite bits, 0 for no mutual information."""
function redundancy(A::AbstractArray{T},
                    B::AbstractArray{T}) where {T<:Union{Integer,AbstractFloat}}
    mutinf = bitinformation(A,B)    # mutual information
    HA = bitcount_entropy(A)        # entropy of A
    HB = bitcount_entropy(B)        # entropy of B
    R = 2mutinf./(HA+HB)            # redundancy (symmetric)

    R[iszero.(HA+HB)] .= 0.0         # HA+HB = 0 creates NaN
    return R
end