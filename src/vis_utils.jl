using LinearAlgebra
using GeometryBasics

abstract type TrajectoryType end
struct SpiralTrajectory <: TrajectoryType end
struct FigureEightTrajectory <: TrajectoryType end

function generate_trajectory(::SpiralTrajectory; turns=3, height=20.0, radius=8.0, points=500)
    t = range(0, turns * 2pi, length=points)
    return [Point3f(radius * cos(ti), radius * sin(ti), height * ti / (turns * 2pi)) for ti in t]
end

function generate_trajectory(::FigureEightTrajectory; size=10.0, height=5.0, points=400)
    t = range(0, 2pi, length=points)
    return [Point3f(size * sin(ti), size * sin(2ti) / 2, height + 2 * sin(3ti)) for ti in t]
end

function get_available_trajectories()
    return Dict(
        "Spiral" => SpiralTrajectory(),
        "Figure-8" => FigureEightTrajectory()
    )
end

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