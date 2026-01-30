include("vis_utils.jl")
using GLMakie
using GeometryBasics
using Colors

function setup_ui(fig, speed, traj, frame_idx, drone_pos)
    controls = GridLayout(fig[1, 1], tellwidth=true)
    
    Label(controls[1,1], "Drone Simulation", fontsize=22, color=:white)
    
    Label(controls[2,1], "-- Playback --", fontsize=14, color=:gray60)
    btn_grid = GridLayout(controls[3,1])
    play_btn = Button(btn_grid[1,1], label="Play", buttoncolor=RGBf(0.2, 0.7, 0.3), labelcolor=:white, width=80)
    pause_btn = Button(btn_grid[1,2], label="Pause", buttoncolor=RGBf(0.9, 0.6, 0.2), labelcolor=:white, width=80)
    restart_btn = Button(btn_grid[1,3], label="Restart", buttoncolor=RGBf(0.5, 0.5, 0.5), labelcolor=:white, width=80)
    
    Label(controls[4,1], "Speed:", fontsize=12, color=:gray70)
    speed_sl = Slider(controls[5,1], range=0.2:0.2:3.0, startvalue=1.0, width=250)
    speed_lbl = @lift string(round($speed, digits=1), "x")
    Label(controls[6,1], speed_lbl, fontsize=12, color=:cyan)
    
    Label(controls[7,1], "Position:", fontsize=12, color=:gray70)
    pos_sl = Slider(controls[8,1], range=1:length(traj[]), startvalue=1, width=250)
    pos_lbl = @lift string($frame_idx, " / ", length($traj))
    Label(controls[9,1], pos_lbl, fontsize=12, color=:cyan)
    
    Label(controls[10,1], "-- Trajectory --", fontsize=14, color=:gray60)
    traj_menu = Menu(controls[11,1], options=["Spiral","Figure-8"], 
        default="Spiral", width=250)
    
    Label(controls[12,1], "-- Status --", fontsize=14, color=:gray60)
    status_lbl = @lift begin
        p = $drone_pos
        string("Pos: (", round(p[1],digits=1), ", ", round(p[2],digits=1), ", ", round(p[3],digits=1), ")")
    end
    Label(controls[13,1], status_lbl, fontsize=12, color=:lime)
    
    colsize!(fig.layout, 1, Fixed(280))
    colsize!(fig.layout, 2, Auto())
end

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
    
    setup_ui(fig, speed, traj, frame_idx, drone_pos)
    screen = display(fig)
    return fig
end

main()