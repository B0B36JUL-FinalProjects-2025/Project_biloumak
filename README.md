# Project_biloumak

**Traveling Salesman Problem with Neighborhoods**

A Julia package that solves a variant of the Traveling Salesman Problem where the cities are toroid-shaped signal zones around AP antennas. A drone must visit every antenna's signal neighborhood in the shortest path, visualized in an interactive 3D scene powered by [GLMakie](https://docs.makie.org/stable/).

![](image.png)
---

## Installation & Activation

### 1. Clone the repository

```bash
git clone https://github.com/B0B36JUL-FinalProjects-2025/Project_biloumak.git
cd Project_biloumak
```

### 2. Activate and install dependencies

Open a Julia REPL in the project directory and run:

```julia
] activate .
] instantiate
```

Or without Pkg mode:

```julia
import Pkg
Pkg.activate(".")
Pkg.instantiate()
```

---

## Running Tests

After activating the project environmebt:

```julia
] test
```

Or from a plain Julia prompt:

```julia
import Pkg
Pkg.activate(".")
Pkg.test()
```

Or from the command line:

```bash
julia --project=. -e "using Pkg; Pkg.test()"
```

---

## Running Examples

Examples are self-contained scripts that activate the project environment automatically, no manual setup is required.

### Simple run (3 antennas)

```bash
julia examples/simple_run.jl
```

Or from the Julia REPL:

```julia
include("examples/simple_run.jl")
```

### Many antennas (10 randomly generated)

```bash
julia examples/more_antennas_run.jl
```

Or from the Julia REPL:

```julia
include("examples/more_antennas_run.jl")
```

Both examples open an interactive 3D window where you can:

- **Play / Pause / Restart** the drone animation
- Adjust **speed** with a slider
- Movr the **position** along the trajectory
- Switch between trajectories, where **Optimised** is our solution.

---

## Quick Start (from scratch)

```julia
import Pkg
Pkg.activate(".")
Pkg.instantiate()

using Project_biloumak
using GeometryBasics

antennas = [
    Antenna(Point3f(-10, -10, 0), height=12f0, donut_radius=4f0),
    Antenna(Point3f( 10,  10, 0), height=15f0, donut_radius=5f0),
]

Project_biloumak.run_solver(antennas=antennas, start_position=Point3f(0, 0, 20))
```

---


## API Reference

### `Antenna`

```julia
Antenna(position::Point3f;
        height = 15.0f0,
        stick_radius = 0.15f0,
        donut_radius = 4.0f0,
        transfer_time = 5.0f0)
```

| Field           | Description                                       |
|-----------------|---------------------------------------------------|
| `position`      | `Point3f` - base position on the ground           |
| `height`        | Height of the antenna stick                       |
| `stick_radius`  | Radius of the rendered stick cylinder             |
| `donut_radius`  | Major & minor radius of the toroidal signal zone  |
| `transfer_time` | Data transfer time at this antenna (reserved)     |

### `solve_path_optimization`

```julia
solve_path_optimization(antennas::Vector{Antenna}; start_position::Point3f = Point3f(0, 0, 20))
```

Returns a `Vector{Point3f}` - a smooth Catmull–Rom spline trajectory through optimal torus contact points in TSP order, starting and ending at `start_position`.

### `run_solver`

```julia
run_solver(; antennas::Vector{Antenna} = get_default_antennas(),start_position::Point3f   = Point3f(0, 0, 20))
```

Convenience entry point that calls `solve_path_optimization` to compute the optimal trajectory, then passes it to `visualize` to display the 3D scene. Returns the `Figure`.

### `visualize`

```julia
visualize(antennas::Vector{Antenna}, trajectory::Vector{Point3f}; start_position::Point3f = Point3f(0, 0, 20))
```

Opens an interactive 3D GLMakie window showing antennas, radiation patterns, and the animated drone path for a given pre-computed trajectory. Useful when you want to supply your own trajectory or visualize the result of a custom solver.

---

## Algorithm Overview

1. **Torus contact points** - For every pair of antennas, the solver finds the closest point on each torus surface using gradient descent.
2. **Distance matrix** - Pairwise torus-to-torus distances are assembled into a matrix.
3. **TSP solver** - For < 9 antennas, all permutations are evaluated (brute-force). For larger instances, a multi-start nearest-neighbor heuristic is refined with 2-opt local search.
4. **Path smoothing** - The ordered contact points are interpolated with Catmull–Rom splines to produce a smooth flyable trajectory.

---

## License

See [LICENSE](LICENSE) for details.
