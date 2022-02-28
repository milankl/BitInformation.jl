@testset "Bitstring with split" begin
    for T in (Float16,Float32,Float64)
        for _ in 1:30
            r = randn()
            bs_split = bitstring(r,:split)
            bs = bitstring(r)
            @test bs == prod(split(bs_split," "))
        end
    end

    # some individual values too
    @test bitstring(Float16( 0),:split) == "0 00000 0000000000"
    @test bitstring(Float16( 1),:split) == "0 01111 0000000000"
    @test bitstring(Float16(-1),:split) == "1 01111 0000000000"
    @test bitstring(Float16( 2),:split) == "0 10000 0000000000"

    @test bitstring( 0f0,:split) == "0 00000000 00000000000000000000000"
    @test bitstring( 1f0,:split) == "0 01111111 00000000000000000000000"
    @test bitstring(-1f0,:split) == "1 01111111 00000000000000000000000"
    @test bitstring( 2f0,:split) == "0 10000000 00000000000000000000000"

    @test bitstring( 0.0,:split) ==
        "0 00000000000 0000000000000000000000000000000000000000000000000000"
    @test bitstring( 1.0,:split) ==
        "0 01111111111 0000000000000000000000000000000000000000000000000000"
    @test bitstring(-1.0,:split) ==
        "1 01111111111 0000000000000000000000000000000000000000000000000000"
    @test bitstring( 2.0,:split) ==
        "0 10000000000 0000000000000000000000000000000000000000000000000000" 
end