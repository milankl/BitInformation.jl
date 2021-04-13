using Distributions: quantile, Normal

"""
```
binom_confidence(n::int,c::Real)
```
Returns the probability `p₁` of successes in the binomial distribution (p=1/2) of
`n` trials with confidence `c`.

# Example
At c=0.95, i.e. 95% confidence, n=1000 tosses of 
a coin will yield not more than
```
julia> p₁ = binom_confidence(1000,0.95)
0.5309897516152281
```
about 53.1% heads (or tails)."""
function binom_confidence(n::Int,c::Real)
    return 0.5 + quantile(Normal(),1-(1-c)/2)/(2*sqrt(n))
end


