using BitInformation
using Test

@testset "Bitpattern entropy" begin
    for N in [100,1000,10000,100000]
        # every bitpattern is only hit once, hence entropy = log2(N)
        @test isapprox(log2(N),bitpattern_entropy(rand(Float32,N)),atol=1e-1)
        @test isapprox(log2(N),bitpattern_entropy(rand(Float64,N)),atol=1e-1)
    end

    N = 1000_000   # more bitpattern than there are in 8 or 16-bit
    @test isapprox(16.0,bitpattern_entropy(rand(UInt16,N)),atol=1e-1)
    @test isapprox(16.0,bitpattern_entropy(rand(Int16,N)),atol=1e-1)

    @test isapprox(8.0,bitpattern_entropy(rand(UInt8,N)),atol=1e-1)
    @test isapprox(8.0,bitpattern_entropy(rand(Int8,N)),atol=1e-1)
end

@testset "XOR reversibility UInt" begin
    for T in (UInt8,UInt16,UInt32,UInt64)
        A = rand(T,1000)
        @test A == unxor_delta(xor_delta(A))
        @test A == xor_delta(unxor_delta(A))

        B = copy(A)
        xor_delta!(A)
        unxor_delta!(A)
        @test B == A

        unxor_delta!(A)
        xor_delta!(A)
        @test B == A
    end
end

@testset "XOR reversibility Float" begin
    for T in (Float32,Float64)
        A = rand(T,1000)
        @test A == unxor_delta(xor_delta(A))
        @test A == xor_delta(unxor_delta(A))
    end
end

@testset "UInt: Backtranspose of transpose" begin
    for T in (UInt8,UInt16,UInt32,UInt64)
        for s  in (10,999,2048,9999,123123)
            A = rand(T,s)
            @test A == bitbacktranspose(bittranspose(A))
        end
    end
end

@testset "Float: Backtranspose of transpose" begin
    for T in (Float32,Float64)
        for s in (10,999,2048,9999,123123)
            A = rand(T,s)
            @test A == bitbacktranspose(bittranspose(A))
        end
    end
end

@testset "N-dimensional arrays" begin
    A = rand(UInt32,123,234)
    @test A == bitbacktranspose(bittranspose(A))

    A = rand(UInt32,12,23,34)
    @test A == bitbacktranspose(bittranspose(A))

    A = rand(Float32,123,234)
    @test A == bitbacktranspose(bittranspose(A))

    A = rand(Float32,12,23,34)
    @test A == bitbacktranspose(bittranspose(A))
end

@testset "Bitcount" begin
    @test bitcount(UInt8[1,2,4,8,16,32,64,128]) == ones(8)
    @test bitcount(collect(0x0000:0xffff)) == 2^15*ones(16)

    N = 100_000
    c = bitcount(rand(N))
    @test c[1] == 0         # sign always 0
    @test c[2] == 0         # first expbit always 0, i.e. U(0,1) < 1
    @test c[3] == N         # second expont always 1

    @test all(isapprox.(c[15:50],N/2,rtol=1e-1))
end

@testset "Bitcountentropy" begin

    # test the PRNG on uniformity
    N = 100_000
    H = bitcountentropy(rand(UInt8,N))
    @test all(isapprox.(H,ones(8),rtol=1e-4))

    H = bitcountentropy(rand(UInt16,N))
    @test all(isapprox.(H,ones(16),rtol=1e-4))

    H = bitcountentropy(rand(UInt32,N))
    @test all(isapprox.(H,ones(32),rtol=1e-4))

    H = bitcountentropy(rand(UInt64,N))
    @test all(isapprox.(H,ones(64),rtol=1e-4))

    # also for random floats
    H = bitcountentropy(rand(N))
    @test H[1:5] == zeros(5)    # first bits never change
    @test all(isapprox.(H[16:55],ones(40),rtol=1e-4))
end

@testset "Bitinformation random" begin
    N = 100_000
    A = rand(UInt64,N)
    @test all(bitinformation(A) .< 1e-4)

    A = rand(Float32,N)
    bi = bitinformation(A)
    @test all(bi[1:4] .== 0.0) # the first bits are always 0011
    sort!(A)
    @test sum(bitinformation(A)) > 12
end

@testset "Bitinformation in chunks" begin
    N = 1000
    Nhalf = N ÷ 2
    A = rand(UInt32,N)
    n11,npair1,N1 = bitcount(A[1:Nhalf-1]),bitpaircount(A[1:Nhalf]),Nhalf
    n12,npair2,N2 = bitcount(A[Nhalf:end-1]),bitpaircount(A[Nhalf:end]),Nhalf-1
    @test bitinformation(n11+n12,npair1+npair2,N1+N2) == bitinformation(A)
end

@testset "Bitinformation dimensions" begin
    A = rand(Float32,30,40,50)
    @test bitinformation(A) == bitinformation(A,dims=1)
    
    # check that the :all_dimensions flag is 
    bi1 = bitinformation(A,dims=1)
    bi2 = bitinformation(A,dims=2)
    bi3 = bitinformation(A,dims=3)
    @test bitinformation(A,:all_dimensions) == ((bi1 .+ bi2 .+ bi3)/3)

    # check that there is indeed more information in the sorted dimensions
    sort!(A,dims=2)
    @test sum(bitinformation(A,dims=1)) < sum(bitinformation(A,dims=2))
end