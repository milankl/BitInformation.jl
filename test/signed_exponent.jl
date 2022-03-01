@testset "Signed/biased exponent idempotence" begin
    for T in (Float16,Float32,Float64)
        for _ in 1:100
            A = randn(T,1)
            @test A == biased_exponent(signed_exponent(A))

            A = rand(T,1)
            @test A == biased_exponent(signed_exponent(A))

            A = 10*randn(T,1)
            @test A == biased_exponent(signed_exponent(A))
        end

        @test [zero(T)] == biased_exponent(signed_exponent([zero(T)]))
        @test_broken isnan(biased_exponent(signed_exponent([T(NaN)]))[1])
    end
end