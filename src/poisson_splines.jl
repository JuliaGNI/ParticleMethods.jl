
using LinearAlgebra

function massmatrix(S::PBSpline{T}, q = S.p+1) where {T}
    M = zeros(T, S.nₕ, S.nₕ)
    for i in 1:S.nₕ
        for k in 0:S.p
            M[1,i] += integrate_gausslegendre(x -> (eval_PBSpline.(S, 1, x) .* eval_PBSpline.(S, i, x)),
                                                k*S.h, (k+1)*S.h, q)
        end
    end
    for j in 2:S.nₕ
        for i in 1:S.nₕ
            M[j,i] = M[j-1,(i-1+S.nₕ-1)%S.nₕ + 1]
        end
    end
    return M
end

function stiffnessmatrix(S::PBSpline{T}, q = S.p) where {T}
    K = zeros(T, S.nₕ, S.nₕ)
    for i in 1:S.nₕ
        for k in 0:S.p
            K[1,i] += integrate_gausslegendre(x -> (eval_deriv_PBSpline.(S, 1, x) .* eval_deriv_PBSpline.(S, i, x) ),
                                                k*S.h, (k+1)*S.h, q)
        end
    end
    for j in 2:S.nₕ
        for i in 1:S.nₕ
            K[j,i] = K[j-1,(i-1+S.nₕ-1)%S.nₕ + 1]
        end
    end
    return K
end


struct PoissonSolverPBSplines{DT <: Real} <: PoissonSolver{DT}
    p::Int
    nx::Int
    Δx::DT
    xgrid::Vector{DT}
    L::DT

    bspl::PBSpline{DT}

    M::Matrix{DT}
    S::Matrix{DT}
    Ŝ::Matrix{DT}
    
    P::Matrix{DT}
    R::Matrix{DT}

    ρ::Vector{DT}
    ϕ::Vector{DT}
    rhs::Vector{DT}

    Mfac::LU{DT, Matrix{DT}}
    Sfac::LU{DT, Matrix{DT}}

    function PoissonSolverPBSplines{DT}(p::Int, nₕ::Int, L::DT) where {DT}
        Δx = L/nₕ
        xgrid = collect(0:Δx:1)

        bspl = PBSpline(p, nₕ, L)
        M = massmatrix(bspl)
        S = stiffnessmatrix(bspl)

        A = ones(nₕ)
        R = A * A' / (A' * A)
        P = Matrix(I, nₕ, nₕ) .- R
        Ŝ = S .+ R

        new(p, nₕ, Δx, xgrid, L, bspl, M, S, Ŝ, P, R, 
            zeros(DT,nₕ), zeros(DT,nₕ), zeros(DT,nₕ), 
            lu(M), lu(Ŝ))
    end
end

PoissonSolverPBSplines(p::Int, nₕ::Int, L::DT) where {DT} = PoissonSolverPBSplines{DT}(p, nₕ, L)


function solve!(p::PoissonSolverPBSplines{DT}, x::AbstractVector{DT}, w::AbstractVector{DT} = one.(x) ./ length(x)) where {DT}
    rhs_particles_PBSBasis(x, w, p.bspl, p.rhs)
    ldiv!(p.ϕ, p.Sfac, - p.P * p.rhs)
    ldiv!(p.ρ, p.Mfac, p.rhs)
    return p
end


function eval_density(p::PoissonSolverPBSplines{DT}, x::DT) where {DT}
    eval_PBSBasis(p.ρ, p.bspl, x)
end

function eval_potential(p::PoissonSolverPBSplines{DT}, x::DT) where {DT}
    eval_PBSBasis(p.ϕ, p.bspl, x)
end

function eval_field(p::PoissonSolverPBSplines{DT}, x::DT) where {DT}
    - eval_deriv_PBSBasis(p.ϕ, p.bspl, x)
end
