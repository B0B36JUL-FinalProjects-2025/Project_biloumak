using LinearAlgebra
using Combinatorics

function get_torus_center(antenna::Antenna)
    return Point3f(antenna.position[1], antenna.position[2], antenna.position[3] + antenna.height)
end

function get_torus_point(antenna::Antenna, u::Real, v::Real)
    center = get_torus_center(antenna)
    R = antenna.donut_radius
    r = antenna.donut_radius
    
    x = center[1] + (R + r * cos(v)) * cos(u)
    y = center[2] + (R + r * cos(v)) * sin(u)
    z = center[3] + r * sin(v)
    return Point3f(x, y, z)
end