var documenterSearchIndex = {"docs":
[{"location":"library/","page":"Library","title":"Library","text":"CurrentModule = Particles","category":"page"},{"location":"library/#Particles-Library-Functions","page":"Library","title":"Particles Library Functions","text":"","category":"section"},{"location":"library/","page":"Library","title":"Library","text":"Modules = [Particles]","category":"page"},{"location":"library/#Particles.ParticleList","page":"Library","title":"Particles.ParticleList","text":"Particles struct. fields: position x, velocity v, weight w\n\n\n\n\n\n","category":"type"},{"location":"library/#Particles.draw_g_accept_reject-Union{Tuple{T}, Tuple{Int64, Function, NamedTuple}} where T","page":"Library","title":"Particles.draw_g_accept_reject","text":"Returns particles drawn from g for the bump-on-tail case.\n\ninput: nb. pf particles Nₚ, x-marginal function gₓ, parameters μ output: Particles struct\n\n\n\n\n\n","category":"method"},{"location":"library/#Particles.draw_g_importance_sampling-Union{Tuple{T}, Tuple{Int64, Function, NamedTuple}} where T","page":"Library","title":"Particles.draw_g_importance_sampling","text":"Returns particles drawn from g for the bump-on-tail case.\n\ninput: nb. pf particles Nₚ, x-marginal function gₓ, parameters μ output: Particles struct\n\n\n\n\n\n","category":"method"},{"location":"library/#Particles.eval_density","page":"Library","title":"Particles.eval_density","text":"Evaluates the charge density field\n\n\n\n\n\n","category":"function"},{"location":"library/#Particles.eval_field","page":"Library","title":"Particles.eval_field","text":"Evaluates the electric field\n\n\n\n\n\n","category":"function"},{"location":"library/#Particles.eval_potential","page":"Library","title":"Particles.eval_potential","text":"Evaluates the electrostatic potential\n\n\n\n\n\n","category":"function"},{"location":"library/#Particles.solve!","page":"Library","title":"Particles.solve!","text":"Solves the Poisson equation for periodic boundary conditions\n\nfunction solve!(p::PoissonSolver, x::AbstractVector, w::AbstractVector) end\n\n\n\n\n\n","category":"function"},{"location":"library/#Particles.weight_f-Tuple{Any, Any, Any}","page":"Library","title":"Particles.weight_f","text":"Returns re-weighted particles according to new parameters.\n\ninput: Particles struct P₀, proposal distribution function g, target distribution function f output: Particles struct\n\n\n\n\n\n","category":"method"},{"location":"poisson/","page":"Poisson Solvers","title":"Poisson Solvers","text":"CurrentModule = Particles","category":"page"},{"location":"poisson/#Poisson-Solvers","page":"Poisson Solvers","title":"Poisson Solvers","text":"","category":"section"},{"location":"poisson/","page":"Poisson Solvers","title":"Poisson Solvers","text":"using Distributions\nusing Particles\nusing Plots\nusing Random\nusing StatsBase\n\nnp = 10000\nxp = zeros(np)\nrand!(MersenneTwister(0), Normal(0.5, 0.1), xp)\n\nx = LinRange(0, 1, 100)\ny = fit(Histogram, xp, x).weights ./ length(x)\nx = x[1:end-1] .+ (x[2] - x[1]) / 2\n\nplot(x, y; xlims = (0,1), xlabel = \"x\", ylabel = \"n\", legend = :none)","category":"page"},{"location":"poisson/","page":"Poisson Solvers","title":"Poisson Solvers","text":"(Image: )","category":"page"},{"location":"poisson/#FFT-Solver","page":"Poisson Solvers","title":"FFT Solver","text":"","category":"section"},{"location":"poisson/","page":"Poisson Solvers","title":"Poisson Solvers","text":"p = PoissonSolverFFT(32, 1.0)\nParticles.solve!(p, xp);","category":"page"},{"location":"poisson/","page":"Poisson Solvers","title":"Poisson Solvers","text":"plot(x, eval_density(p, x); xlims = (0,1), xlabel = \"x\", ylabel = \"ρ(x)\", legend = :none)","category":"page"},{"location":"poisson/","page":"Poisson Solvers","title":"Poisson Solvers","text":"(Image: )","category":"page"},{"location":"poisson/","page":"Poisson Solvers","title":"Poisson Solvers","text":"plot(x, eval_potential(p, x); xlims = (0,1), xlabel = \"x\", ylabel = \"ϕ(x)\", legend = :none)","category":"page"},{"location":"poisson/","page":"Poisson Solvers","title":"Poisson Solvers","text":"(Image: )","category":"page"},{"location":"poisson/","page":"Poisson Solvers","title":"Poisson Solvers","text":"plot(x, eval_field(p, x); xlims = (0,1), xlabel = \"x\", ylabel = \"E(x)\", legend = :none)","category":"page"},{"location":"poisson/","page":"Poisson Solvers","title":"Poisson Solvers","text":"(Image: )","category":"page"},{"location":"poisson/#B-Spline-Solver","page":"Poisson Solvers","title":"B-Spline Solver","text":"","category":"section"},{"location":"poisson/","page":"Poisson Solvers","title":"Poisson Solvers","text":"p = PoissonSolverPBSplines(3, 32, 1.0)\nParticles.solve!(p, xp);","category":"page"},{"location":"poisson/","page":"Poisson Solvers","title":"Poisson Solvers","text":"plot(x, eval_density(p, x); xlims = (0,1), xlabel = \"x\", ylabel = \"ρ(x)\", legend = :none)","category":"page"},{"location":"poisson/","page":"Poisson Solvers","title":"Poisson Solvers","text":"(Image: )","category":"page"},{"location":"poisson/","page":"Poisson Solvers","title":"Poisson Solvers","text":"plot(x, eval_potential(p, x); xlims = (0,1), xlabel = \"x\", ylabel = \"ϕ(x)\", legend = :none)","category":"page"},{"location":"poisson/","page":"Poisson Solvers","title":"Poisson Solvers","text":"(Image: )","category":"page"},{"location":"poisson/","page":"Poisson Solvers","title":"Poisson Solvers","text":"plot(x, eval_field(p, x); xlims = (0,1), xlabel = \"x\", ylabel = \"E(x)\", legend = :none)","category":"page"},{"location":"poisson/","page":"Poisson Solvers","title":"Poisson Solvers","text":"(Image: )","category":"page"},{"location":"","page":"Home","title":"Home","text":"CurrentModule = Particles","category":"page"},{"location":"#Particles.jl","page":"Home","title":"Particles.jl","text":"","category":"section"},{"location":"#Installation","page":"Home","title":"Installation","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Particles.jl and all of its dependencies can be installed via the Julia REPL by typing ","category":"page"},{"location":"","page":"Home","title":"Home","text":"]add Particles","category":"page"},{"location":"#Data-Stuctures","page":"Home","title":"Data Stuctures","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"The particles package provides flexible data structures for particles and particle lists. While particle states are stored as vectors and particle lists as matrices, the package provides convenient access to different fields in the state of a particle as well as to parameters.","category":"page"},{"location":"#Particle","page":"Home","title":"Particle","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"A typical particle state could be","category":"page"},{"location":"","page":"Home","title":"Home","text":"s = | x | v |w|","category":"page"},{"location":"","page":"Home","title":"Home","text":"where s is a vector of length 7, x is the particle position with length 3, v is the particle velocity with length 3, and w is the particle weight, which is scalar. In order to create a particle with such a structure, one can either initialize the particle with a prescribed data type,","category":"page"},{"location":"","page":"Home","title":"Home","text":"p = Particle(Float64, 7; variables = (x = 1:3, v = 4:6, z = 1:6, w = 7))","category":"page"},{"location":"","page":"Home","title":"Home","text":"or  with a prescribed state,","category":"page"},{"location":"","page":"Home","title":"Home","text":"p = Particle(rand(7); variables = (x = 1:3, v = 4:6, z = 1:6, w = 7))","category":"page"},{"location":"","page":"Home","title":"Home","text":"The former constructor will default to using an MVector from StaticArrays.jl to store the particle state. The latter will use whichever vector type is specified by the user.","category":"page"},{"location":"","page":"Home","title":"Home","text":"In both cases, the particle state is accessible via fields corresponding to the index ranges specified by the user:","category":"page"},{"location":"","page":"Home","title":"Home","text":"using Particles\np = Particle([1.0, 0.0, 0.0, 0.5, 0.2, 0.0, 0.1];\n             variables = (x = 1:3, v = 4:6, z = 1:6, w = 7))\np.state\np.z\np.x\np.v\np.w","category":"page"}]
}
