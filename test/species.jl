using ParticleMethods
using Test

# a species carries a name, a charge and a mass, and the mass must be positive
@testset "Species rejects a non-positive mass" begin
    @test_throws ArgumentError Species(:n, 0.0, 0.0)
    @test_throws ArgumentError Species(:n, 1.0, -1.0)
    @test_throws ArgumentError Species(:n, 1.0, 0.0)

    s = Species(:n, 0.0, 1.0)
    @test s isa Species{Float64}
    @test s.name === :n
    @test s.charge == 0.0
    @test s.mass == 1.0
end

# the constructor promotes the charge and the mass, and the accessors read the fields
@testset "Species promotes its fields" begin
    e = Species(:e, -1, 0.5)
    @test e isa Species{Float64}
    @test charge(e) == -1.0
    @test mass(e) == 0.5
    @test species(e) === e

    i = Species(:i, 2, 4)
    @test i isa Species{Int}
    @test charge(i) === 2
    @test mass(i) === 4
end

# Species{T}(s) converts an existing species, and re-checks the mass in T
@testset "Species converts to another element type" begin
    e = Species(:e, -1, 0.5)
    @test Species{Float32}(e) isa Species{Float32}
    @test charge(Species{Float32}(e)) === -1.0f0
    @test mass(Species{Float32}(e)) === 0.5f0

    @test_throws ArgumentError Species{Float32}(Species(:n, 1.0, 1e-50))
end
