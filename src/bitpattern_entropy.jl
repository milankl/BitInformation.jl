"""Calculate the bitpattern entropy for an array A by reinterpreting the elements
as UInts and sorting them to avoid creating a histogram."""
function bitpattern_entropy(A::AbstractArray{T},base::Real=2) where T
    return bitpattern_entropy!(copy(A),base)  # copy of array to avoid in-place changes to A
end

"""Calculate the bitpattern entropy for an array A by reinterpreting the elements
as UInts and sorting them to avoid creating a histogram. In-place version of bitpattern_entropy."""
function bitpattern_entropy!(A::AbstractArray{T},base::Real=2) where T

    # reinterpret to UInt then sort in-place for minimal memory allocation
    sort!(reinterpret(Base.uinttype(T),vec(A)))
    n = length(A)

    E = 0.0     # entropy
    m = 1       # counter, start with 1 as only bitwise-same elements are counted

    for i in 1:n-1
        @inbounds if A[i] == A[i+1]     # check whether next entry belongs to the same bin in histogram
            m += 1                      # increase counter
        else
            p = m/n                     # probability/frequency of ith bit pattern
            E -= p*log(p)               # entropy contribution
            m = 1                       # start with 1, A[i+1] is already 1st element of next bin
        end
    end

    p = m/n         # complete loop for last bin
    E -= p*log(p)   # entropy contribution of last bin
    E /= log(base)  # convert to given base, 2 i.e. [bit] by default

    return E
end