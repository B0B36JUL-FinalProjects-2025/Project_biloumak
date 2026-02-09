import Pkg
Pkg.activate(@__DIR__)
Pkg.develop(path=joinpath(@__DIR__, ".."))
Pkg.instantiate()

using Project_biloumak
using GeometryBasics
using Random

Random.seed!(42)

antennas = Antenna[]
num_antennas = 10
range_vals = 60.0f0

for i in 1:num_antennas
    x = rand(Float32) * 2 * range_vals - range_vals
    y = rand(Float32) * 2 * range_vals - range_vals
    pos = Point3f(x, y, 0.0f0)
    
    h = 10.0f0 + rand(Float32) * 20.0f0
    r_donut = 3.0f0 + rand(Float32) * 6.0f0
    t_transfer = 1.0f0 + rand(Float32) * 5.0f0 
    
    push!(antennas, Antenna(pos, height=h, donut_radius=r_donut, transfer_time=t_transfer))
end

start_pos = Point3f(0, 0, 40)

Project_biloumak.run_solver(antennas=antennas, start_position=start_pos)