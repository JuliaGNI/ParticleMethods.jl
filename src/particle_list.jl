
_tuple_to_range(indices) = indices[begin]:indices[end]

_sort_names(::NamedTuple{N,T}) where {N,T} = Tuple(sort([N...]))

_sort_ntuple(nt::NamedTuple) = NamedTuple{_sort_names(nt)}(nt)


struct ParticleList{T, ST <: AbstractMatrix{T}, VT <: NamedTuple, PT <: NamedTuple, PART <: AbstractVector, VART <: NamedTuple, IND <: NamedTuple}
    list::ST
    views::VT
    params::PT
    particles::PART
    variables::VART
    indices::IND

    function ParticleList(list, views, params, particles, variables, indices)
        @assert isdisjoint(fieldnames(ParticleList), keys(views))
        @assert isdisjoint(fieldnames(ParticleList), keys(params))
        @assert isdisjoint(keys(views), keys(params))
        new{eltype(list), typeof(list), typeof(views), typeof(params), typeof(particles), typeof(variables), typeof(indices)}(list, views, params, particles, variables, indices)
    end
end

function ParticleList(list::AbstractMatrix; variables = NamedTuple(), parameters = NamedTuple())
    svariables = _sort_ntuple(variables)
    views = map(idx_range -> view(list, idx_range, :), svariables)
    vars = map(idx_range -> [view(list, idx_range, i) for i in axes(list, 2)], svariables)
    particles = [Particle(p; variables = svariables, parameters = parameters) for p in eachcol(list)]
    ParticleList(list, views, parameters, particles, vars, svariables)
end

function ParticleList(DT::DataType, np::Int, nd::Int; kwargs...)
    ParticleList(zeros(DT, nd, np); kwargs...)
end

function ParticleList(x::AbstractArray{DT}, v::AbstractArray{DT}, w::AbstractArray{DT}; kwargs...) where {DT}
    vars = ( 
            x = 1:size(x,1),
            v = size(x,1)+1:size(x,1)+size(v,1),
            z = 1:size(x,1)+size(v,1),
            w = size(x,1)+size(v,1)+1:size(x,1)+size(v,1)+size(w,1),
           )
    ParticleList(vcat(x,v,w); variables = vars, kwargs...)
end

function ParticleList(x::AbstractVector{DT}, v::AbstractVector{DT}, w::AbstractVector{DT}; kwargs...) where {DT}
    ParticleList(reshape(x, (1,length(x))), reshape(v, (1,length(v))), reshape(w, (1,length(w))); kwargs...)
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


function ParticleList(h5::H5DataStore, path::AbstractString = "/")
    group = h5[path]

    particles = read(group["particles"])

    vars = group["variables"]
    vinds = Symbol.(keys(vars))
    vvals = (_tuple_to_range(read(vars[key])) for key in keys(vars))
    variables = NamedTuple{Tuple(vinds)}(Tuple(vvals))

    pgroup = group["parameters"]
    paramkeys = Tuple(Symbol.(keys(pgroup)))
    paramvals = Tuple(read(pgroup[key]) for key in keys(pgroup))

    params = NamedTuple{paramkeys}(paramvals)

    ParticleList(particles; variables = variables, parameters = params)
end

function ParticleList(fpath::AbstractString, path::AbstractString = "/")
    h5open(fpath, "r") do file
        ParticleList(file, path)
    end
end

function h5save(h5::H5DataStore, p::ParticleList; path::AbstractString = "/")
    group = _create_group(h5, path)

    vars = _create_group(group, "variables")
    params = _create_group(group, "parameters")

    for key in keys(p.indices)
        inds = p.indices[key]
        vars[string(key)] = [inds[begin], inds[end]]
    end

    for key in keys(p.params)
        params[string(key)] = p.params[key]
    end

    group["particles"] = p.list
end

function h5load(::Type{ParticleList}, h5::H5DataStore; path::AbstractString = "/")
    ParticleList(h5, path)
end

# Base.length(pl::ParticleList) = length(pl.w)
