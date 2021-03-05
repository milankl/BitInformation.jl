"""Calculate the bitpattern entropy in base `base` for all elements in array A."""
function bitpattern_entropy(A::AbstractArray,base::Real=2)
    nbits = sizeof(eltype(A))*8
    T = whichUInt(nbits)
    return bitpattern_entropy(T,A,base)
end

"""Calculate the bitpattern entropy in base `base` for all elements in array A.
In place version that will sort the array."""
function bitpattern_entropy!(A::AbstractArray,base::Real=2)
    nbits = sizeof(eltype(A))*8
    T = whichUInt(nbits)
    return bitpattern_entropy!(T,A,base)
end

"""Calculate the bitpattern entropy for an array A by reinterpreting the elements
as UInts and sorting them to avoid creating a histogram."""
function bitpattern_entropy(::Type{T},A::AbstractArray,base::Real) where {T<:Unsigned}
    return bitpattern_entropy!(T,copy(A),base)
end

"""Calculate the bitpattern entropy for an array A by reinterpreting the elements
as UInts and sorting them to avoid creating a histogram.
In-place version of bitpattern_entropy."""
function bitpattern_entropy!(::Type{T},A::AbstractArray,base::Real) where {T<:Unsigned}

    # reinterpret to UInt then sort to avoid allocating a histogram
    # in-place ver
    sort!(reinterpret(T,vec(A)))    # TODO maybe think of an inplace version?
    n = length(A)

    E = 0.0     # entropy
    m = 1       # counter

    for i in 1:n-1
        @inbounds if A[i] == A[i+1]     # check whether next entry belongs to the same bin in histogram
            m += 1
        else
            p = m/n
            E -= p*log(p)
            m = 1
        end
    end

    p = m/n         # complete for last bin
    E -= p*log(p)

    # convert to given base, 2 i.e. [bit] by default
    E /= log(base)

    return E
end