@testset "Permute arrays" begin
    A = rand(3,4,5,6,7,8)
    @test A == BitInformation.permute_dim_forward(A,1)

    A1 = BitInformation.permute_dim_forward(A,2)
    A1 = BitInformation.permute_dim_forward(A1,6)
    @test A == A1

    A2 = BitInformation.permute_dim_forward(A,3)
    A2 = BitInformation.permute_dim_forward(A2,5)
    @test A == A2

    A3 = BitInformation.ermute_dim_forward(A,4)
    A3 = BitInformation.permute_dim_forward(A3,4)
    @test A == A3
end