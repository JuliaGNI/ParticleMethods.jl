
using FastGaussQuadrature
using LinearAlgebra

struct PBSpline{T}
    p :: Int       # spline degree
    nₕ :: Int      # number of splines
    L :: T         # domain length
    h :: T         # element width

    function PBSpline(p::Int, nₕ::Int, L::T, h::T) where {T}
        @assert nₕ > p
        new{T}(p, nₕ, L, h)
    end
end

# convenience constructor
PBSpline(p::Int, nₕ::Int, L) = PBSpline(p, nₕ, L, L/nₕ)

Base.size(S::PBSpline) = (1,)
Base.length(S::PBSpline) = 1
Base.iterate(S::PBSpline, state=1) = state > 1 ? nothing : (S, state+1)

@inline function eval_unitPBSpline(p::Int, x::T) where {T}
    if p == 0
        return zero(T) <= x < one(T) ? one(T) : zero(T)
    elseif x > p+1
        return zero(T)
    else
        return x/p * eval_unitPBSpline(p-1,x) + (p+1-x)/p * eval_unitPBSpline(p-1,x-1)
    end
end

@inline function eval_PBSpline(S::PBSpline{T}, i::Int, x::T) where {T}
    x /= S.h; x -= (i-1)
    # periodicity
    while x < zero(T)  x += S.nₕ end
    while x > S.nₕ     x -= S.nₕ end
    return eval_unitPBSpline(S.p, x)
end

function eval_PBSBasis(c::Array{T}, S::PBSpline{T}, x::T) where {T}
    @assert length(c) == S.nₕ
    r::T = 0
    for j in 1:S.nₕ
        r += c[j] * eval_PBSpline(S, j, x)
    end
    return r
end

function eval_PBSBasis(c::Array{T}, S::PBSpline{T}, x::Array{T}, r = zero(x)) where {T}
    @assert length(c) == S.nₕ
    for i in eachindex(r,x)
        r[i] = eval_PBSBasis(c, S, x[i])
    end
    return r
end

# evaluation point(s) x, degree p
function eval_deriv_PBSpline(S::PBSpline{T}, i::Int, x::T) where {T}
    x /= S.h; x -= i-1
    # periodicity
    while x < zero(T)  x += S.nₕ end
    while x > S.nₕ     x -= S.nₕ end
    1/S.h * (eval_unitPBSpline(S.p-1, x) - eval_unitPBSpline(S.p-1, x-1 < 0 ? x-1+S.nₕ : x-1) )
end

function eval_deriv_PBSBasis(c::Array{T}, S::PBSpline{T}, x::T) where {T}
    @assert length(c) == S.nₕ
    r::T = 0
    for j in 1:S.nₕ
        r += c[j] * eval_deriv_PBSpline(S, j, x)
    end
    return r
end

function eval_deriv_PBSBasis(c::Array{T}, S::PBSpline{T}, x::Array{T}, r = zero(x)) where {T}
    for i in eachindex(x)
        r[i] = eval_deriv_PBSBasis(c, S, x[i])
    end
    return r
end

function integrate_gausslegendre(f, a::T, b::T, nq::Int) where {T}
    nodes, weights = gausslegendre(nq)
    return 0.5*(b-a)*dot(weights, f( 0.5 .* (b-a) .* nodes .+ 0.5 .* (a+b) ) )
    # 0.5 * (b-a) * mapreduce(q -> q[2] * f( 0.5 * (b-a) * q[1] + 0.5 * (a+b) ), +, zip(gausslegendre(nq)...))
    # 0.5 * (b-a) * mapreduce((c,w) -> w * f( 0.5 * (b-a) * c + 0.5 * (a+b) ), +, zip(gausslegendre(nq)...))
end

function rhs_PBSBasis(f, S::PBSpline{T}, q = S.p+1, rhs = zeros(T, S.nₕ)) where {T}
    for i in 1:S.nₕ
        for k in 0:S.p
            if i+k <= S.nₕ
                rhs[i] += integrate_gausslegendre(x -> (eval_PBSpline(S, i, x) .* f(x)), (i-1+k)*S.h, (i+k)*S.h, q)
            else
                rhs[i] += integrate_gausslegendre(x -> (eval_PBSpline(S, i, x) .* f(x)), (i-1+k-S.nₕ)*S.h, (i+k-S.nₕ)*S.h, q)
            end
        end
    end
    return rhs
end

function rhs_particles_PBSBasis(x::Vector{T}, w::Vector{T}, S::PBSpline{T}, rhs = zeros(T, S.nₕ)) where {T}
    for i in eachindex(rhs)
        rhs[i] = 0
        for j in eachindex(w,x)
            rhs[i] += w[j] * eval_PBSpline(S, i, x[j])
        end
    end
    return rhs
end
