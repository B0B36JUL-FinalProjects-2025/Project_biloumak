function run_solver(; antennas::Vector{Antenna}=get_default_antennas(), start_position::Point3f=Point3f(0, 0, 20))
    trajectory = solve_path_optimization(antennas, start_position=start_position)
    fig = visualize(antennas, trajectory, start_position=start_position)
    return fig
end
