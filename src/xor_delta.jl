"""Bitwise XOR delta. Elements include A are XORed with the previous one. The
first element is left unchanged.
E.g. [0b0011,0b0010] -> [0b0011,0b0001] """
function xor_delta!(A::Array{T,1}) where {T<:Unsigned}
    a = A[1]
    @inbounds for i in 2:length(A)
        b = A[i]
        A[i] = a ⊻ b
        a = b
   end
end

"""Undo bitwise XOR delta. Elements include A are XORed again to reverse xor_delta.
E.g. [0b0011,0b0001] -> [0b0011,0b0010] """
function unxor_delta!(A::Array{T,1}) where {T<:Unsigned}
    a = A[1]
    @inbounds for i in 2:length(A)
        b = A[i]
        a = a ⊻ b
        A[i] = a
   end
end

"""Bitwise XOR delta. Elements include A are XORed with the previous one. The
first element is left unchanged.
E.g. [0b0011,0b0010] -> [0b0011,0b0001]. """
function xor_delta(A::Array{T,1}) where {T<:Unsigned}
   B = copy(A)
   xor_delta!(B)
   return B
end

"""Undo bitwise XOR delta. Elements include A are XORed again to reverse xor_delta.
E.g. [0b0011,0b0001] -> [0b0011,0b0010] """
function unxor_delta(A::Array{T,1}) where {T<:Unsigned}
    B = copy(A)
    unxor_delta!(B)
    return B
end

"""Bitwise XOR delta. Elements include A are XORed with the previous one. The
first element is left unchanged.
E.g. [0b0011,0b0010] -> [0b0011,0b0001]. """
function xor_delta(::Type{UIntT},A::Array{T,1}) where {UIntT<:Unsigned,T<:AbstractFloat}
   B = reinterpret.(UIntT,A)
   xor_delta!(B)
   return reinterpret.(T,B)
end

"""Undo bitwise XOR delta. Elements include A are XORed again to reverse xor_delta.
E.g. [0b0011,0b0001] -> [0b0011,0b0010] """
function unxor_delta(::Type{UIntT},A::Array{T,1}) where {UIntT<:Unsigned,T<:AbstractFloat}
   B = reinterpret.(UIntT,A)
   unxor_delta!(B)
   return reinterpret.(T,B)
end

"""Bitwise XOR delta. Elements include A are XORed with the previous one. The
first element is left unchanged.
E.g. [0b0011,0b0010] -> [0b0011,0b0001]. """
xor_delta(A::Array{T,1}) where {T<:AbstractFloat} = xor_delta(whichUInt(T),A)

"""Undo bitwise XOR delta. Elements include A are XORed again to reverse xor_delta.
E.g. [0b0011,0b0001] -> [0b0011,0b0010] """
unxor_delta(A::Array{T,1}) where {T<:AbstractFloat} = unxor_delta(whichUInt(T),A)
