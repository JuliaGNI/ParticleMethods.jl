using ParticleMethods
using Random
using StaticArrays: MVector
using Test

Random.seed!(1234)

# test constructors
l = 7
vars = (x = 1:3, v = 4:6, z = 1:6, w = 7)
params = (a = 1, b = 1.0)

ps = MVector{l}(zeros(l))
p1 = Particle(ps; variables = vars, parameters = params)
p2 = Particle(eltype(ps), length(ps); variables = vars, parameters = params)

@test p1.state == p2.state == ps
@test p1.views == p2.views
@test p1.params == p2.params == params
@test p1.params === p2.params === params

# test assertions
@test_throws AssertionError Particle(ps; variables = (z = 1:6, w = 7), parameters = (
    a = 1, z = 2))
@test_throws AssertionError Particle(ps; variables = (z = 1:6, state = 7), parameters = (
    a = 1, b = 2))
@test_throws AssertionError Particle(ps; variables = (z = 1:6, w = 7), parameters = (
    a = 1, state = 2))

# test getproperty
s = rand(7)
p = Particle(s; variables = (x = 1:3, v = 4:6, z = 1:6, w = 7), parameters = (
    a = 1, b = 1.0))

# test state vector
@test p.state === s

# test views
@test p.x == p.state[1:3]
@test p.v == p.state[4:6]
@test p.z == p.state[1:6]
@test p.w == fill(p.state[7])

# test parameters
@test p.a == 1
@test p.b == 1.0

# The barriers `allocations` and the positive control `_allocating`. Every allocation assertion
# below runs only where `Base.JLOptions().code_coverage == 0`, so a run with code coverage skips
# it.
include("helpers/allocations.jl")

# One barrier per property name: a name passed at run time does not constant-propagate, so each
# barrier holds its name as a literal.
_getx(p) = p.x
_getw(p) = p.w
_geta(p) = p.a
_getstate(p) = p.state
_hasx(p) = hasproperty(p, :x)
_hasa(p) = hasproperty(p, :a)
_hasstate(p) = hasproperty(p, :state)
_hasnone(p) = hasproperty(p, :none)

# the properties of a particle of a list, and of a particle on its own state vector
@testset "getproperty and hasproperty ($T)" for T in (Float32, Float64)
    vars = (x = 1:3, v = 4:6, w = 7)
    params = (a = 1, b = T(2))
    pl = ParticleList(rand(T, 7, 3); variables = vars, parameters = params)

    for p in (pl[2], Particle(rand(T, 7); variables = vars, parameters = params))
        @test @inferred(_getx(p)) == p.state[1:3]
        @test @inferred(_getw(p)) == fill(p.state[7])
        @test @inferred(_geta(p)) === 1
        @test @inferred(_getstate(p)) === getfield(p, :state)
        @test @inferred(_hasx(p)) === true
        @test @inferred(_hasa(p)) === true
        @test @inferred(_hasstate(p)) === true
        @test @inferred(_hasnone(p)) === false

        if Base.JLOptions().code_coverage == 0
            @test allocations(_getx, p) == 0
            @test allocations(_getw, p) == 0
            @test allocations(_geta, p) == 0
            @test allocations(_getstate, p) == 0
            @test allocations(_hasx, p) == 0
            @test allocations(_hasa, p) == 0
            @test allocations(_hasstate, p) == 0
            @test allocations(_hasnone, p) == 0
            @test allocations(_allocating, p) > 0
        end
    end
end
