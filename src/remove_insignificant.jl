"""
    p₁ = binom_confidence(n::Int,c::Real)

Returns the probability `p₁` of successes in the binomial distribution (p=1/2) of
`n` trials with confidence `c`.

# Example
At c=0.95, i.e. 95% confidence, n=1000 tosses of 
a coin will yield not more than
```julia
julia> p₁ = BitInformation.binom_confidence(1000,0.95)
0.5309897516152281
```
about 53.1% heads (or tails)."""
function binom_confidence(n::Int,c::Real)
    p = 0.5 + quantile(Normal(),1-(1-c)/2)/(2*sqrt(n))
    return min(1.0,p)   # cap probability at 1 (only important for n small)
end

"""
    Hf = binom_free_entropy(n::Int,c::Real,base::Real=2)

Returns the free entropy `Hf` associated with `binom_confidence`."""
function binom_free_entropy(n::Int,c::Real,base::Real=2)
    p = binom_confidence(n,c)
    return 1 - entropy([p,1-p],base)
end

```
    set_zero_insignificant!(H::Vector,nelements::Int,confidence::Real)

Remove binary information in the vector `H` of entropies that is insignificantly
different from a random 50/50 by setting it to zero.```
function set_zero_insignificant!(H::Vector,nelements::Int,confidence::Real)
    Hfree = binom_free_entropy(nelements,confidence)    # free entropy of random 50/50 at trial size
                                                        # get chance p for 1 (or 0) from binom distr
    @inbounds for i in eachindex(H)
        H[i] = H[i] <= Hfree ? 0 : H[i]                 # set zero what's insignificant
    end                          
    return H
end