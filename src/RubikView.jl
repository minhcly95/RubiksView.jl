module RubikView

using RubikCore
using Luxor, Colors, ImageShow
using WGLMakie, GeometryBasics

include("macros.jl")
include("colors.jl")
include("draw-net.jl")
include("render.jl")

export default_color_scheme
export draw_net, draw_flat_net, draw_oblique_net, draw_isometric_net, draw_oblique_cube, draw_isometric_cube
export render

end
