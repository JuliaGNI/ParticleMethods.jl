"""
    ParticleMethods

Data structures for particles and particle lists: [`Particle`](@ref) and
[`ParticleList`](@ref), with named access to parts of the state and to parameters.
"""
module ParticleMethods

using HDF5
using HDF5: H5DataStore

include("hdf5_utils.jl")

include("particle.jl")

export Particle

include("particle_list.jl")

export ParticleList
export eachparticle

end # module
