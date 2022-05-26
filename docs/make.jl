using ParticleMethods
using Documenter
using Weave

ENV["GKSwstype"] = "100"


weave("src/poisson.jmd",
         out_path = "src",
         doctype = "github")


makedocs(;
    modules=[ParticleMethods],
    authors="Michael Kraus",
    repo="https://github.com/JuliaGNI/ParticleMethods.jl/blob/{commit}{path}#L{line}",
    sitename="ParticleMethods.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://juliagni.github.io/ParticleMethods.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Poisson Solvers" => "poisson.md",
        "Library" => "library.md",
    ],
)

deploydocs(;
    repo="github.com/JuliaGNI/ParticleMethods.jl",
)
