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

# A function barrier with concrete arguments, for the allocation assertions: the first call warms
# the method and the second is measured.
allocations(f::F, a::A) where {F, A} = (f(a); @allocated f(a))
allocations(f::F, a::A, i::I) where {F, A, I} = (f(a, i); @allocated f(a, i))

_allocating(pl, i) = zeros(i)
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
    @test allocations(charge, pl, 1) == 0
    @test allocations(mass, pl, 1) == 0
    @test allocations(species, pl, 1) == 0
    @test allocations(_allocating, pl, 1) > 0

    # an `Int32` index works, on the accessors and in the keyword
    @test charge(pl, Int32(2)) == charge(pl, 2)
    @test mass(pl, Int32(2)) == mass(pl, 2)
    @test species(pl, Int32(2)) === species(pl, 2)
    @test ParticleList(z; variables = vars, species = specieslist,
        speciesindex = Int32[1, 2, 1, 2, 2]) == pl

    # construction throws in three cases
    @test_throws ArgumentError ParticleList(z; variables = vars, species = specieslist,
        speciesindex = [1, 2, 1, 2])
    @test_throws ArgumentError ParticleList(z; variables = vars, species = specieslist,
        speciesindex = [1, 2, 3, 1, 2])
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
    @test allocations(_chargeweight, pl, 1) == 0
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
        pl2 = ParticleList(f)
        @test charge.(Ref(pl2), 1:np) == charge.(Ref(pl), 1:np)
        @test mass.(Ref(pl2), 1:np) == mass.(Ref(pl), 1:np)
        @test pl2.speciesindex == pl.speciesindex
        @test pl2.species == pl.species
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
        pl2 = ParticleList(f)
        @test species(pl2, 1).name === :default
        @test charge(pl2, 1) == 1.0
        @test mass(pl2, 1) == 1.0
        @test pl2.speciesindex == ones(Int, np)
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
        a = ParticleList(f, "a")
        b = ParticleList(f, "b")
        @test charge.(Ref(a), 1:np) == charge.(Ref(plA), 1:np)
        @test mass.(Ref(a), 1:np) == mass.(Ref(plA), 1:np)
        @test a.speciesindex == plA.speciesindex
        @test charge.(Ref(b), 1:np) == charge.(Ref(plB), 1:np)
        @test mass.(Ref(b), 1:np) == mass.(Ref(plB), 1:np)
        @test b.speciesindex == plB.speciesindex
        @test a.species != b.species

        # a nested species group stripped from one path leaves the other alone
        h5open(f, "r+") do file
            delete_object(file, "a/species")
        end
        a2 = ParticleList(f, "a")
        b2 = ParticleList(f, "b")
        @test species(a2, 1).name === :default
        @test charge.(Ref(b2), 1:np) == charge.(Ref(plB), 1:np)
    end
end
