@testset "Bitinformation random" begin
    N = 10_000

    for T in (UInt8,UInt16,UInt32,UInt64)
        A = rand(T,N)
        @test all(bitinformation(A,set_zero_insignificant=false) .< 1e-3)
    end

    for T in (Float16,Float32,Float64)
        A = rand(T,N)

        # increase confidence to filter out more information for reliable tests...
        # i.e. lower the risk of false positives
        bi = bitinformation(A,confidence=0.9999)    

        # no bit should contain information, insignificant
        # information should be filtered out
        @test all(bi .== 0.0)

        sort!(A)                            # introduce some information via sorting
        @test sum(bitinformation(A)) > 9    # some bits of information (guessed)
    end
end

@testset "Bitinformation dimensions" begin

    for T in (Float16,Float32,Float64)
        A = rand(T,30,40,50)
        @test bitinformation(A) == bitinformation(A,dim=1)
        
        bi1 = bitinformation(A,dim=1)
        bi2 = bitinformation(A,dim=2)
        bi3 = bitinformation(A,dim=3)

        nbits = 8*sizeof(T)
        for i in 1:nbits
            @test bi1[i] ≈ bi2[i] atol=1e-3
            @test bi2[i] ≈ bi3[i] atol=1e-3
            @test bi1[i] ≈ bi3[i] atol=1e-3
        end

        # check that there is indeed more information in the sorted dimensions
        sort!(A,dims=2)
        @test sum(bitinformation(A,dim=1)) < sum(bitinformation(A,dim=2))
    end
end

@testset "Mutual information" begin
    N = 10_000

    # equal probabilities for 00|01|10|11
    @test 0.0 == mutual_information([0.25 0.25;0.25 0.25])

    # every 0 or 1 in A is also a 0 or 1 in B
    @test 1.0 == mutual_information([0.5 0.0;0.0 0.5])

    # as before but more 1s means a lower entropy
    @test entropy([0.25,0.75],2) == mutual_information([0.25 0.0;0.0 0.75])

    # every bit is inverted
    @test 1.0 == mutual_information([0.0 0.5;0.5 0.0])

    # two independent arrays
    for T in (UInt8,UInt16,UInt32,UInt64,Float16,Float32,Float64)
        mutinf = mutual_information(rand(T,N),rand(T,N))
        for m in mutinf
            @test isapprox(0,m,atol=2e-3)
        end
    end

    # mutual information of identical arrays
    # for 0,1 occuring exactly 50/50 this is 1bit
    # but so in practice slightly lower for rand(UInt),
    # or clearly lower for low entropy bits in Float16/32/64
    # but identical to the bitcount_entropy (up to rounding errors)
    for T in (UInt8,UInt16,UInt32,UInt64,Float16,Float32,Float64)
        R = rand(T,N)
        mutinf = mutual_information(R,R)
        @test mutinf ≈ bitcount_entropy(R)
    end
end

@testset "Redundancy" begin
    N = 10_000

    # No redundancy in independent arrays
    for T in (UInt8,UInt16,UInt32,UInt64)
        redun = redundancy(rand(T,N),rand(T,N))
        for r in redun
            @test isapprox(0,r,atol=2e-3)
        end
    end

    # no redundancy in the mantissa bits of rand
    for T in (Float16,Float32,Float64)
        redun = redundancy(rand(T,N),rand(T,N))
        for r in redun[end-Base.significand_bits(T):end]
            @test isapprox(0,r,atol=2e-3)
        end
    end

    # Full redundancy in identical arrays
    for T in (UInt8,UInt16,UInt32,UInt64,Float16,Float32,Float64)
        A = rand(T,N)
        H = bitcount_entropy(A)
        R = redundancy(A,A)
        for r in R
            @test r ≈ 1 atol=1e-3
        end
    end

    # Some artificially introduced redundancy PART I
    for T in (UInt8,UInt16,UInt32,UInt64)
        
        A = rand(T,N)
        B = copy(A)                 # B is A on every second entry
        B[1:2:end] .= rand(T,N÷2)   # otherwise independent

        # joint prob mass is therefore [0.375 0.125; 0.125 0.375]
        # at 50% bits are identical, at 50% they are independent
        # = 25% same, 25% opposite
        p = mutual_information([0.375 0.125;0.125 0.375])

        R = redundancy(A,B)
        for r in R
            @test r ≈ p rtol=2e-1
        end
    end

    # Some artificially introduced redundancy PART II
    for T in (UInt8,UInt16,UInt32,UInt64)
    
        A = rand(T,N)
        B = copy(A)                 # B is A on every fourth entry
        B[1:4:end] .= rand(T,N÷4)   # otherwise independent

        # joint prob mass is therefore [0.4375 0.0625; 0.0625 0.4375]
        # at 75% bits are identical, at 25% they are independent
        # = 12.5% same, 12.5% opposite
        p = mutual_information([0.4375 0.0625;0.0625 0.4375])

        R = redundancy(A,B)
        for r in R
            @test r ≈ p rtol=2e-1
        end
    end
end

@testset "Mutual information with shave/round" begin
    N = 10_000

    for T in (Float16,Float32,Float64)
        R = randn(T,N)
        for keepbit in [5,10,15]
            
            Rshaved = shave(R,keepbit)
            mutinf_shave = mutual_information(R,Rshaved)
            H_R = bitcount_entropy(R)
            H_Rs = bitcount_entropy(Rshaved)

            for (i,(s,hr,hrs)) in enumerate(zip(mutinf_shave,H_R,H_Rs))
                if i <= (1+Base.exponent_bits(T)+keepbit)
                    @test isapprox(s,hr,atol=1e-2)
                    @test isapprox(s,hrs,atol=1e-2)
                else
                    @test s == 0
                    @test hr > 0
                    @test hrs == 0
                end
            end
        end
    end
end

@testset "Masked arrays" begin
    for T in (Float16, Float32, Float64)
        A = rand(T, 30, 40)
        sort!(A, dims=1)

        # nothing is masked
        mask = BitArray(undef,30,40)
        fill!(mask,false)
        @test bitinformation(A) == bitinformation(A, mask)

        # half of the array is masked
        # use view to avoid masking only a deep copy through [] indexing
        fill!(@view(mask[:, 21:end]),true)   
        @test bitinformation(A[:, 1:20]) == bitinformation(A,mask)

        # half of the array is masked
        # use view to avoid masking only a deep copy through [] indexing
        fill!(mask,false)
        fill!(@view(mask[21:end, :]), true)
        @test bitinformation(A[1:20, :]) == bitinformation(A,mask)

        # mask every other value (should throw an error as no
        # adjacent entries are left)
        fill!(mask, false)
        mask[1:2:end, 2:2:end] .= true
        mask[2:2:end, 1:2:end] .= true
        @test_throws AssertionError bitinformation(A,mask)

        # check providing mask against providing a masked_value (mask is created internally)
        masked_value = convert(T, 1/4)
        A = rand(T, 30, 40)
        round!(A, 1)
        mask = A .== masked_value
        @test bitinformation(A, mask) == bitinformation(A; masked_value)

        # check that masked_value=NaN also works
        A[:, 2] .= NaN                       # put some NaNs somewhere
        mask = BitArray(undef,size(A)...)   # create corresponding mask
        fill!(mask,false)
        mask[:, 2] .= true
        @test bitinformation(A,mask) == bitinformation(A;masked_value=convert(T,NaN))

        # only 2 in first dimension
        dimss = ((2,), (2, 3), (2, 3, 4), (2, 3, 4, 5))
        for dims in dimss
            A = randn(T, dims...)
            @test bitinformation(A) == bitinformation(A, masked_value=T(999.))
        end

        # bitinformation of single element isn't possible should be caught 
        @test_throws AssertionError bitinformation(rand(T, 1))
        @test_throws AssertionError bitinformation(rand(T, 1, 1))
        @test_throws AssertionError bitinformation(rand(T, 1, 1, 1))
    end
end