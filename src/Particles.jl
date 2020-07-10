module Particles

using FFTW
using StatsBase

export PoissonSolver, solve!, eval_field

include("poisson.jl")

end # module
