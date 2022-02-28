"""Bitstring function with a split-mode that splits the bitstring into
sign, exponent and significant bits."""
function Base.bitstring(x::T,mode::Symbol) where {T<:AbstractFloat}
    if mode == :split
        bstr = bitstring(x)
        n = Base.exponent_bits(T)
        return "$(bstr[1]) $(bstr[2:n+1]) $(bstr[n+2:end])"
    else
        bitstring(x)
    end
end