include("vis_utils.jl")
using GLMakie

function setup_window()
    GLMakie.activate!(inline=false)
    set_theme!(theme_dark())
    fig = Figure(size=(1200, 800), backgroundcolor=:gray10)
    return fig
end

function setup_axis!(fig)
    ax = Axis(fig[1, 1],
        backgroundcolor=:gray15,
        titlecolor=:white,
        titlesize=22,
        title="TSPN"
    )
    xlims!(ax, -15, 15)
    ylims!(ax, -15, 15)
    ax.aspect = DataAspect()
    return ax
end

function draw_static_elements!(ax, traj)
    lines!(ax, traj, color=(:cyan, 0.4), linewidth=2) # Path
    scatter!(ax, [traj[1]], color=:lime, markersize=12, marker=:circle) # Start
    scatter!(ax, [traj[end]], color=:red, markersize=12, marker=:circle) # Finish
end

function setup_drone!(ax, traj, frame_index)
    drone_pos = @lift [traj[$frame_index]]
    arrow_dir = @lift begin
        angle = get_direction_angle(traj, $frame_index)
        [Vec2f(cos(angle), sin(angle))]
    end
    arrows2d!(ax, drone_pos, arrow_dir,
        color=:orangered,
        shaftwidth=0.2,
        tiplength=0.5,
        tipwidth=0.4
    )
    scatter!(ax, drone_pos, color=:orangered, markersize=14, marker=:circle)
end

function run_animation_loop(is_running, frame_index, traj_length)
    is_running[] = true
    if frame_index[] >= traj_length
        frame_index[] = 1
    end
    for i in frame_index[]:traj_length
        if !is_running[]
            break
        end
        frame_index[] = i
        sleep(0.02)
    end
    is_running[] = false
end

function setup_controls!(fig, is_running, frame_index, traj_length)
    controls_layout = GridLayout(valign = :top, halign = :left, tellheight = false)
    fig[1, 2] = controls_layout
    
    restart_btn = Button(controls_layout[1, 1], label="Start/Restart", buttoncolor=:gray30, labelcolor=:white, width = 150)
    
    colsize!(fig.layout, 1, Relative(0.8))
    colsize!(fig.layout, 2, Fixed(200))
    
    on(restart_btn.clicks) do _
        if !is_running[]
            @async run_animation_loop(is_running, frame_index, traj_length)
        end
    end
end

function main()
    traj = generate_test_trajectory()
    fig = setup_window()
    ax = setup_axis!(fig)
    draw_static_elements!(ax, traj)
    frame_index = Observable(1)
    is_running = Observable(false)
    setup_drone!(ax, traj, frame_index)
    setup_controls!(fig, is_running, frame_index, length(traj))
    display(fig)
    @async run_animation_loop(is_running, frame_index, length(traj))
    if !isinteractive()
        wait(Condition()) 
    end
end

main()