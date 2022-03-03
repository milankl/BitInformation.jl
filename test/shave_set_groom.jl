@testset "Zero shaves to zero" begin
    for T in [Float16,Float32,Float64]
        for k in -5:50
            A = zeros(T,2,3)
            Ar = shave(A,k)
            @test A == Ar
            @test zero(T) == round(zero(T),k)
        end
    end
end

@testset "one shaves to one" begin
    for T in [Float16,Float32,Float64]
        for k in 0:50
            A = ones(T,2,3)
            Ar = shave(A,k)
            @test A == Ar
            @test one(T) == round(one(T),k)
        end
    end
end

@testset "minus one shaves to minus one" begin
    for T in [Float16,Float32,Float64]
        for k in 0:50
            A = -ones(T,2,3)
            Ar = shave(A,k)
            @test A == Ar
            @test -one(T) == round(-one(T),k)
        end
    end
end

@testset "No (half)shaving/setting/grooming for keepbits=10,23,52" begin
    for (T,k) in zip([Float16,Float32,Float64],
                        [10,23,52])
        A = rand(T,200,300)
        Ar = shave(A,k)
        @test A == Ar

        Ar = halfshave(A,k)
        @test A == Ar

        Ar = set_one(A,k)
        @test A == Ar

        Ar = groom(A,k)
        @test A == Ar

        # and a single one
        r = rand(T)
        @test r == shave(r,k)
        @test r == halfshave(r,k)
        @test r == set_one(r,k)
    end
end

@testset "Approx equal for keepbits=8,15,35" begin
    for (T,k) in zip([Float16,Float32,Float64],
                        [8,15,35])
        A = rand(T,200,300)
        Ar = shave(A,k)
        @test A ≈ Ar

        Ar = halfshave(A,k)
        @test A ≈ Ar

        Ar = set_one(A,k)
        @test A ≈ Ar

        Ar = groom(A,k)
        @test A ≈ Ar

        # and a single one
        r = rand(T)
        @test r ≈ shave(r,k)
        @test r ≈ set_one(r,k)
        @test r ≈ halfshave(r,k)       
    end
end

@testset "Idempotence" begin
    for T in [Float16,Float32,Float64]
        for k in 0:20
            A = rand(T,200,300)
            Ar = shave(A,k)
            Ar2 = shave(Ar,k)
            @test Ar == Ar2

            Ar = halfshave(A,k)
            Ar2 = halfshave(Ar,k)
            @test Ar == Ar2

            Ar = set_one(A,k)
            Ar2 = set_one(Ar,k)
            @test Ar == Ar2

            Ar = groom(A,k)
            Ar2 = groom(Ar,k)
            @test Ar == Ar2
        end
    end
end

@testset "Shave/set = round towards/away from zero?" begin
    N = 1000
    for _ in 1:N
        for (T,UIntT) in zip([Float16,Float32,Float64],
                                [UInt16,UInt32,UInt64])
            for k in 1:9
                x = randn(T)
                xr = shave(x,k)
                @test abs(xr) <= abs(x)

                xr = set_one(x,k)
                @test abs(xr) >= abs(x)
            end
        end
    end 
end