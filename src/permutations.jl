"""
    permute_dim_forward(A::AbstractArray,dim::Int)

Permute array `A` such that dimension `dim` is the first dimension. For `A` being a matrix this
is equivalent to a transpose, for `size(A) = (m,n,o,p,q)` and `dim=3` the returned PermutedDimsArray
is of size `(o,p,q,m,n)`."""
function permute_dim_forward(A::AbstractArray,dim::Int)
    if dim > 1                                  # no permutation for dim==1
        permu = collect(1:ndims(A))             # permutation
        perm0 = vcat(permu[2:end],permu[1])     # used to permute permu
        for _ in 1:dim-1                        # create permutation array
            permute!(permu,perm0)
        end
        return PermutedDimsArray(A,permu)       # permute A, such that desired dim is 1st dim
    else
        return A                                # return original array if dim==1
    end
end