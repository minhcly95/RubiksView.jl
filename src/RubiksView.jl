module RubiksView

using RubiksCore
using Luxor, Colors, ImageShow

include("macros.jl")
include("colors.jl")
include("draw-net.jl")

export default_color_scheme
export draw_net, draw_flat_net, draw_oblique_net, draw_isometric_net, draw_oblique_cube, draw_isometric_cube

end
