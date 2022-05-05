
struct ParticleList{T, ST <: AbstractMatrix{T}, VT <: NamedTuple, PT <: NamedTuple, PART <: AbstractVector, VART <: NamedTuple}
    list::ST
    views::VT
    params::PT
    particles::PART
    variables::VART

    function ParticleList(list, views, params, particles, variables)
        @assert isdisjoint(fieldnames(ParticleList), keys(views))
        @assert isdisjoint(fieldnames(ParticleList), keys(params))
        @assert isdisjoint(keys(views), keys(params))
        new{eltype(list), typeof(list), typeof(views), typeof(params), typeof(particles), typeof(variables)}(list, views, params, particles, variables)
    end
end

function ParticleList(list::AbstractMatrix; variables = NamedTuple(), parameters = NamedTuple())
    views = map(idx_range -> view(list, idx_range, :), variables)
    vars = map(idx_range -> [view(list, idx_range, i) for i in axes(list, 2)], variables)
    particles = [Particle(p; variables = variables, parameters = parameters) for p in eachcol(list)]
    ParticleList(list, views, parameters, particles, vars)
end

function ParticleList(DT, np, nd; kwargs...)
    ParticleList(zeros(DT, nd, np); kwargs...)
end

@inline function Base.hasproperty(::ParticleList{T,ST,VT,PT}, s::Symbol) where {T,ST,VT,PT}
    hasfield(VT, s) || hasfield(PT, s) || hasfield(Particle, s)
end

@inline function Base.getproperty(p::ParticleList{T,ST,VT,PT}, s::Symbol) where {T, ST, VT, PT}
    if hasfield(VT, s)
        return getfield(p, :views)[s]
    elseif hasfield(PT, s)
        return getfield(p, :params)[s]
    else
        return getfield(p, s)
    end
end

Base.eltype(::ParticleList{T}) where {T} = T

Base.length(pl::ParticleList) = length(pl.particles)

Base.size(pl::ParticleList) = size(pl.list)

Base.getindex(pl::ParticleList, i::Int) = getindex(pl.particles, i)

Base.getindex(pl::ParticleList, I::Vararg{Int}) = getindex(pl.list, I...)

Base.getindex(pl::ParticleList, I...) = getindex(pl.list, I...)

Base.setindex!(pl::ParticleList, v, i::Int) = setindex!(pl.particles, v, i)

Base.setindex!(pl::ParticleList, v, I::Vararg{Int}) = setindex!(pl.list, v, I...)

Base.setindex!(pl::ParticleList, X, I...) = setindex!(pl.list, X, I...)

Base.eachindex(pl::ParticleList) = eachindex(pl.particles)

Base.iterate(pl::ParticleList) = (pl[1], 1)

Base.iterate(pl::ParticleList, i::Int) = i < length(pl) ? (pl[i+1], i+1) : nothing


# function ParticleList(h5::H5DataStore, path::AbstractString = "/")
#     group = h5[path]

#     x = read(group["x"])
#     v = read(group["v"])
#     w = read(group["w"])

#     ParticleList(x, v, w)
# end

# function ParticleList(fpath::AbstractString, path::AbstractString = "/")
#     h5open(fpath, "r") do file
#         ParticleList(file, path)
#     end
# end

# function h5save(h5::H5DataStore, p::ParticleList; path::AbstractString = "/")
#     group = _create_group(h5, path)

#     group["x"] = p.x
#     group["v"] = p.v
#     group["w"] = p.w
# end

# function h5load(::Type{ParticleList}, h5::H5DataStore; path::AbstractString = "/")
#     ParticleList(h5, path)
# end

# Base.length(pl::ParticleList) = length(pl.w)
