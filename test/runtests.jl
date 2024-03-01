using NicamFiles
using Test

@testset "NicamFiles.jl" begin
    # Write your tests here.

    # hgrid, sequential
    nioh_all = NicamHgridAllFiles( "./hgrid/gl05/rl00/grid",
                                   access="sequential", glevel=5, rlevel=0 )
    @test nioh_all.nioh[10].data["hiy"][1] == 0.5132468992041482
    
end
