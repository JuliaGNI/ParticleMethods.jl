module ParticleMethods

using HDF5
using HDF5: H5DataStore

using PoissonSolvers

using StaticArrays: MVector


include("hdf5_utils.jl")


include("particle.jl")

export Particle


include("particle_list.jl")

export ParticleList
export eachparticle


include("vlasov_poisson.jl")

export VPIntegratorParameters, VPIntegratorCache, integrate_vp!


include("sampling.jl")

export draw_g_accept_reject, draw_g_importance_sampling, weight_f


include("visualisation.jl")

export plot_particles, plot_distribution


include("bump_on_tail.jl")

end # module
