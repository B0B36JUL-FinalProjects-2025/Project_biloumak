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
        if dist < 1e-6 break end
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

function build_distance_matrix(antennas::Vector{Antenna})
    n = length(antennas)
    dist_matrix = zeros(Float64, n, n)
    for i in 1:n, j in 1:n
        if i != j
            p1 = find_closest_point_on_torus(antennas[i], get_torus_center(antennas[j]))
            p2 = find_closest_point_on_torus(antennas[j], Point3f(p1))
            dist_matrix[i, j] = norm(Point3f(p1) - Point3f(p2))
        end
    end
    return dist_matrix
end

function solve_tsp_bruteforce(dist_matrix::Matrix{Float64})
    n = size(dist_matrix, 1)
    best_order, best_dist = collect(1:n), Inf
    
    for perm in permutations(1:n)
        d = sum(dist_matrix[perm[i], perm[i+1]] for i in 1:(n-1))
        if d < best_dist
            best_dist = d
            best_order = collect(perm)
        end
    end
    return best_order
end

function solve_tsp_greedy(dist_matrix::Matrix{Float64}, start_idx::Int=1)
    n = size(dist_matrix, 1)
    visited = falses(n)
    order = Int[start_idx]
    visited[start_idx] = true
    
    current = start_idx
    while length(order) < n
        best_next, best_dist = -1, Inf
        for j in 1:n
            if !visited[j] && dist_matrix[current, j] < best_dist
                best_dist = dist_matrix[current, j]
                best_next = j
            end
        end
        push!(order, best_next)
        visited[best_next] = true
        current = best_next
    end
    return order
end

function improve_tsp_2opt!(order::Vector{Int}, dist_matrix::Matrix{Float64})
    n = length(order)
    improved = true
    while improved
        improved = false
        for i in 1:(n-2), j in (i+2):n
            d1 = dist_matrix[order[i], order[i+1]]
            d2 = j < n ? dist_matrix[order[j], order[j+1]] : 0.0
            new_d1 = dist_matrix[order[i], order[j]]
            new_d2 = j < n ? dist_matrix[order[i+1], order[j+1]] : 0.0
            
            if d1 + d2 > new_d1 + new_d2 + 1e-6
                order[i+1:j] = reverse(order[i+1:j])
                improved = true
            end
        end
    end
    return order
end

function solve_tsp(dist_matrix::Matrix{Float64})
    n = size(dist_matrix, 1)
    if n <= 8
        return solve_tsp_bruteforce(dist_matrix)
    else
        best_order, best_dist = nothing, Inf
        for start in 1:n
            order = solve_tsp_greedy(dist_matrix, start)
            improve_tsp_2opt!(order, dist_matrix)
            d = sum(dist_matrix[order[i], order[i+1]] for i in 1:(n-1))
            if d < best_dist
                best_dist = d
                best_order = order
            end
        end
        return best_order
    end
end

function generate_smooth_path(waypoints::Vector{Point3f}; points_per_segment::Int=50)
    length(waypoints) < 2 && return waypoints
    trajectory = Point3f[]
    
    for i in 1:(length(waypoints)-1)
        p0 = i > 1 ? waypoints[i-1] : waypoints[i]
        p1 = waypoints[i]
        p2 = waypoints[i+1]
        p3 = i < length(waypoints)-1 ? waypoints[i+2] : waypoints[i+1]
        
        for j in 0:(points_per_segment-1)
            t = j / points_per_segment
            t2, t3 = t^2, t^3
            
            pos = 0.5f0 * ((2*p1) + (-p0 + p2)*t + 
                  (2*p0 - 5*p1 + 4*p2 - p3)*t2 + 
                  (-p0 + 3*p1 - 3*p2 + p3)*t3)
            push!(trajectory, pos)
        end
    end
    push!(trajectory, waypoints[end])
    return trajectory
end

function solve_path_optimization(antennas::Vector{Antenna}; start_position::Point3f=Point3f(0, 0, 20))
    isempty(antennas) && return [Point3f(0, 0, 5)]
    n = length(antennas)
    
    if n == 1
        order = [1]
    else
        dist_matrix = build_distance_matrix(antennas)
        order = solve_tsp(dist_matrix)
    end
    
    contact_points = Point3f[]
    push!(contact_points, start_position)
    
    for i in 1:n
        ant = antennas[order[i]]
        to_p = i < n ? get_torus_center(antennas[order[i+1]]) : start_position
        push!(contact_points, find_optimal_contact_point(ant, contact_points[end], to_p))
    end    
    push!(contact_points, start_position)
    
    return generate_smooth_path(contact_points)
end