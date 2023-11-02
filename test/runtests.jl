using Test, InMAPSRM
using Meshes

@testset "Test InMAPSRM" begin
    @testset "Test cell data access" begin
        @test get_isrm_cell_data("MortalityRate") isa Vector
        cell_data = get_isrm_cell_data(["MortalityRate", "NOxDryDep"], geometry_lonlat = true)
        @test cell_data.MortalityRate isa Vector{<:Number}
        @test cell_data.NOxDryDep isa Vector{<:Number}
        @test cell_data.geometry isa Vector{Box{2, Float64}}
        @test cell_data.geometry_lonlat isa Vector{Quadrangle{2, Float64}}
    end
    @testset "Test SRM access" begin
        srm = SRM("PrimaryPM25")
        @test srm isa Array{Float32, 3}
        sparse_srm = SparseSRM(srm, [5000, 10000], [1,2])
        @test sparse_srm isa AbstractArray{Float32, 3}

        emis_srm =  compute_receptor_emis(srm, 5000, 1, 1.0)
        @test emis_srm isa Vector{Float64}
        @test length(emis_srm) == NSR

        emis_sparse = compute_receptor_emis(srm, 5000, 1, 1.0)
        @test emis_sparse isa Vector{Float64}
        @test length(emis_sparse) == NSR
        
        @test emis_sparse ≈ emis_srm

        emis_srm =  compute_receptor_emis(srm, [5000, 10000], [1,2], [1.0, 2.0])
        @test emis_srm isa Vector{Float64}
        @test length(emis_srm) == NSR

        emis_sparse = compute_receptor_emis(srm, [5000, 10000], [1,2], [1.0,2.0])
        @test emis_sparse isa Vector{Float64}
        @test length(emis_sparse) == NSR
        
        @test emis_sparse ≈ emis_srm
    end
end