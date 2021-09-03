module Particles

"""
Particles struct.
fields: positon x, velocity v, weight w
"""
struct ParticleList{T}
    x::Vector{T}
    v::Vector{T}
    w::Vector{T}
end

export ParticleList


include("poisson.jl")

export PoissonSolver
export solve!, eval_density, eval_potential, eval_field


include("poisson_fft.jl")

export PoissonSolverFFT


include("splines.jl")
include("poisson_splines.jl")

export PoissonSolverPBSplines


include("integrate_vlasov_poisson.jl")

export VPIntegratorParameters, VPIntegratorCache, integrate_vp


include("sampling.jl")

export draw_g_accept_reject, draw_g_importance_sampling, weight_f


include("visualisation.jl")

export plot_particles, plot_distribution


include("bump_on_tail.jl")

end # module
