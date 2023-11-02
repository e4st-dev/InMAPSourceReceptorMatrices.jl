using Test, InMAPSRM
using Meshes
using DataFrames
using .Sys

@testset "Test InMAPSRM" begin
    @testset "Test cell data access" begin
        @test get_isrm_cell_data("MortalityRate") isa Vector
        cell_data = get_isrm_cell_data(["MortalityRate", "NOxDryDep"], geometry_longlat = true)
        @test cell_data.MortalityRate isa Vector{<:Number}
        @test cell_data.NOxDryDep isa Vector{<:Number}
        @test cell_data.geometry isa Vector{Box{2, Float64}}
        @test cell_data.geometry_longlat isa Vector{Quadrangle{2, Float64}}
    end

    # Only load in an SRM if plenty of RAM
    if Sys.free_memory() > 70e9
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
        GC.gc()

        @testset "Test run_srm" begin
            source_emis = DataFrame(
                latitude = [39],
                longitude = [-77],
                layer_idx = [1],
                PM2_5 = [1.5],
            )
            res = run_sr(source_emis, ["MortalityRate"])
            @test res isa DataFrame

        end
    end
end