using Pkg
Pkg.activate(@__DIR__)

try
    using GLMakie
    using GeometryBasics
    using Color
    using Optim
    using Combinatorics
catch
    Pkg.instantiate()
end

include("visual.jl")
