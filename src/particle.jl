
import Base.hasproperty, Base.getproperty


struct Particle{T, ST <: AbstractVector{T}, VT <: NamedTuple, PT <: NamedTuple}
    state::ST
    views::VT
    params::PT

    function Particle(state, views, params)
        @assert isdisjoint(fieldnames(Particle), keys(views))
        @assert isdisjoint(fieldnames(Particle), keys(params))
        @assert isdisjoint(keys(views), keys(params))
        new{eltype(state), typeof(state), typeof(views), typeof(params)}(state, views, params)
    end
end

function Particle(state; variables = NamedTuple(), parameters = NamedTuple())
    views = map(idx_range -> view(state, idx_range), variables)
    Particle(state, views, parameters)
end

function Particle(DT, len; kwargs...)
    Particle(MVector{len}(zeros(DT, len)); kwargs...)
end

@inline function Base.hasproperty(::Particle{T,ST,VT,PT}, s::Symbol) where {T,ST,VT,PT}
    hasfield(VT, s) || hasfield(PT, s) || hasfield(Particle, s)
end

@inline function Base.getproperty(p::Particle{T,ST,VT,PT}, s::Symbol) where {T, ST, VT, PT}
    if hasfield(VT, s)
        return getfield(p, :views)[s]
    elseif hasfield(PT, s)
        return getfield(p, :params)[s]
    else
        return getfield(p, s)
    end
end
