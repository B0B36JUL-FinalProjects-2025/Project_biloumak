include("vis_utils.jl")

using GLMakie
GLMakie.activate!(inline=false)
set_theme!(theme_dark())

t = range(0, 4π, length=300)
traj = [Point2f(ti * cos(ti), ti * sin(ti)) for ti in t]

fig = Figure(size=(1200, 800), backgroundcolor=:gray10)
ax = Axis(fig[1, 1],
    backgroundcolor=:gray15,
    # xgridcolor=(:white, 0.0),
    # ygridcolor=(:white, 0.0),
    titlecolor=:white,
    titlesize=22,
    title="TSPN"
)
lines!(traj, color=(:cyan, 0.4), linewidth=2) #the way

#container + listener creation
frame_index = Observable(1)
drone_pos = @lift [traj[$frame_index]]

arrow_start = @lift [traj[$frame_index]]
arrow_dir = @lift begin
    angle = get_direction_angle(traj, $frame_index)
    [Vec2f(cos(angle), sin(angle))]
end

arrows2d!(ax, arrow_start, arrow_dir,
    color=:orangered,
    shaftwidth=0.2,
    tiplength=0.5,
    tipwidth=0.4
)

scatter!(ax, drone_pos, color=:orangered, markersize=14, marker=:circle) #boid
scatter!(ax,[traj[1]], color=:lime,markersize=12,marker=:circle) #start
scatter!(ax,[traj[end]],color=:red, markersize=12, marker=:circle) #finish

xlims!(ax, -15, 15)
ylims!(ax, -15, 15)
ax.aspect = DataAspect()
is_running = Observable(false)

function run_animation()
    is_running[] = true
    for i in 1:length(traj)
        if !is_running[]
            break
        end
        frame_index[] = i
        sleep(0.02)
    end
    is_running[] = false
end

controls_layout = fig[1, 2] = GridLayout(valign = :top, halign = :left, tellheight = false)
restart_btn = Button(controls_layout[1, 1], label="Restart Animation", buttoncolor=:gray30, labelcolor=:white, width = 150)
colsize!(fig.layout, 1, Relative(0.8))
colsize!(fig.layout, 2, Fixed(200))
on(restart_btn.clicks) do _
    if !is_running[]
        # restart_btn.buttoncolor[] = :gray50
        @async run_animation()
    end
end

display(fig)
run_animation()