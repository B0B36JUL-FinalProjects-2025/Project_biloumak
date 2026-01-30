using LinearAlgebra
using GeometryBasics

function get_direction_vector(traj, idx)
    if idx >= length(traj)
        idx = length(traj) - 1
    end
    p1 = traj[max(1, idx)]
    p2 = traj[min(idx + 1, length(traj))]
    dir = Point3f(p2) - Point3f(p1)
    norm_dir = norm(dir)
    if norm_dir < 1e-6
        return Point3f(1, 0, 0)
    end
    return Point3f(dir ./ norm_dir)
end

function get_up_vector(direction)
    world_up = Point3f(0, 0, 1)
    if abs(dot(direction, world_up)) > 0.99
        world_up = Point3f(0, 1, 0)
    end
    right = normalize(cross(Vec3f(direction...), Vec3f(world_up...)))
    up = normalize(cross(right, Vec3f(direction...)))
    return Point3f(up...)
end