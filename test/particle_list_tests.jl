
using HDF5
using ParticleMethods: _sort_ntuple


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
@test_throws AssertionError ParticleList(pa; variables = (x = 1:3, v = 4:6), parameters = (a = 1, x = 2))
@test_throws AssertionError ParticleList(pa; variables = (x = 1:3, list = 4:6), parameters = (a = 1, b = 2))
@test_throws AssertionError ParticleList(pa; variables = (x = 1:3, v = 4:6), parameters = (a = 1, list = 2))


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
@test pl.particles == [Particle(view(pa, :, i); variables = _sort_ntuple(vars), parameters = params) for i in axes(pa, 2)]

# test variable views
@test pl.variables.x == [view(pa, 1:3, i) for i in axes(pa,2)]
@test pl.variables.v == [view(pa, 4:6, i) for i in axes(pa,2)]
@test pl.variables.z == [view(pa, 1:6, i) for i in axes(pa,2)]

# test parameters
@test pl.a == params.a
@test pl.b == params.b

# test array interface
@test eltype(pl) == eltype(pa)
@test length(pl) == np
@test size(pl) == (nd, np)

# test getindex methods
@test pl[1] == pl.particles[1]
@test pl[1,1] == pl.list[1,1] == pa[1,1]
@test pl[1,:] == pl.list[1,:] == pa[1,:]
@test pl[:,1] == pl.list[:,1] == pa[:,1]

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

@test plh5[1] == pl[1] # TODO activate once parameters are stored and read
@test plh5[1,1] == pl[1,1]
@test plh5[1,:] == pl[1,:]
@test plh5[:,1] == pl[:,1]
