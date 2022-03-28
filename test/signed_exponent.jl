@testset "Signed/biased exponent idempotence" begin
    for T in (Float16,Float32,Float64)
        for _ in 1:100
            A = [reinterpret(T,rand(Base.uinttype(T)))]
            # call functions with array but evaluated only the element of it
            # with === to allow to nan equality too
            @test A[1] === biased_exponent(signed_exponent(A))[1]
            
            # and for scalars
            a = reinterpret(T,rand(Base.uinttype(T)))
            @test a === biased_exponent(signed_exponent(a))
        end

        # special cases 0, NaN, Inf
        @test [zero(T)] == biased_exponent(signed_exponent([zero(T)]))
        @test isnan(biased_exponent(signed_exponent([T(NaN)]))[1])
        @test isinf(biased_exponent(signed_exponent([T(Inf)]))[1])   
    end
end