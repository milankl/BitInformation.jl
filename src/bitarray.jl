function bitarray(A::AbstractArray{T}) where T
    nbits = 8*sizeof(T)         # number of bits in T
    UIntN = Base.uinttype(T)    # UInt type corresponding to T

    # allocate BitArray with additional dimension for the bits
    B = BitArray(undef,nbits,size(A)...)
    indices = CartesianIndices(A)

    for i in eachindex(A)                   # every element in A
        a = reinterpret(UIntN,A[i])         # as UInt
        mask = UIntN(1)                     # mask to isolate jth bit
        for j in 0:nbits-1                  # loop from less to more significant bits
            bit = (a & mask) >> j           # isolate bit (=true/false)
            B[nbits-j,indices[i]] = bit     # set BitArray entry to isolated bit in A
            mask <<= 1                      # shift mask towards more significant bit
        end
    end
    return B
end

function bitmap(A::AbstractMatrix;dim::Int=1)
    @assert dim in (1,2) "dim has to be 1 or 2, $dim provided."

    #TODO bitordering for dim=2 is currently off
    n,m = size(A)    
    B = bitarray(A)
    nbits,_ = size(B)
    Br = reshape(B,nbits*n,:)
    Br = dim == 1 ? Br : Br'

    return Br
end


