function render(cube::Cube; resolution=(400, 400), background="gray")
    scene = WGLMakie.Scene(; resolution, backgroundcolor = background)
    WGLMakie.cam3d!(scene)

    invcube = cube'

    for (i, f) in enumerate(RubikCore.rotate.(ALL_FACES, (invcube.center,)))
        _add_center_cubie!(scene, i, f)
    end

    for (i, e) in enumerate(invcube.edges)
        _add_edge_cubie!(scene, i, e)
    end

    for (i, c) in enumerate(invcube.corners)
        _add_corner_cubie!(scene, i, c)
    end

    WGLMakie.scale!(scene, Vec3f(0.6))
    return scene
end

# Mesh building
function _make_cubie_mesh()
    CORNERS = Point3f.([
        (0, 0, 0), (1, 0, 0), (0, 1, 0), (1, 1, 0),
        (0, 0, 1), (1, 0, 1), (0, 1, 1), (1, 1, 1)]) .- [Point3f(0.5)]
    POINTS = CORNERS[[
        8, 7, 5, 6,     # Up
        8, 6, 2, 4,     # Front
        7, 8, 4, 3,     # Right
        1, 3, 4, 2,     # Down
        5, 7, 3, 1,     # Back
        6, 5, 1, 2,     # Left
    ]]
    FACES = [QuadFace(i:i+3...) for i in 1:4:24]
    NORMALS = repeat([
        Vec3f(0, 0, 1), Vec3f(1, 0, 0), Vec3f(0, 1, 0),
        Vec3f(0, 0, -1), Vec3f(-1, 0, 0), Vec3f(0, -1, 0)], inner=4)
    
    uv_quad(x, y) = (Vec2f(0.5(x+1), 0.5(y+1)), Vec2f(0.5x, 0.5(y+1)), Vec2f(0.5x, 0.5y), Vec2f(0.5(x+1), 0.5y))
    UVS = [uv_quad(0, 1)..., uv_quad(0, 0)..., uv_quad(1, 0)..., uv_quad(1, 1)..., uv_quad(1, 1)..., uv_quad(1, 1)...]

    return GeometryBasics.Mesh(meta(POINTS, uv=UVS, normals=NORMALS), FACES)
end
const _CUBIE_MESH = _make_cubie_mesh()

# Texture building
function _make_cubie_texture(faces...; colors=default_color_scheme(),
    cell_width=30, border_width=2)
    lrange = range(border_width + 1, cell_width - border_width)
    hrange = range(cell_width + border_width + 1, 2cell_width - border_width)
    image = Color[BORDER_COLOR for _ in 1:2cell_width, _ in 1:2cell_width]
    image[lrange, lrange] .= colors[Int(faces[1])]
    (length(faces) >= 2) && (image[hrange, lrange] .= colors[Int(faces[2])])
    (length(faces) >= 3) && (image[hrange, hrange] .= colors[Int(faces[3])])
    return image
end

# Cubies transformations
const _CENTER_TRANSLATIONS = [
    Vec3f(0, 0, 1), Vec3f(1, 0, 0), Vec3f(0, 1, 0),
    Vec3f(0, 0, -1), Vec3f(-1, 0, 0), Vec3f(0, -1, 0),
]
const _EDGE_TRANSLATIONS = [
    Vec3f(-1, 0, 1), Vec3f(0, -1, 1), Vec3f(0, 1, 1), Vec3f(1, 0, 1),
    Vec3f(-1, -1, 0), Vec3f(-1, 1, 0), Vec3f(1, -1, 0), Vec3f(1, 1, 0),
    Vec3f(-1, 0, -1), Vec3f(0, -1, -1), Vec3f(0, 1, -1), Vec3f(1, 0, -1),
]
const _CORNER_TRANSLATIONS = [
    Vec3f(-1, -1, 1), Vec3f(-1, 1, 1), Vec3f(1, -1, 1), Vec3f(1, 1, 1),
    Vec3f(-1, -1, -1), Vec3f(-1, 1, -1), Vec3f(1, -1, -1), Vec3f(1, 1, -1),
]

function _make_rotations()
    I = Quaternionf(0, 0, 0, 1)
    x = Quaternionf(sind(45), 0, 0, cosd(45))
    y = Quaternionf(0, sind(45), 0, cosd(45))
    z = Quaternionf(0, 0, sind(45), cosd(45))
    x2, x3 = x * x, x * x * x
    y2, y3 = y * y, y * y * y
    z2, z3 = z * z, z * z * z
    return (I, y, x3, x2, y3, x),
        (z2, z3, z, I, z2 * x3, z2 * x, x, x3, z2 * x2, z3 * x2, z * x2, x2),
        (z2, z, z3, I, z3 * x2, z2 * x2, x2, z * x2)
end
const _CENTER_ROTATIONS, _EDGE_ROTATIONS, _CORNER_ROTATIONS = _make_rotations()

function _add_center_cubie!(scene, i, f)
    texture = _make_cubie_texture(f)
    cubie = WGLMakie.mesh!(scene, _CUBIE_MESH, color=texture)
    WGLMakie.rotate!(cubie, _CENTER_ROTATIONS[i])
    WGLMakie.translate!(cubie, _CENTER_TRANSLATIONS[i])
    return cubie
end

function _add_edge_cubie!(scene, i, e)
    str = RubikCore._EDGE_STRS[Int(e)]
    texture = _make_cubie_texture(Face.(collect(str))...)
    cubie = WGLMakie.mesh!(scene, _CUBIE_MESH, color=texture)
    WGLMakie.rotate!(cubie, _EDGE_ROTATIONS[i])
    WGLMakie.translate!(cubie, _EDGE_TRANSLATIONS[i])
    return cubie
end

function _add_corner_cubie!(scene, i, c)
    str = RubikCore._CORNER_STRS[Int(c)]
    texture = _make_cubie_texture(Face.(collect(str))...)
    cubie = WGLMakie.mesh!(scene, _CUBIE_MESH, color=texture)
    WGLMakie.rotate!(cubie, _CORNER_ROTATIONS[i])
    WGLMakie.translate!(cubie, _CORNER_TRANSLATIONS[i])
    return cubie
end
