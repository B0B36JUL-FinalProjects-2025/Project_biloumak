using Test
using Project_biloumak
using GeometryBasics
using LinearAlgebra

@testset "Solve Logic Tests" begin
    @testset "Torus Geometry Helper Functions" begin
        pos = Point3f(0, 0, 0)
        h = 10.0f0
        r_donut = 5.0f0
        antenna = Antenna(pos, height=h, donut_radius=r_donut)
        center = Project_biloumak.get_torus_center(antenna)
        @test center ≈ Point3f(0f0, 0f0, 10f0)
        p_00 = Project_biloumak.get_torus_point(antenna, 0.0, 0.0)
        @test p_00 ≈ Point3f(10f0, 0f0, 10f0)
        p_90_0 = Project_biloumak.get_torus_point(antenna, pi/2, 0.0)
        @test p_90_0[1] ≈ 0f0 atol=1e-5
        @test p_90_0[2] ≈ 10f0 atol=1e-5
        @test p_90_0[3] ≈ 10f0 atol=1e-5
        p_target = p_00
        p_found = Project_biloumak.find_closest_point_on_torus(antenna, p_target)
        @test norm(p_found - p_target) < 1e-4
        p_far = Point3f(20f0, 0f0, 10f0)
        p_closest_far = Project_biloumak.find_closest_point_on_torus(antenna, p_far)
        @test norm(p_closest_far - Point3f(10f0, 0f0, 10f0)) < 1.0
    end
    @testset "Optimization & TSP" begin
        a1 = Antenna(Point3f(0, 0, 0), height=10f0, donut_radius=2f0)
        a2 = Antenna(Point3f(20, 0, 0), height=10f0, donut_radius=2f0)
        a3 = Antenna(Point3f(10, 20, 0), height=10f0, donut_radius=2f0)
        antennas = [a1, a2, a3]

        dist_mat = Project_biloumak.build_distance_matrix(antennas)
        @test size(dist_mat) == (3, 3)
        @test dist_mat[1,1] == 0.0
        @test dist_mat[1,2] > 0.0
        
        order = Project_biloumak.solve_tsp(dist_mat)
        @test length(order) == 3
        @test sort(order) == [1, 2, 3]

        start_pos = Point3f(0, -10, 20)
        path = solve_path_optimization(antennas, start_position=start_pos)
        
        @test !isempty(path)
        @test path[end] ≈ start_pos
        
        @test length(path) > length(antennas)
    end
    @testset "Edge Cases" begin
        path_empty = solve_path_optimization(Antenna[])
        @test length(path_empty) == 1
        
        single_ant = [Antenna(Point3f(0,0,0))]
        path_single = solve_path_optimization(single_ant)
        @test length(path_single) > 1
    end
end
