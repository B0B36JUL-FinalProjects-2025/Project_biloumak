module Project_biloumak

using LinearAlgebra
using Combinatorics
using GLMakie
using GeometryBasics
using Colors

include("vis_utils.jl")
include("solve.jl")
include("visual.jl")

export Antenna, Point3f
export solve_path_optimization
export main

end