@testset "Bit pattern entropy" begin
    for N in [100,1000,10000,100000]
        # every bit pattern is only hit once, hence entropy = log2(N)
        @test isapprox(log2(N),bitpattern_entropy(rand(Float32,N)),atol=1e-1)
        @test isapprox(log2(N),bitpattern_entropy(rand(Float64,N)),atol=1e-1)
    end

    N = 1000_000   # more bit pattern than there are in 8 or 16-bit
    @test isapprox(16.0,bitpattern_entropy(rand(UInt16,N)),atol=1e-1)
    @test isapprox(16.0,bitpattern_entropy(rand(Int16,N)),atol=1e-1)

    @test isapprox(8.0,bitpattern_entropy(rand(UInt8,N)),atol=1e-1)
    @test isapprox(8.0,bitpattern_entropy(rand(Int8,N)),atol=1e-1)
end