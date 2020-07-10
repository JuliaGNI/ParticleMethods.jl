
struct PoissonSolver{DT <: Real}
    nx::Int
    Δx::DT
    xgrid::Vector{DT}
    ρ::Vector{DT}
    ϕ::Vector{DT}

    function PoissonSolver{DT}(nx::Int) where {DT}
        Δx = 1/nx
        xgrid = collect(0:Δx:1)
        new(nx, Δx, xgrid, zeros(DT, nx), zeros(DT, nx))
    end
end


function solve!(p::PoissonSolver{DT}, x::AbstractVector{DT}) where {DT}
    h = fit(Histogram, mod.(x, 1), p.xgrid)
    p.ρ .= h.weights ./ length(x)
    ρ̂ = rfft(p.ρ)
    k² = [(i-1)^2 for i in eachindex(ρ̂)]
    ϕ̂ = - ρ̂ ./ k²
    ϕ̂[1] = 0
    p.ϕ .= irfft(ϕ̂, length(p.ρ))
    return p
end


function eval_field(p::PoissonSolver{DT}, x::DT) where {DT}
    y = mod(x, one(x))
    i1 = floor(Int, y / p.Δx) + 1
    i2 = mod( ceil(Int, y / p.Δx), p.nx) + 1
    i1 == i2 && (i1 = i1-1)
    i1 == 0 && (i1 = lastindex(p.ϕ))
    return - (p.ϕ[i2] - p.ϕ[i1]) / p.Δx
end
