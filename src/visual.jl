include("vis_utils.jl")
using GLMakie
using GeometryBasics
using Colors

function draw_antenna_stick!(ax, antenna::Antenna; color=:gray70)
    pos = antenna.position
    h = antenna.height
    r = antenna.stick_radius
    n_segments = 20
    n_height = 2
    θ = range(0, 2pi, length=n_segments)
    z_vals = range(0, h, length=n_height)
    x = [pos[1] + r * cos(t) for t in θ, _ in z_vals]
    y = [pos[2] + r * sin(t) for t in θ, _ in z_vals]
    z = [pos[3] + zv for _ in θ, zv in z_vals]
    surface!(ax, x, y, z, color=fill(color, size(x)), shading=FastShading, 
        transparency=false)
    meshscatter!(ax, [Point3f(pos[1], pos[2], pos[3] + h)], 
        markersize=r*2, color=:red)
end

function draw_radiation_pattern!(
    ax, antenna::Antenna; 
    color=RGBAf(0.2, 0.6, 1.0, 0.3),
    u_segments=50, v_segments=25
    )
    pos = antenna.position
    r = antenna.donut_radius
    R = r
    center_z = pos[3] + antenna.height
    
    u = range(0, 2pi, length=u_segments)
    v = range(0, 2pi, length=v_segments)
    
    x = [(pos[1] + (R + r * cos(vv)) * cos(uu)) for uu in u, vv in v]
    y = [(pos[2] + (R + r * cos(vv)) * sin(uu)) for uu in u, vv in v]
    z = [(center_z + r * sin(vv)) for uu in u, vv in v]
    
    surface!(ax, x, y, z, color=fill(color, size(x)), shading=FastShading,
        transparency=true)
end

function draw_antenna!(
    ax, antenna::Antenna; 
    stick_color=:gray60,
    pattern_color=RGBAf(0.2, 0.6, 1.0, 0.25)
    )
    draw_antenna_stick!(ax, antenna, color=stick_color)
    draw_radiation_pattern!(ax, antenna, color=pattern_color)
end

function draw_antennas!(ax, antennas::Vector{Antenna})
    colors = [
        RGBAf(0.2, 0.6, 1.0, 0.25),#blue
        RGBAf(1.0, 0.4, 0.2, 0.25),#orange  
        RGBAf(0.2, 1.0, 0.4, 0.25),#green
    ]
    for (i, antenna) in enumerate(antennas)
        pattern_color = colors[mod1(i, length(colors))]
        draw_antenna!(ax, antenna, pattern_color=pattern_color)
    end
end

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
    return (play_btn=play_btn, pause_btn=pause_btn, restart_btn=restart_btn, 
        speed_sl=speed_sl, pos_sl=pos_sl, traj_menu=traj_menu)
end

function manage_ui(ui, speed, is_playing, frame_idx, traj)
    on(ui.speed_sl.value) do v
        speed[] = v
    end
    on(ui.pos_sl.value) do v
        if !is_playing[]
            frame_idx[] = Int(round(v))
        end
    end
    on(frame_idx) do v
        if ui.pos_sl.value[] != v && v <= length(traj[])
            ui.pos_sl.value[] = v
        end
    end
    on(ui.play_btn.clicks) do _
        is_playing[] = true
    end
    on(ui.pause_btn.clicks) do _
        is_playing[] = false
    end
    on(ui.restart_btn.clicks) do _
        frame_idx[] = 1
        is_playing[] = true
    end
    on(ui.traj_menu.selection) do sel
        is_playing[] = false
        trajectories = get_available_trajectories()
        if haskey(trajectories, sel)
            new_traj = generate_trajectory(trajectories[sel])
            traj[] = new_traj
            frame_idx[] = 1
            ui.pos_sl.range = 1:length(new_traj)
        end
    end
end

function main()
    GLMakie.activate!(inline=false)
    # set_theme!(theme_dark())
    
    frame_idx = Observable(1)
    speed = Observable(1.0)
    is_playing = Observable(false)
    traj = Observable(generate_trajectory(SpiralTrajectory()))
    
    fig = Figure(size=(1600, 900), backgroundcolor=:gray10)
    ax = LScene(fig[1, 2], show_axis=true)
    
    antennas = get_default_antennas()
    draw_antennas!(ax, antennas)
    
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
    
    ui = setup_ui(fig, speed, traj, frame_idx, drone_pos)
    manage_ui(ui, speed, is_playing, frame_idx, traj)
    
    screen = display(fig)
    is_playing[] = true
    
    if !isinteractive()
        while isopen(screen)
            if is_playing[]
                new_idx = frame_idx[] + max(1, round(Int, speed[]))
                if new_idx > length(traj[])
                    frame_idx[] = 1
                else
                    frame_idx[] = new_idx
                end
            end
            sleep(0.02)
        end
    end
    
    return fig
end

main()