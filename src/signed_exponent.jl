"""Converts the exponent bits of Float16,Float32 or Float64-arrays from its
conventional biased-form into a sign&magnitude representation. E.g.

julia> bitstring(10f0,:split)
"0 10000010 01000000000000000000000"

julia> bitstring.(signed_exponent([10f0]),:split)[1]
"0 00000011 01000000000000000000000"

In the former the exponent 3 is interpret from 0b10000010=130 via subtraction of
the exponent bias of Float32 = 127. In the latter the exponent is inferred from
sign bit (0) and a magnitude represetation 2^1 + 2^1 = 3.
"""
function signed_exponent!(A::Array{T}) where {T<:Union{Float16,Float32,Float64}}

    # sign&fraction mask
    sfmask = Base.sign_mask(T) | Base.significand_mask(T)
    emask = Base.exponent_mask(T)

    sbits = Base.significand_bits(T)
    bias  = Base.exponent_bias(T)
    ebits = Base.exponent_bits(T)-1

    for i in eachindex(A)
        ui = reinterpret(Unsigned,A[i])
        sf = ui & sfmask                    # sign & fraction bits
        e = ((ui & emask) >> sbits) - bias  # de-biased exponent
        eabs = e == -bias ? 0 : abs(e)      # for iszero(A[i]) e == -bias, set to 0
        esign = (e < 0 ? 1 : 0) << ebits    # determine sign of exponent
        esigned = ((esign | eabs) % typeof(ui)) << sbits    # concatentate exponent

        A[i] = reinterpret(T,sf | esigned)  # concatenate everything back together
    end
end

"""Convert the exponent bits into a sign&magnitude representation with
preallocation of a new array."""
function signed_exponent(A::Array{T}) where {T<:Union{Float16,Float32,Float64}}
    B = copy(A)
    signed_exponent!(B)
    return B
end