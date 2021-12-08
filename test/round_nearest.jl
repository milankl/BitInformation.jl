using Test

@testset "iseven isodd" begin
    # check sign bits
    @test iseven(1f0,-8)
    @test isodd(-1f0,-8)
    @test iseven(1.0,-11)
    @test isodd(-1.0,-11)
    @test iseven(Float16(1),-5)
    @test isodd(Float16(-1),-5)

    @test isodd(1.5f0,1)
    @test isodd(1.5,1)
    @test isodd(Float16(1.5),1)

    @test iseven(1.25f0,1)
    @test iseven(1.25,1)
    @test iseven(Float16(1.25),1)

    @test isodd(1.25f0,2)
    @test isodd(1.25,2)
    @test isodd(Float16(1.25),2)
end

@testset "Zero rounds to zero" begin
    for T in [Float16,Float32,Float64]
        for k in -5:50
            A = zeros(T,2,3)
            Ar = round(A,k)
            @test A == Ar
            @test zero(T) == round(zero(T),k)
        end
    end
end

@testset "one rounds to one" begin
    for T in [Float16,Float32,Float64]
        for k in 0:50
            A = ones(T,2,3)
            Ar = round(A,k)
            @test A == Ar
            @test one(T) == round(one(T),k)
        end
    end
end

@testset "minus one rounds to minus one" begin
    for T in [Float16,Float32,Float64]
        for k in 0:50
            A = -ones(T,2,3)
            Ar = round(A,k)
            @test A == Ar
            @test -one(T) == round(-one(T),k)
        end
    end
end

@testset "No rounding for keepbits=10,23,52" begin
    for (T,k) in zip([Float16,Float32,Float64],
                        [11,24,53])
        A = rand(T,200,300)
        Ar = round(A,k)
        @test A == Ar

        # and a single one
        r = rand(T)
        @test r == round(r,k)
    end
end

@testset "Approx equal for keepbits=5,10,25" begin
    for (T,k) in zip([Float16,Float32,Float64],
                        [5,10,25])
        A = rand(T,200,300)
        Ar = round(A,k)
        @test A ≈ Ar

        # and a single one
        r = rand(T)
        @test r ≈ round(r,k)
    end
end

@testset "Idempotence" begin
    for T in [Float16,Float32,Float64]
        for k in 0:20
            A = rand(T,200,300)
            Ar = round(A,k)
            Ar2 = round(A,k)
            @test Ar == Ar2
        end
    end
end

@testset "Tie to even" begin

    for T in [Float16,Float32,Float64]

        @test round(1.5f0,0) == T(2)
    
        @test round(1.25f0,1) == T(1)
        @test round(1.5f0,1) == T(1.5)
        @test round(1.75f0,1) == T(2)

        @test round(1.125f0,2) == T(1)
        @test round(1.375f0,2) == T(1.5)
        @test round(1.625f0,2) == T(1.5)
        @test round(1.875f0,2) == T(2)
    end

    for k in 1:10
        m = 0x8000_0000 >> (9+k)
        x = reinterpret(UInt32,one(Float32)) + m
        x = reinterpret(Float32,x)
        @test 1f0 == round(x,k)
    end

    # for T in [Float16,Float32,Float64]
    #     for k in 1:20
    #         x = randn(T)
    #         xr1 = round(x,k+1)
    #         xr = round(xr1,k)

    #         if iseven(xr,k)

    #     end
    # end
end

@testset "Round to nearest?" begin
    N = 1000
    for _ in 1:N
        for (T,UIntT) in zip([Float16,Float32,Float64],
                                [UInt16,UInt32,UInt64])
            for k in 1:9
                x = randn(T)
                xr = round(x,k)

                ulp = Base.sign_mask(T) >> (Base.exponent_bits(T)+k)
                next_xr = reinterpret(T,reinterpret(UIntT,xr) + ulp)
                prev_xr = reinterpret(T,reinterpret(UIntT,xr) - ulp)

                @test abs(next_xr - x) >= abs(xr - x)
                @test abs(prev_xr - x) >= abs(xr - x)
            end
        end
    end 
end