using ParticleMethods
using Documenter

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
        "Library" => "library.md",
    ],
)

deploydocs(;
    repo="github.com/JuliaGNI/ParticleMethods.jl",
)
