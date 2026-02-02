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

function find_closest_point_on_torus(antenna::Antenna, point::Point3f)
    center = get_torus_center(antenna)
    R, r = antenna.donut_radius, antenna.donut_radius
    
    dx, dy, dz = point[1] - center[1], point[2] - center[2], point[3] - center[3]
    u = atan(dy, dx)
    v = atan(dz, sqrt(dx^2 + dy^2) - R)
    
    lr, eps_step = 0.1, 1e-5
    
    for _ in 1:100
        p = get_torus_point(antenna, u, v)
        dist = norm(Point3f(p) - point)
        
        p_du = get_torus_point(antenna, u + eps_step, v)
        p_dv = get_torus_point(antenna, u, v + eps_step)
        
        grad_u = (norm(Point3f(p_du) - point) - dist) / eps_step
        grad_v = (norm(Point3f(p_dv) - point) - dist) / eps_step
        
        u -= lr * grad_u
        v -= lr * grad_v
        
        if abs(grad_u) < 1e-6 && abs(grad_v) < 1e-6 break end
    end
    return get_torus_point(antenna, u, v)
end

function find_optimal_contact_point(antenna::Antenna, from_point::Point3f, to_point::Union{Point3f, Nothing}=nothing)
    best_point, best_cost = nothing, Inf
    n_samples = 36
    
    for i in 0:n_samples-1, j in 0:n_samples-1
        u, v = 2π * i / n_samples, 2π * j / n_samples
        p = get_torus_point(antenna, u, v)
        
        cost = norm(Point3f(p) - Point3f(from_point))
        if to_point !== nothing
            cost += norm(Point3f(p) - Point3f(to_point))
        end
        
        if cost < best_cost
            best_cost = cost
            best_point = p
        end
    end
    return best_point
end