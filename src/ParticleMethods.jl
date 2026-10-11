"""
    ParticleMethods

Data structures for particles and particle lists: [`Particle`](@ref) and
[`ParticleList`](@ref), with named access to parts of the state and to parameters.
"""
module ParticleMethods

using HDF5
using HDF5: H5DataStore

include("hdf5_utils.jl")

include("species.jl")

export Species
export charge
export mass
export species

include("particle.jl")

export Particle

include("particle_list.jl")

export ParticleList
export eachparticle
export chargeweights

end # module
