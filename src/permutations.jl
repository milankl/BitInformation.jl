"""
    permute_dim_forward(A::AbstractArray,dim::Int)

Permute array `A` such that dimension `dim` is the first dimension by circular shifting its dimensions.
Returns a `PermutedDimsArray`. For `A` being a matrix this is equivalent to a transpose, for more dimensions
the dimensions are shifted circular. E.g. An array of size `(3,4,5,6,7)` and `dim=3` will return a PermutedDimsArray
of size `(5,6,7,3,4)`."""
function permute_dim_forward(A::AbstractArray,dim::Int)
    A_ndims = ndims(A)
    @boundscheck dim <= A_ndims || throw(BoundsError)

    return PermutedDimsArray(A,circshift(1:A_ndims,-dim+1))
end