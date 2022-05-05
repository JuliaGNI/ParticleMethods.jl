using Particles
using Test

using StaticArrays: MVector

@testset "Particles.jl" begin
    @testset "Particles" begin
        include("particle_tests.jl")
    end

    @testset "Particle Lists" begin
        include("particle_list_tests.jl")
    end
end
