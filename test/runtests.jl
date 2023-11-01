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
end