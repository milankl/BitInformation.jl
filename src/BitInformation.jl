module BitInformation

    export bittranspose, bitbacktranspose, shave, set_one, groom, halfshave
        kouzround, minpos, round!, xor_delta, unxor_delta, signed_exponent,
        bitinformation, mutual_information, redundancy, bitpattern_entropy,
        bitcount_entropy, bitpaircount, bitcondprobability

    import StatsBase.entropy

    include("which_uint.jl")
    include("bitstring.jl")
    include("bittranspose.jl")
    include("shave_set_groom.jl")
    include("round.jl")
    include("xor_delta.jl")
    include("signed_exponent.jl")
    include("bit_information.jl")
    include("mutual_information.jl")

end
