
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

Base.:(==)(p1::Particle{T1,ST1}, p2::Particle{T2,ST2}) where {T1,T2,ST1,ST2} = (
                        T1 == T2 && ST1 == ST2
                     && p1.state  == p2.state
                     && p1.views  == p2.views
                     && p1.params == p2.params)

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
