module Particles



include("poisson.jl")

export PoissonSolver
export solve!, eval_density, eval_potential, eval_field


include("poisson_fft.jl")

export PoissonSolverFFT


include("splines.jl")
include("poisson_splines.jl")

export PoissonSolverPBSplines
end # module
