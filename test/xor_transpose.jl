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