module ParticleMethods

using HDF5
using HDF5: H5DataStore

using StaticArrays: MVector


include("hdf5_utils.jl")


include("particle.jl")

export Particle


include("particle_list.jl")

export ParticleList
export eachparticle

end # module
