using Particles
using Documenter
using Weave

ENV["GKSwstype"] = "100"


weave("src/poisson.jmd",
         out_path = "src",
         doctype = "github")


makedocs(;
    modules=[Particles],
    authors="Michael Kraus",
    repo="https://github.com/JuliaGNI/Particles.jl/blob/{commit}{path}#L{line}",
    sitename="Particles.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://juliagni.github.io/Particles.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Poisson Solvers" => "poisson.md",
        "Library" => "library.md",
    ],
)

deploydocs(;
    repo="github.com/JuliaGNI/Particles.jl",
)
