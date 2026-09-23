
using HDF5

# eachparticle is exported and returns the particle vector
@testset "eachparticle is defined" begin
    pa = rand(6, 4)
    pl = ParticleList(pa; variables = (x = 1:3, v = 4:6))
    @test eachparticle(pl) == pl.particles
end

# hasproperty(::ParticleList, s) must test ParticleList's own fields,
# not Particle's, once VT and PT are exhausted
@testset "hasproperty tests ParticleList, not Particle" begin
    pa = rand(6, 4)
    pl = ParticleList(pa; variables = (x = 1:3, v = 4:6))
    @test hasproperty(pl, :list)
    @test hasproperty(pl, :indices)
    @test !hasproperty(pl, :state)
end

# Particle(DT, len) must infer its return type: the length is a runtime value
@testset "Particle(DT, len) is inferred" begin
    p = @inferred Particle(Float64, 7)
    @test p.state == zeros(7)
end

# iterate on an empty list must terminate instead of indexing pl[1]
@testset "iterate on an empty ParticleList terminates" begin
    pa = zeros(6, 0)
    pl = ParticleList(pa; variables = (x = 1:3, v = 4:6))
    @test iterate(pl) === nothing
end

# collect must yield the particles; eltype stays the numeric element type
@testset "collect over a ParticleList yields its particles" begin
    pa = rand(6, 4)
    pl = ParticleList(pa; variables = (x = 1:3, v = 4:6))
    @test collect(pl) == pl.particles
    @test eltype(pl) == Float64
end

# HDF5 round-trip must preserve a scalar variable index, not widen it
# to a 1-element range
@testset "HDF5 round-trip preserves a scalar variable index" begin
    pa = rand(7, 5)
    vars = (x = 1:3, v = 4:6, w = 7)
    pl = ParticleList(pa; variables = vars)

    mktempdir() do dir
        h5file = joinpath(dir, "roundtrip.h5")
        h5open(h5file, "w") do file
            ParticleMethods.h5save(file, pl)
        end
        plh5 = ParticleList(h5file)

        @test typeof(plh5.indices.w) == typeof(pl.indices.w)
        @test plh5.w == pl.w
    end
end

# the per-particle variable views of a scalar index are 0-dimensional views,
# the same as the particle's own view of that variable
@testset "scalar variable views match the particle views" begin
    pa = rand(7, 5)
    pl = ParticleList(pa; variables = (x = 1:3, v = 4:6, w = 7))
    @test all(pl.variables.w[i] == pl.particles[i].w for i in axes(pa, 2))
    @test all(pl.variables.x[i] == pl.particles[i].x for i in axes(pa, 2))
end
