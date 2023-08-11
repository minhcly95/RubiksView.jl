Base.show(io::IO, mime::MIME"image/png", cube::Cube) = show(io, mime, draw_net(cube))

function draw_net(cube::Cube, projection=:oblique;
    z_scale=0.6, attach_down=:front, attach_back=:right, attach_left=:front,
    colors=default_color_scheme(), background=nothing,
    scale=1, cell_width=30, cell_border_width=2, face_border_width=4)

    cell_width *= scale
    cell_border_width *= scale
    face_border_width *= scale

    # Preprocessing
    @_check_argument_in_array(attach_down, :none, :front, :right)
    @_check_argument_in_array(attach_back, :none, :up, :right)
    @_check_argument_in_array(attach_left, :none, :up, :front)

    net = collect(RubikCore._get_net(cube))
    (attach_down == :right) && (net[4] = _rotate_face_ccw(net[4]))
    (attach_back == :up) && (net[5] = _rotate_face_180(net[5]))
    (attach_left == :up) && (net[6] = _rotate_face_cw(net[6]))

    local transforms, bounds
    if projection == :flat
        transforms, bounds = _get_flat_transforms_and_bounds(z_scale, attach_down, attach_back, attach_left)
    elseif projection == :oblique
        transforms, bounds = _get_oblique_transforms_and_bounds(z_scale, attach_down, attach_back, attach_left)
    elseif projection in (:iso, :isometric)
        transforms, bounds = _get_isometric_transforms_and_bounds(z_scale, attach_down, attach_back, attach_left)
    else
        throw(ArgumentError("invalid value for projection, must be :flat, :oblique, or :isometric"))
    end

    width, height = round.(Int, ((bounds[3]-bounds[1]+1/3) * 3cell_width, (bounds[4]-bounds[2]+1/3) * 3cell_width))

    # Drawing
    Drawing(width, height, :png)
    origin()

    translate(-Point(bounds[3]+bounds[1], bounds[4]+bounds[2])/2 * 3cell_width)
    isnothing(background) || Luxor.background(background)

    kwargs = (;colors, cell_width, cell_border_width, face_border_width)

    for i in 1:6
        isnothing(transforms[i]) || _draw_face(net[i], transforms[i]; kwargs...)
    end

    f = convert(Matrix, image_as_matrix())
    finish()
    return f
end

function _get_flat_transforms_and_bounds(z, attach_down, attach_back, attach_left)
    transforms = [
        [1 0 -0.5; 0 1 -0.5; 0 0 1],
        [1 0 -0.5; 0 1 0.5; 0 0 1],
        [1 0 0.5; 0 1 0.5; 0 0 1],
        @_match(attach_down, :front => [1 0 -0.5; 0 1 1.5; 0 0 1], :right => [1 0 0.5; 0 1 1.5; 0 0 1]),
        @_match(attach_back, :up => [1 0 -0.5; 0 1 -1.5; 0 0 1], :right => [1 0 1.5; 0 1 0.5; 0 0 1]),
        @_match(attach_left, :up => [1 0 -1.5; 0 1 -0.5; 0 0 1], :front => [1 0 -1.5; 0 1 0.5; 0 0 1]),
    ]
    b_left = -1 - (attach_left != :none ? 1 : 0)
    b_top = -1 - (attach_back == :up ? 1 : 0)
    b_right = 1 + (attach_back == :right ? 1 : 0)
    b_bottom = 1 + (attach_down != :none ? 1 : 0)
    return transforms, (b_left, b_top, b_right, b_bottom)
end

function _get_oblique_transforms_and_bounds(z, attach_down, attach_back, attach_left)
    transforms = [
        [1 -z 0.5(-1+z); 0 z 0.5(-z); 0 0 1],
        [1 0 0.5(-1); 0 1 0.5(1); 0 0 1],
        [z 0 0.5(z); -z 1 0.5(1-z); 0 0 1],
        @_match(attach_down, :front => [1 0 0.5(-1); 0 1 0.5(3); 0 0 1], :right => [z 0 0.5(z); -z 1 0.5(3-z); 0 0 1]),
        @_match(attach_back, :up => [1 0 0.5(-1+2z); 0 1 0.5(-1-2z); 0 0 1], :right => [1 0 0.5(1+2z); 0 1 0.5(1-2z); 0 0 1]),
        @_match(attach_left, :up => [1 -z 0.5(-3+z); 0 z 0.5(-z); 0 0 1], :front => [1 0 0.5(-3); 0 1 0.5(1); 0 0 1]),
    ]
    b_left = -1 - (attach_left != :none ? 1 : 0)
    b_top = -z - (attach_back == :up ? 1 : 0)
    b_right = z + (attach_back == :right ? 1 : 0)
    b_bottom = 1 + (attach_down != :none ? 1 : 0)
    return transforms, (b_left, b_top, b_right, b_bottom)
end

function _get_isometric_transforms_and_bounds(z, attach_down, attach_back, attach_left)
    a = sqrt(3)/2
    transforms = [
        [a -a 0.5(0); 0.5 0.5 0.5(-1); 0 0 1],
        [a 0 0.5(-a); 0.5 1 0.5(0.5); 0 0 1],
        [a 0 0.5(a); -0.5 1 0.5(0.5); 0 0 1],
        @_match(attach_down, :front => [a 0 0.5(-a); 0.5 1 0.5(2.5); 0 0 1], :right => [a 0 0.5(a); -0.5 1 0.5(2.5); 0 0 1]),
        @_match(attach_back, :up => [a -a 0.5(2a); 0.5 0.5 0.5(-2); 0 0 1], :right => [1 0 0.5(2a+1); 0 1 0.5(0); 0 0 1]),
        @_match(attach_left, :up => [a -a 0.5(-2a); 0.5 0.5 0.5(-2); 0 0 1], :front => [1 0 0.5(-2a-1); 0 1 0.5(0); 0 0 1]),
    ]
    b_left = -a - (attach_left == :front ? 1 : 0) - (attach_left == :up ? a : 0)
    b_top = -1 - (attach_back == :up || attach_left == :up ? 0.5 : 0)
    b_right = a + (attach_back == :right ? 1 : 0) + (attach_back == :up ? a : 0)
    b_bottom = 1 + (attach_down != :none ? 1 : 0)
    return transforms, (b_left, b_top, b_right, b_bottom)
end

# Derivatives
draw_flat_net(cube::Cube; kwargs...) = draw_net(cube, :flat; kwargs...)

draw_oblique_net(cube::Cube; kwargs...) = draw_net(cube, :oblique; kwargs...)

draw_isometric_net(cube::Cube; kwargs...) = draw_net(cube, :isometric; kwargs...)

draw_oblique_cube(cube::Cube; kwargs...) =
    draw_net(cube, :oblique; attach_down=:none, attach_back=:none, attach_left=:none, kwargs...)

draw_isometric_cube(cube::Cube; kwargs...) =
    draw_net(cube, :isometric; attach_down=:none, attach_back=:none, attach_left=:none, kwargs...)

# Subroutines
function _draw_face(face_net, transform;
    colors, cell_width, cell_border_width, face_border_width)

    cell_faces = Face.(face_net)
    cell_colors = [colors[Int(f)] for f in cell_faces]

    @layer begin
        scale(3cell_width)

        M = cairotojuliamatrix(getmatrix())
        setmatrix(juliatocairomatrix(M * transform))

        # Cells
        for i in 1:3, j in 1:3
            setcolor(cell_colors[(j-1)*3+i])
            box(Point(i - 2, j - 2)/3, 1/3, 1/3, :fill)
        end

        # Cell border
        setline(cell_border_width)
        setlinejoin("round")
        setcolor(BORDER_COLOR)
        line(Point(-0.5, -1/6), Point(0.5, -1/6), :stroke)
        line(Point(-0.5, 1/6), Point(0.5, 1/6), :stroke)
        line(Point(-1/6, -0.5), Point(-1/6, 0.5), :stroke)
        line(Point(1/6, -0.5), Point(1/6, 0.5), :stroke)

        # Face border
        setline(face_border_width)
        setcolor(BORDER_COLOR)
        box(Point(0, 0), 1, 1, :stroke)
    end
end

_rotate_face_cw(face_net) = face_net[[7, 4, 1, 8, 5, 2, 9, 6, 3]]
_rotate_face_ccw(face_net) = face_net[[3, 6, 9, 2, 5, 8, 1, 4, 7]]
_rotate_face_180(face_net) = face_net[[9, 8, 7, 6, 5, 4, 3, 2, 1]]
