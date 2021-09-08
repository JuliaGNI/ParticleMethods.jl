
using FFTW
using StatsBase

struct PoissonSolverFFT{DT <: Real} <: PoissonSolver{DT}
    nx::Int
    Δx::DT
    xgrid::Vector{DT}
    cells::Vector{DT}
    L::DT
    ρ::Vector{DT}
    ϕ::Vector{DT}

    function PoissonSolverFFT{DT}(nx::Int, L::DT) where {DT}
        Δx = L/(nx+1)
        xgrid = LinRange(Δx/2, L-Δx/2, nx)
        cells = LinRange(0, L, nx+1)
        new(nx, Δx, xgrid, cells, L, zeros(DT, nx), zeros(DT, nx))
    end
end

PoissonSolverFFT(nx::Int, L::DT) where {DT} = PoissonSolverFFT{DT}(nx, L)

Base.length(p::PoissonSolverFFT) = p.nx

function solve!(p::PoissonSolverFFT{DT}, x::AbstractVector{DT}, w::AbstractVector{DT} = one.(x) ./ length(x)) where {DT}
    h = fit(Histogram, mod.(x, p.L), p.cells)
    p.ρ .= h.weights ./ length(x)
    ρ̂ = rfft(p.ρ)
    k² = [(i-1)^2 for i in eachindex(ρ̂)]
    ϕ̂ = - ρ̂ ./ k²
    ϕ̂[1] = 0
    p.ϕ .= irfft(ϕ̂, length(p.ρ))
    return p
end


function get_indices(p::PoissonSolverFFT, x)
    y = mod(x, p.L)

    i1 = floor(Int, y / p.Δx)
    i2 = mod( ceil(Int, y / p.Δx) - 1, p.nx) + 1

    i1 == 0 && (i1 = p.nx)
    i2 == 0 && (i2 = p.nx)

    i1 == p.nx+1 && (i1 = 1)
    i2 == p.nx+1 && (i2 = 1)

    return (i1, i2)
end

function get_index(p::PoissonSolverFFT, x)
    i1, i2 = get_indices(p, x)
    return (abs(p.xgrid[i1] - x) ≤ abs(p.xgrid[i2] - x) ? i1 : i2)
end


function eval_density(p::PoissonSolverFFT{DT}, x::DT) where {DT}
    p.ρ[get_index(p, x)]
end

function eval_potential(p::PoissonSolverFFT{DT}, x::DT) where {DT}
    p.ϕ[get_index(p, x)]
end

function eval_field(p::PoissonSolverFFT{DT}, x::DT) where {DT}
    i1, i2 = get_indices(p, x)
    return - (p.ϕ[i2] - p.ϕ[i1]) / p.Δx
end
