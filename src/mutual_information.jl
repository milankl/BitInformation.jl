function mutual_information(p::AbstractArray{T,2},base::Real=2) where T
    @assert sum(p) ≈ one(T)
    @assert all(p .>= zero(T))
    
    na,nb = size(p)
    
    mpa = sum(p,dims=2)
    mpb = sum(p,dims=1)
    
    M = zero(T)
    for j in 1:nb
        for i in 1:na
            if p[i,j] > zero(T)
                M += p[i,j]*log(p[i,j]/mpa[i]/mpb[j])
            end
        end
    end

    M /= log(base)
end

function bitinformation(A::AbstractArray{T},
                        B::AbstractArray{T}) where {T<:Union{Integer,AbstractFloat}}
    
    @assert size(A) == size(B)
    nelements = length(A)
    nbits = 8*sizeof(T)

    # array of counters, first dim is from last bit to first
    C = zeros(Int,nbits,2,2)

    for (a,b) in zip(A,B)
        bitcount!(C,a,b)
    end

    # P is the join probabilities mass function
    # invert the order of C's first dimension
    P = [C[i,:,:]/nelements for i in nbits:-1:1]
    M = [mutual_information(p) for p in P]
    return M
end

function bitcount!(C::Array{Int,3},a::T,b::T) where {T<:AbstractFloat}
    uia = reinterpret(Base.uinttype(T),a)
    uib = reinterpret(Base.uinttype(T),b)
    bitcount!(C,uia,uib)
end

function bitcount!(C::Array{Int,3},a::T,b::T) where {T<:Union{Unsigned,Signed}}
    nbits = 8*sizeof(T)
    mask = one(T)
    for i in 1:nbits
        j = 1+((a & mask) >>> (i-1))
        k = 1+((b & mask) >>> (i-1))
        C[i,j,k] += 1
        mask <<= 1
    end
end