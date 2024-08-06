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
    H = bitcount_entropy(rand(UInt8,N))
    @test all(isapprox.(H,ones(8),rtol=5e-4))

    H = bitcount_entropy(rand(UInt16,N))
    @test all(isapprox.(H,ones(16),rtol=5e-4))

    H = bitcount_entropy(rand(UInt32,N))
    @test all(isapprox.(H,ones(32),rtol=5e-4))

    H = bitcount_entropy(rand(UInt64,N))
    @test all(isapprox.(H,ones(64),rtol=5e-4))

    # also for random floats
    H = bitcount_entropy(rand(N))
    @test H[1:5] == zeros(5)    # first bits never change
    @test all(isapprox.(H[16:55],ones(40),rtol=1e-4))
end

import BitInformation: bitpair_count

@testset "Bit pair count" begin
    for T in (Float16,Float32,Float64)
        N = 10_000
        A = rand(T,N)
        C1 = bitpair_count(A,A)     # count bitpairs with 2 equiv arrays
        C2 = bitcount(A)            # compare to bits counted in that array

        nbits = 8*sizeof(T)
        for i in 1:nbits
            @test C1[i,1,2] == 0    # no 01 pair for bitpair_count(A,A)
            @test C1[i,2,1] == 0    # no 10
            @test C1[i,1,1] + C1[i,2,2] == N    # 00 + 11 are all cases = N
            @test C1[i,2,2] == C2[i]            # 11 is the same as bitcount(A)
        end

        Auint = reinterpret(Base.uinttype(T),A)
        Buint = .~Auint                         # flip all bits in A

        C3 = bitpair_count(Auint,Auint)
        @test C1 == C3                          # same when called with uints

        C4 = bitpair_count(Auint,Buint)
        for i in 1:nbits
            @test C4[i,1,2] + C4[i,2,1] == N    # 01, 10 are all cases = N
            @test C1[i,1,1] == C4[i,1,2]        # 00 before is now 01
            @test C1[i,2,2] == C4[i,2,1]        # 11 before is now 10
            @test C4[i,1,1] == 0                # no 00
            @test C4[i,2,2] == 0                # no 11
        end
    end
end