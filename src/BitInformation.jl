module BitInformation

    # ROUNDING
    export shave, set_one, groom, halfshave, 
        shave!, set_one!, groom!, halfshave!, round!

    # TRANSFORMATIONS
    export bittranspose, bitbacktranspose,
        xor_delta, unxor_delta, xor_delta!, unxor_delta!,
        signed_exponent, biased_exponent,
        bitarray
    
    # INFORMATION
    export bitinformation, mutual_information, redundancy, bitpattern_entropy,
        bitcount, bitcount_entropy, bitpaircount, bit_condprobability,
        bit_condentropy

    import StatsBase: entropy
    import Distributions: quantile, Normal

    # Base method extensions
    include("uint_types.jl")

    # print and conversions
    include("bitstring.jl")
    include("bitarray.jl")

    # transformations
    include("bittranspose.jl")
    include("xor_delta.jl")
    include("signed_exponent.jl")

    # rounding
    include("round_nearest.jl")
    include("shave_set_groom.jl")
    
    # information
    include("permutations.jl")
    include("bitcount.jl")
    include("mutual_information.jl")
    include("bitpattern_entropy.jl")
    include("remove_insignificant.jl")
end
