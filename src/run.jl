using Pkg
Pkg.activate(@__DIR__)

try
    using GLMakie
    using GeometryBasics
    using Colors
catch
    Pkg.instantiate()
end

include("visual.jl")
