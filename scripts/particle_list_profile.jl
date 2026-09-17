using ParticleMethods
using Profile

const np = 1000000
const nd = 6

const vars = (x = 1:3, v = 4:6, z = 1:6)
const params = (a = 1, b = 1.0)

const pl = ParticleList(rand(nd, np); variables = vars, parameters = params)

function test_particlelist(pl)
    for i in eachindex(pl.x, pl.v)
        pl.x[i] += pl.v[i]
    end
end

# Warmup
test_particlelist(pl)

# Setup profiler
Profile.clear()
Profile.clear_malloc_data()

# Profile run
test_particlelist(pl)
