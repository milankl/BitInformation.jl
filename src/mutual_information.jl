"""Mutual information from the joint probability mass function p
of two variables X,Y. p is an nx x ny array which elements represent
the probabilities of observing x~X and y~Y.""" 
function mutual_information(p::AbstractArray{T,2},base::Real=2) where T
    @assert sum(p) ≈ one(T)     "Entries in p have to sum to 1"
    @assert all(p .>= zero(T))  "Entries in p have to be >= 1"
    
    nx,ny = size(p)         # events X are 1st dim, Y is 2nd
    py = sum(p,dims=1)      # marginal probabilities of y
    px = sum(p,dims=2)      # marginal probabilities of x
    
    M = zero(T)             # mutual information M
    for j in 1:ny           # loop over all entries in p
        for i in 1:nx
            # add entropy only for non-zero entries in p
            if p[i,j] > zero(T)
                M += p[i,j]*log(p[i,j]/px[i]/py[j])
            end
        end
    end

    M /= log(base)          # convert to given base
end

"""Mutual bitwise information of the elements in input arrays A,B.
A and B have to be of same size and eltype."""
function mutual_information(A::AbstractArray{T},
                            B::AbstractArray{T};
                            set_zero_insignificant::Bool=true,
                            confidence::Real=0.99
                            ) where {T<:Union{Integer,AbstractFloat}}
    
    nelements = length(A)           # number of elements in each A and B
    nbits = 8*sizeof(T)             # number of bits in eltype(A),eltype(B)

    C = bitpair_count(A,B)          # nbits x 2 x 2 array of bitpair counters
    M = zeros(nbits)                # allocate mutual information array
    P = zeros(2,2)                  # allocate joint probability mass function    

    @inbounds for i in 1:nbits      # mutual information for every bit position
        for j in 1:2, k in 1:2      # joint prob mass from counter C
            P[j,k] = C[i,j,k]/nelements     
        end
        M[i] = mutual_information(P)
    end

    # remove information that is insignificantly different from a random 50/50
    if set_zero_insignificant
        set_zero_insignificant!(M,nelements,confidence)                        
    end

    return M
end

"""
    M = bitinformation(A::AbstractArray{T}) where {T<:Union{Integer,AbstractFloat}}

Bitwise real information content of array `A` calculated from the bitwise mutual information
in adjacent entries in `A`. Optional keyword arguments

    - `dim::Int=1` computes the bitwise information along dimension `dim`.
    - `masked_value::T=NaN` masks all entries in `A` that are equal to `masked_value`.
    - `set_zero_insignificant::Bool=true` set insignificant information to zero.
    - `confidence::Real=0.99` confidence level for `set_zero_insignificant`.
"""
function bitinformation(A::AbstractArray{T};
                        dim::Int=1,
                        masked_value::Union{T, Nothing}=nothing,
                        kwargs...) where {T<:Union{Integer, AbstractFloat}}
    
    # create a BitArray mask if a masked_value is provided, use === to also allow NaN comparison
    isnothing(masked_value) || return bitinformation(A, A .=== masked_value; dim, kwargs...)

    A = permute_dim_forward(A, dim) # Permute A to take adjacent entry in dimension dim
    n = size(A, 1)                  # n elements in dim

    # create a two views on A for pairs of adjacent entries, dim is always 1st dimension after permutation
    A1view = selectdim(A, 1, 1:n-1)     # no adjacent entries in A array bounds
    A2view = selectdim(A, 1, 2:n)       # for same indices A2 is the adjacent entry to A1

    return mutual_information(A1view, A2view; kwargs...)
end

"""
    M = bitinformation(A::AbstractArray{T}, mask::BitArray) where {T<:Union{Integer,AbstractFloat}}

Bitwise real information content of array `A` calculated from the bitwise mutual information
in adjacent entries in A along dimension `dim` (optional keyword). Array `A` is masked through
trues in entries of the mask `mask`. Masked elements are ignored in the bitwise information calculation."""
function bitinformation(A::AbstractArray{T},
                        mask::BitArray;
                        dim::Int=1,
                        set_zero_insignificant::Bool=true,
                        confidence::Real=0.99) where {T<:Union{Integer, AbstractFloat}}

    @boundscheck size(A) == size(mask) || throw(BoundsError)
    nbits = 8*sizeof(T)

    # Permute A and mask to take adjacent entry in dimension dim
    A = permute_dim_forward(A, dim)
    mask = permute_dim_forward(mask, dim)

    C = bitpair_count(A, mask)          # nbits x 2 x 2 array of bitpair counters
    nelements = sum(view(C, 1, :, :))   # depending on mask nelements changes so obtain via C
    @assert nelements > 0 "Mask has $(sum(.~mask)) unmasked values, 0 entries are adjacent."
    
    M = zeros(nbits)                # allocate mutual information array
    P = zeros(2, 2)                 # allocate joint probability mass function    

    @inbounds for i in 1:nbits      # mutual information for every bit position 
        for j in 1:2, k in 1:2      # joint prob mass from counter C
            P[j,k] = C[i,j,k]/nelements
        end
        M[i] = mutual_information(P)
    end

    # remove information that is insignificantly different from a random 50/50
    if set_zero_insignificant
        set_zero_insignificant!(M,nelements,confidence)                        
    end

    return M
end

"""
    R = redundancy(A::AbstractArray{T},B::AbstractArray{T}) where {T<:Union{Integer,AbstractFloat}}

Bitwise redundancy of two arrays A,B. Redundancy is a normalised measure of the mutual information:
1 for always identical/opposite bits, 0 for no mutual information."""
function redundancy(A::AbstractArray{T},
                    B::AbstractArray{T}) where {T<:Union{Integer,AbstractFloat}}
    
    M = mutual_information(A,B)     # mutual information
    HA = bitcount_entropy(A)        # entropy of A
    HB = bitcount_entropy(B)        # entropy of B
    
    R = ones(size(M)...)            # allocate redundancy R
    
    for i in eachindex(M)           # loop over bit positions
        HAB = HA[i]+HB[i]           # sum of entropies of A,B
        if HAB > 0                  # entropy = 0 means A,B are fully redundant
            R[i] = 2*M[i]/HAB       # symmetric redundancy
        end
    end

    return R
end

# """Mutual bitwise information of the elements in input arrays A,B.
# A and B have to be of same size and eltype."""
# function bitinformation(A::AbstractArray{T},
#                         B::AbstractArray{T},
#                         n::Int) where {T<:Union{Integer,AbstractFloat}}
    
#     @assert size(A) == size(B)
#     nelements = length(A)
#     nbits = 8*sizeof(T)

#     # array of counters, first dim is from last bit to first
#     C = [zeros(Int,2^min(i,n+1),2) for i in nbits:-1:1]

#     for (a,b) in zip(A,B)   # run through all elements in A,B pairwise
#         bitcount!(C,a,b,n)  # count the bits and update counter array C
#     end

#     # P is the join probabilities mass function
#     P = [C[i]/nelements for i in 1:nbits]
#     M = [mutual_information(p) for p in P]
    
#     # filter out rounding errors
#     M[isapprox.(M,0,atol=10eps(Float64))] .= 0
#     return M
# end

# """Update counter array of size nbits x 2 x 2 for every 
# 00|01|10|11-bitpairing in a,b.""" 
# function bitcount!(C::Array{Int,3},a::T,b::T) where {T<:AbstractFloat}
#     uia = reinterpret(Base.uinttype(T),a)
#     uib = reinterpret(Base.uinttype(T),b)
#     bitcount!(C,uia,uib)
# end

# """Update counter array of size nbits x 2 x 2 for every 
# 00|01|10|11-bitpairing in a,b.""" 
# function bitcount!(C::Vector{Matrix{Int}},a::T,b::T,n::Int) where {T<:AbstractFloat}
#     uia = reinterpret(Base.uinttype(T),a)
#     uib = reinterpret(Base.uinttype(T),b)
#     bitcount!(C,uia,uib,n)
# end

# """Update counter array of size nbits x 2 x 2 for every 
# 00|01|10|11-bitpairing in a,b.""" 
# function bitcount!(C::Vector{Matrix{Int}},a::T,b::T,n::Int) where {T<:Integer}

#     nbits = 8*sizeof(T)

#     for i = nbits:-1:1
#         @boundscheck size(C[end-i+1],1) == 2^min(i,n+1) || throw(BoundsError()) 
#     end
    
#     maskb = one(T) << (nbits-1)
#     maska = reinterpret(T,signed(maskb) >> n)

#     for i in 1:nbits
#         j = 1+((a & maska) >>> max(nbits-n-i,0))
#         k = 1+((b & maskb) >>> (nbits-i))
#         C[i][j,k] += 1

#         maska >>>= 1    # shift through nbits
#         maskb >>>= 1
#     end
# end

# """Calculate the bitwise redundancy of two arrays A,B.
# Multi-bit predictor version which includes n lesser significant bit
# as additional predictors in A for the mutual information to account
# for round-to-nearest-induced carry bits. Redundancy is normalised 
# by the entropy of A. To be used for A being the reference array
# and B an approximation of it."""
# function redundancy(A::AbstractArray{T},
#                     B::AbstractArray{T},
#                     n::Int) where {T<:Union{Integer,AbstractFloat}}
#     mutinf = bitinformation(A,B,n)  # mutual information
#     HA = bitcount_entropy(A)        # entropy of A
#     R = mutinf./HA                  # redundancy (asymmetric)

#     R[iszero.(HA)] .= 0.0           # HA = 0 creates NaN
#     return R
# end