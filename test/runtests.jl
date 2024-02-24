using RubikView: draw_net, draw_oblique_cube, draw_isometric_cube
using RubikCore
using Test, ReferenceTests

@testset "RubikView.jl" begin
    include("draw-net.jl")
end
