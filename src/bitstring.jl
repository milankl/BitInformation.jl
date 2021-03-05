"""Bitstring function with a split-mode that splits the bitstring into
sign, exponent and significant bits."""
function Base.bitstring(x::Float16,mode::Symbol)
    if mode == :split
        bstr = bitstring(x)
        return "$(bstr[1]) $(bstr[2:6]) $(bstr[7:end])"
    else
        bitstring(x)
    end
end

"""Bitstring function with a split-mode that splits the bitstring into
sign, exponent and significant bits."""
function Base.bitstring(x::Float32,mode::Symbol)
    if mode == :split
        bstr = bitstring(x)
        return "$(bstr[1]) $(bstr[2:9]) $(bstr[10:end])"
    else
        bitstring(x)
    end
end

"""Bitstring function with a split-mode that splits the bitstring into
sign, exponent and significant bits."""
function Base.bitstring(x::Float64,mode::Symbol)
    if mode == :split
        bstr = bitstring(x)
        return "$(bstr[1]) $(bstr[2:12]) $(bstr[13:end])"
    else
        bitstring(x)
    end
end
