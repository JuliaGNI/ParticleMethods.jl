using ParticleMethods
using Test

using Aqua: Aqua
using StaticArrays: MVector

@testset "ParticleMethods.jl" begin
    @testset "Aqua" begin
        Aqua.test_all(ParticleMethods)
    end

    @testset "Particles" begin
        include("particle_tests.jl")
    end

    @testset "Particle Lists" begin
        include("particle_list_tests.jl")
    end

    @testset "Defects" begin
        include("defects_tests.jl")
    end
end
