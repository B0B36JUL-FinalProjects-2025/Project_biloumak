include("vis_utils.jl")
using GLMakie
using GeometryBasics
using Colors

function main()
    GLMakie.activate!(inline=false)
    set_theme!(theme_dark())
    
    frame_idx = Observable(1)
    speed = Observable(1.0)
    is_playing = Observable(false)
    traj = Observable(generate_trajectory(SpiralTrajectory()))
    
    fig = Figure(size=(1600, 900), backgroundcolor=:gray10)
    ax = LScene(fig[1, 2], show_axis=true)
    
    drone_pos = @lift $traj[clamp($frame_idx, 1, length($traj))]
    
    trail_pts = @lift begin
        idx = clamp($frame_idx, 1, length($traj))
        start = max(1, idx - 30)
        $traj[start:idx]
    end
    
    lines!(ax, traj, color=:cyan, linewidth=2)
    meshscatter!(ax, @lift([$traj[1]]), markersize=0.5, color=:lime)
    meshscatter!(ax, @lift([$traj[end]]), markersize=0.5, color=:red)
    
    lines!(ax, trail_pts, color=:orange, linewidth=3)
    meshscatter!(ax, @lift([$drone_pos]), markersize=0.5, color=:orangered)
    
    arrow_dir = @lift begin
        idx = clamp($frame_idx, 1, length($traj))
        Vec3f(get_direction_vector($traj, idx)...) * 1.2
    end
    arrows3d!(ax, @lift([$drone_pos]), @lift([$arrow_dir]), 
        color=:yellow, tipradius=0.15, tiplength=0.3)
    
    screen = display(fig)
    return fig
end

main()