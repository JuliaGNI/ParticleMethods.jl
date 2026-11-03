using HDF5
using ParticleMethods
using ParticleMethods: _sort_ntuple
using Random
using Test

Random.seed!(1234)

# test constructors
np = 10
nd = 6

vars = (x = 1:3, v = 4:6, z = 1:6)
params = (a = 1, b = 1.0)

pa = zeros(nd, np)
l1 = ParticleList(pa; variables = vars)
l2 = ParticleList(eltype(pa), np, nd; variables = vars)

@test l1.list == l2.list
@test l1.views == l2.views
@test l1.params == l2.params
@test l1.params === l2.params

# test assertions
@test_throws AssertionError ParticleList(pa; variables = (x = 1:3, v = 4:6), parameters = (
    a = 1, x = 2))
@test_throws AssertionError ParticleList(pa; variables = (x = 1:3, list = 4:6), parameters = (
    a = 1, b = 2))
@test_throws AssertionError ParticleList(pa; variables = (x = 1:3, v = 4:6), parameters = (
    a = 1, list = 2))

# test getproperty
pa = rand(nd, np)
pl = ParticleList(pa; variables = vars, parameters = params)

# test list matrix
@test pl.list === pa

# test views
@test pl.x == view(pl.list, 1:3, :)
@test pl.v == view(pl.list, 4:6, :)
@test pl.z == view(pl.list, 1:6, :)

# test particle vector
@test pl.particles ==
      [Particle(view(pa, :, i); variables = _sort_ntuple(vars), parameters = params)
       for i in axes(pa, 2)]

# test variable views
@test pl.variables.x == [view(pa, 1:3, i) for i in axes(pa, 2)]
@test pl.variables.v == [view(pa, 4:6, i) for i in axes(pa, 2)]
@test pl.variables.z == [view(pa, 1:6, i) for i in axes(pa, 2)]

# test parameters
@test pl.a == params.a
@test pl.b == params.b

# test array interface
@test eltype(pl) == eltype(pa)
@test length(pl) == np
@test size(pl) == (nd, np)

# test getindex methods
@test pl[1] == pl.particles[1]
@test pl[1, 1] == pl.list[1, 1] == pa[1, 1]
@test pl[1, :] == pl.list[1, :] == pa[1, :]
@test pl[:, 1] == pl.list[:, 1] == pa[:, 1]

# test setindex methods
# .
# .
# .

# test iterate methods
@test eachindex(pl) == eachindex(pl.particles)

i = 0
for p in pl
    global i += 1
    @test p == pl[i]
end

# test HDF5 methods
h5file = "temp.h5"

h5open(h5file, "w") do file
    ParticleMethods.h5save(file, pl)
end

plh5 = ParticleList(h5file)

@test plh5.indices == pl.indices
@test plh5.params == pl.params

@test plh5.x == pl.x
@test plh5.v == pl.v
@test plh5.z == pl.z

@test plh5[1] == pl[1]
@test plh5[1, 1] == pl[1, 1]
@test plh5[1, :] == pl[1, :]
@test plh5[:, 1] == pl[:, 1]

# The barriers `allocations` and the positive control `_allocating`. Every allocation assertion
# below runs only where `Base.JLOptions().code_coverage == 0`, so a run with code coverage skips
# it.
include("helpers/allocations.jl")

_chargeweight(pl, i) = chargeweights(pl)[1, i]

# the species table, the per-particle index, and the accessors
@testset "species table and accessors ($T)" for T in (Float32, Float64)
    np = 5
    nd = 3
    vars = (x = 1, v = 2, w = 3)
    z = rand(T, nd, np)
    specieslist = [Species(:e, -1, T(0.5)), Species(:i, 2, 4)]
    speciesindex = [1, 2, 1, 2, 2]
    pl = ParticleList(z; variables = vars, species = specieslist, speciesindex = speciesindex)

    # the table is converted to the element type of the list, and the index stays `Int`
    @test pl.species isa Vector{Species{T}}
    @test pl.speciesindex isa Vector{Int}
    @test pl.speciesindex == speciesindex

    # every particle reads its own charge, mass and species
    @test [charge(pl, i) for i in 1:np] == T[-1, 2, -1, 2, 2]
    @test [mass(pl, i) for i in 1:np] == T[T(0.5), 4, T(0.5), 4, 4]
    @test [species(pl, i).name for i in 1:np] == [:e, :i, :e, :i, :i]
    @test charge(pl, 1) isa T
    @test mass(pl, 1) isa T
    @test species(pl, 1) isa Species{T}

    # the accessors infer, and allocate nothing after a warm call
    @test @inferred(charge(pl, 1)) == T(-1)
    @test @inferred(mass(pl, 1)) == T(0.5)
    @test @inferred(species(pl, 1)) == Species(:e, -1, T(0.5))
    if Base.JLOptions().code_coverage == 0
        @test allocations(charge, pl, 1) == 0
        @test allocations(mass, pl, 1) == 0
        @test allocations(species, pl, 1) == 0
        @test allocations(_allocating, pl, 1) > 0
    end

    # an `Int32` index works, on the accessors and in the keyword
    @test charge(pl, Int32(2)) == charge(pl, 2)
    @test mass(pl, Int32(2)) == mass(pl, 2)
    @test species(pl, Int32(2)) === species(pl, 2)
    @test ParticleList(z; variables = vars, species = specieslist,
        speciesindex = Int32[1, 2, 1, 2, 2]) == pl

    # the list copies the index, so a later write to the caller's vector leaves it valid
    idx = copy(speciesindex)
    pli = ParticleList(z; variables = vars, species = specieslist, speciesindex = idx)
    idx[1] = 7
    @test pli.speciesindex == speciesindex

    # construction throws in three cases; the range is checked on both sides
    @test_throws ArgumentError ParticleList(z; variables = vars, species = specieslist,
        speciesindex = [1, 2, 1, 2])
    @test_throws ArgumentError ParticleList(z; variables = vars, species = specieslist,
        speciesindex = [1, 2, 3, 1, 2])
    @test_throws ArgumentError ParticleList(z; variables = vars, species = specieslist,
        speciesindex = [1, 2, 1, 2, 0])
    @test_throws ArgumentError ParticleList(z; variables = vars, species = specieslist)

    # equality compares the species table and the index
    @test ParticleList(z; variables = vars, species = specieslist,
        speciesindex = speciesindex) == pl
    @test ParticleList(z; variables = vars,
        species = [Species(:e, -1, T(0.5)), Species(:i, 3, 4)],
        speciesindex = speciesindex) != pl
    @test ParticleList(z; variables = vars, species = specieslist,
        speciesindex = [2, 1, 1, 2, 2]) != pl

    # a list built without a species holds one species, with charge and mass one
    pld = ParticleList(z; variables = vars)
    @test pld.species == [Species(:default, one(T), one(T))]
    @test pld.speciesindex == ones(Int, np)
    @test charge(pld, 1) == one(T)
    @test mass(pld, 1) == one(T)
    @test species(pld, 1).name === :default
    @test vec(collect(chargeweights(pld))) == collect(pld.w)

    # an empty species table with np ≥ 1 throws through the out-of-range check
    @test_throws ArgumentError ParticleList(z; variables = vars, species = Species[])

    # an empty list builds, with and without a species
    z0 = rand(T, nd, 0)
    @test length(ParticleList(z0; variables = vars, species = Species[])) == 0
    @test length(ParticleList(z0; variables = vars)) == 0

    # the conversion to the list's element type re-checks the mass
    if T === Float32
        @test_throws ArgumentError ParticleList(z; variables = vars,
            species = [Species(:n, 1.0, 1e-50)],
            speciesindex = ones(Int, np))
    end
end

# the charge-weighted weights, and a deposit that uses them
@testset "chargeweights" begin
    np = 5
    x = [0.4, 0.6, 1.4, 1.6, 1.9]
    v = zeros(np)
    w = [0.25, 0.5, 1.0, 2.0, 4.0]
    specieslist = [Species(:e, -1, 0.5), Species(:i, 2, 4)]
    speciesindex = [1, 2, 1, 2, 2]
    pl = ParticleList(x, v, w; species = specieslist, speciesindex = speciesindex)

    cw = chargeweights(pl)
    @test cw isa AbstractMatrix{Float64}
    @test size(cw) == (1, np)
    # q_i · w_i by hand: (−1)(0.25), (2)(0.5), (−1)(1.0), (2)(2.0), (2)(4.0)
    @test collect(cw) == [-0.25 1.0 -1.0 4.0 8.0]
    @test @inferred(chargeweights(pl)[1, 1]) == -0.25
    @test cw[1, Int32(2)] == 1.0
    if Base.JLOptions().code_coverage == 0
        @test allocations(_chargeweight, pl, 1) == 0
        @test allocations(_allocating, pl, 1) > 0
    end
    @test_throws BoundsError cw[2, 1]

    # a scalar `w` row and a one-row range agree, on one matrix
    z = vcat(x', v', w')
    pl_int = ParticleList(z; variables = (x = 1, v = 2, w = 3), species = specieslist,
        speciesindex = speciesindex)
    pl_rng = ParticleList(z; variables = (x = 1, v = 2, w = 3:3), species = specieslist,
        speciesindex = speciesindex)
    @test collect(chargeweights(pl_int)) ==
          collect(chargeweights(pl_rng)) == [-0.25 1.0 -1.0 4.0 8.0]

    # `w` spanning two rows, and a list without `w`
    z4 = vcat(x', v', w', w')
    @test_throws ArgumentError chargeweights(ParticleList(z4;
        variables = (x = 1, v = 2, w = 3:4), species = specieslist, speciesindex = speciesindex))
    @test_throws ArgumentError chargeweights(ParticleList(z; variables = (x = 1, v = 2),
        species = specieslist, speciesindex = speciesindex))

    # the deposit weights each particle by q·w, onto its nearest grid point
    grid = [0.5, 1.5]
    deposit = zeros(2)
    for i in 1:np
        j = argmin(abs.(grid .- pl.list[1, i]))
        deposit[j] += cw[1, i]
    end
    # cell 1: (−1)(0.25) + (2)(0.5) = 0.75;  cell 2: (−1)(1.0) + (2)(2.0) + (2)(4.0) = 11.0
    @test deposit == [0.75, 11.0]
end

# the species table and the index survive the HDF5 round trip
@testset "HDF5 round trip of the species table ($T)" for T in (Float32, Float64)
    np = 5
    nd = 3
    vars = (x = 1, v = 2, w = 3)
    z = rand(T, nd, np)
    specieslist = [Species(:e, -1, T(0.5)), Species(:i, 2, 4)]
    speciesindex = [1, 2, 1, 2, 2]
    pl = ParticleList(z; variables = vars, species = specieslist, speciesindex = speciesindex)

    mktempdir() do dir
        f = joinpath(dir, "species.h5")
        h5open(f, "w") do file
            ParticleMethods.h5save(file, pl)
        end
        @test ParticleList(f) == pl

        # the datasets are written in the element type of the list, `index` as `Int`
        h5open(f, "r") do file
            @test eltype(read(file["species/charge"])) === T
            @test eltype(read(file["species/mass"])) === T
            @test eltype(read(file["species/index"])) === Int
            @test read(file["species/name"]) isa Vector{String}
        end
    end
end

# a file whose species group is gone loads with the default species
@testset "a file without a species group loads with the default" begin
    np = 5
    z = rand(3, np)
    vars = (x = 1, v = 2, w = 3)
    pl = ParticleList(
        z; variables = vars, species = [Species(:e, -1, 0.5), Species(:i, 2, 4)],
        speciesindex = [1, 2, 1, 2, 2])

    mktempdir() do dir
        f = joinpath(dir, "stripped.h5")
        h5open(f, "w") do file
            ParticleMethods.h5save(file, pl)
        end
        h5open(f, "r+") do file
            delete_object(file, "species")
        end
        @test ParticleList(f) == ParticleList(z; variables = vars)
    end
end

# the species group is written under `path`, beside `particles`
@testset "the species group follows path" begin
    np = 5
    z = rand(3, np)
    vars = (x = 1, v = 2, w = 3)
    plA = ParticleList(
        z; variables = vars, species = [Species(:e, -1, 0.5), Species(:i, 2, 4)],
        speciesindex = [1, 2, 1, 2, 2])
    plB = ParticleList(
        z; variables = vars, species = [Species(:p, 3, 7), Species(:q, -4, 2)],
        speciesindex = [2, 1, 2, 1, 2])

    mktempdir() do dir
        f = joinpath(dir, "nested.h5")
        h5open(f, "w") do file
            ParticleMethods.h5save(file, plA; path = "a")
            ParticleMethods.h5save(file, plB; path = "b")
        end
        @test ParticleList(f, "a") == plA
        @test ParticleList(f, "b") == plB

        # a nested species group stripped from one path leaves the other alone
        h5open(f, "r+") do file
            delete_object(file, "a/species")
        end
        @test ParticleList(f, "a") == ParticleList(z; variables = vars)
        @test ParticleList(f, "b") == plB
    end
end

# One barrier per property name: a name passed at run time does not constant-propagate, so each
# barrier holds its name as a literal.
_getx(pl) = pl.x
_geta(pl) = pl.a
_getlist(pl) = pl.list
_getparticles(pl) = pl.particles
_hasx(pl) = hasproperty(pl, :x)
_hasa(pl) = hasproperty(pl, :a)
_haslist(pl) = hasproperty(pl, :list)
_hasnone(pl) = hasproperty(pl, :none)

_getparticle(pl, i) = pl[i]
_getelement(pl, i, j) = pl[i, j]
_setparticle!(pl, p, i) = setindex!(pl, p, i)
_setelement!(pl, v, i, j) = setindex!(pl, v, i, j)
# the colon is a literal here: a `Colon()` passed through the barrier reads 32 B on Julia 1.13
_setcolumn!(pl, X, j) = setindex!(pl, X, :, j)

# `iterate` returns a `Union` with `Nothing`, and a barrier that returns it reads 192 B on
# Julia 1.13; these barriers consume the result and return the state, or 0 at the end of the
# iteration.
_firststate(pl) = (r = iterate(pl); r === nothing ? 0 : r[2])
_nextstate(pl, s) = (r = iterate(pl, s); r === nothing ? 0 : r[2])

# the accessors, the scalar indexing, the column assignment and the iteration of a list
@testset "accessors, indexing and iteration ($T)" for T in (Float32, Float64)
    np = 4
    nd = 4
    vars = (x = 1:2, v = 3, w = 4)
    params = (a = 1, b = T(2))
    z = rand(T, nd, np)
    pl = ParticleList(z; variables = vars, parameters = params)
    pl0 = ParticleList(rand(T, nd, 0); variables = vars, parameters = params)
    p = pl[2]
    X = rand(T, nd)

    # properties: a variable, a parameter and two field names
    @test @inferred(_getx(pl)) == view(z, 1:2, :)
    @test @inferred(_geta(pl)) === 1
    @test @inferred(_getlist(pl)) === z
    @test @inferred(_getparticles(pl)) === getfield(pl, :particles)
    @test @inferred(_hasx(pl)) === true
    @test @inferred(_hasa(pl)) === true
    @test @inferred(_haslist(pl)) === true
    @test @inferred(_hasnone(pl)) === false

    # scalar indexing, scalar assignment and column assignment
    @test @inferred(_getparticle(pl, 2)) == p
    @test @inferred(_getelement(pl, 3, 2)) === z[3, 2]
    @test @inferred(_setparticle!(pl, p, 2)) === pl.particles
    @test @inferred(_setelement!(pl, T(7), 3, 2)) === z
    @test z[3, 2] === T(7)
    @test @inferred(_setcolumn!(pl, X, 2)) === z
    @test z[:, 2] == X

    # the array interface, on a list of np particles and on an empty list
    @test @inferred(length(pl)) === np
    @test @inferred(length(pl0)) === 0
    @test @inferred(size(pl)) === (nd, np)
    @test @inferred(eachindex(pl)) === Base.OneTo(np)
    @test @inferred(eachindex(pl0)) === Base.OneTo(0)
    @test @inferred(eltype(pl)) === T
    @test @inferred(eachparticle(pl)) === pl.particles

    # iteration: the first call, a call with the state the first returned, the end, and an empty
    # list
    s = iterate(pl)[2]
    @test @inferred(Nothing, iterate(pl)) == (pl[1], 2)
    @test @inferred(Nothing, iterate(pl, s)) == (pl[2], 3)
    @test @inferred(Nothing, iterate(pl, np + 1)) === nothing
    @test @inferred(Nothing, iterate(pl0)) === nothing
    @test _firststate(pl) == 2
    @test _nextstate(pl, s) == 3
    @test _nextstate(pl, np + 1) == 0
    @test _firststate(pl0) == 0

    if Base.JLOptions().code_coverage == 0
        @test allocations(_getx, pl) == 0
        @test allocations(_geta, pl) == 0
        @test allocations(_getlist, pl) == 0
        @test allocations(_getparticles, pl) == 0
        @test allocations(_hasx, pl) == 0
        @test allocations(_hasa, pl) == 0
        @test allocations(_haslist, pl) == 0
        @test allocations(_hasnone, pl) == 0

        @test allocations(_getparticle, pl, 2) == 0
        @test allocations(_getelement, pl, 3, 2) == 0
        @test allocations(_setparticle!, pl, p, 2) == 0
        @test allocations(_setelement!, pl, T(7), 3, 2) == 0
        @test allocations(_setcolumn!, pl, X, 2) == 0

        @test allocations(length, pl) == 0
        @test allocations(length, pl0) == 0
        @test allocations(size, pl) == 0
        @test allocations(eachindex, pl) == 0
        @test allocations(eachindex, pl0) == 0
        @test allocations(eltype, pl) == 0
        @test allocations(eachparticle, pl) == 0

        @test allocations(_firststate, pl) == 0
        @test allocations(_nextstate, pl, s) == 0
        @test allocations(_nextstate, pl, np + 1) == 0
        @test allocations(_firststate, pl0) == 0

        # the positive control, on the barrier of each arity above
        @test allocations(_allocating, pl) > 0
        @test allocations(_allocating, pl, 2) > 0
        @test allocations(_allocating, pl, 3, 2) > 0
        @test allocations(_allocating, pl, T(7), 3, 2) > 0
    end
end
