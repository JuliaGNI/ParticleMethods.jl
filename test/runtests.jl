using SafeTestsets

const GROUPS = isempty(ARGS) ? ["core", "slow"] : ARGS

if "core" in GROUPS
    @safetestset "Aqua" include("quality/aqua.jl")
    @safetestset "Particles" include("particle.jl")
    @safetestset "Particle Lists" include("particle_list.jl")
    @safetestset "Defects" include("defects.jl")
end
