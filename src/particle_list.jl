
function _bounds_to_indices(indices)
    length(indices) == 1 ? indices[begin] : indices[begin]:indices[end]
end

_sort_names(::NamedTuple{N, T}) where {N, T} = Tuple(sort([N...]))

_sort_ntuple(nt::NamedTuple) = NamedTuple{_sort_names(nt)}(nt)

"""
    ParticleList(list::AbstractMatrix; variables = NamedTuple(), parameters = NamedTuple(),
                 species = nothing, speciesindex = nothing)
    ParticleList(DT, np, nd; variables = NamedTuple(), parameters = NamedTuple(),
                 species = nothing, speciesindex = nothing)
    ParticleList(x, v, w; parameters = NamedTuple(), species = nothing,
                 speciesindex = nothing)
    ParticleList(h5::H5DataStore, path = "/")
    ParticleList(fpath::AbstractString, path = "/")

A list of particles, stored as the columns of the matrix `list`. Each column is the state of one
particle, and `pl[i]` is that particle as a [`Particle`](@ref).

`variables` maps names to row indices or row ranges of `list`, and `parameters` maps names to
values. Each name is a property of the list: `pl.x` is a view into the rows of a variable `x` for
all particles, and the stored value for a parameter. The names must not repeat each other or the
field names `list`, `views`, `params`, `particles`, `variables`, `indices`, `species` and
`speciesindex`.

`species` is the table of particle species, each a [`Species`](@ref) with a charge and a mass, and
`speciesindex` gives the species of each particle as an index into that table. A list built
without `species` holds one species with charge and mass one, so `chargeweights(pl)[1, i]` is the
weight `w_i` of particle `i`. A list with more than one species needs an explicit `speciesindex` of
length `np`, with every index in `1:length(species)`.

The second form makes a zero list of element type `DT` with `np` particles of `nd` components.
The third form stacks positions `x`, velocities `v` and weights `w`, and defines the variables
`x`, `v`, `z` (positions and velocities) and `w`. The last two forms read a list that `h5save`
wrote, from a group `path` of an HDF5 file or from the file at `fpath`.
"""
struct ParticleList{T, ST <: AbstractMatrix{T}, VT <: NamedTuple, PT <: NamedTuple,
    PART <: AbstractVector, VART <: NamedTuple, IND <: NamedTuple}
    list::ST
    views::VT
    params::PT
    particles::PART
    variables::VART
    indices::IND
    species::Vector{Species{T}}
    speciesindex::Vector{Int}

    function ParticleList(list, views, params, particles, variables, indices, species,
            speciesindex)
        @assert isdisjoint(fieldnames(ParticleList), keys(views))
        @assert isdisjoint(fieldnames(ParticleList), keys(params))
        @assert isdisjoint(keys(views), keys(params))
        new{eltype(list), typeof(list), typeof(views), typeof(params),
            typeof(particles), typeof(variables), typeof(indices)}(
            list, views, params, particles, variables, indices, species, speciesindex)
    end
end

function ParticleList(
        list::AbstractMatrix; variables = NamedTuple(), parameters = NamedTuple(),
        species = nothing, speciesindex = nothing)
    svariables = _sort_ntuple(variables)
    views = map(idx_range -> view(list, idx_range, :), svariables)
    vars = map(v -> eachslice(v; dims = ndims(v)), views)
    particles = [Particle(p; variables = svariables, parameters = parameters)
                 for p in eachcol(list)]

    T = eltype(list)
    np = size(list, 2)
    stable = species === nothing ? [Species(:default, one(T), one(T))] :
             Species{T}.(species)
    sind = if speciesindex === nothing
        if length(stable) > 1
            throw(ArgumentError(
                "a ParticleList with $(length(stable)) species needs an explicit speciesindex"))
        end
        ones(Int, np)
    else
        convert(Vector{Int}, speciesindex)
    end

    length(sind) == np || throw(ArgumentError(
        "speciesindex has length $(length(sind)), expected $np"))
    for i in sind
        1 ≤ i ≤ length(stable) || throw(ArgumentError(
            "speciesindex contains $i, outside 1:$(length(stable))"))
    end

    ParticleList(list, views, parameters, particles, vars, svariables, stable, sind)
end

function ParticleList(DT::DataType, np::Int, nd::Int; kwargs...)
    ParticleList(zeros(DT, nd, np); kwargs...)
end

function ParticleList(x::AbstractArray{DT}, v::AbstractArray{DT}, w::AbstractArray{DT}; kwargs...) where {DT}
    vars = (
        x = 1:size(x, 1),
        v = (size(x, 1) + 1):(size(x, 1) + size(v, 1)),
        z = 1:(size(x, 1) + size(v, 1)),
        w = (size(x, 1) + size(v, 1) + 1):(size(x, 1) + size(v, 1) + size(w, 1))
    )
    ParticleList(vcat(x, v, w); variables = vars, kwargs...)
end

function ParticleList(x::AbstractVector{DT}, v::AbstractVector{DT}, w::AbstractVector{DT}; kwargs...) where {DT}
    ParticleList(
        reshape(x, (1, length(x))), reshape(v, (1, length(v))), reshape(w, (
            1, length(w))); kwargs...)
end

function Base.:(==)(pl1::ParticleList{T1, ST1}, pl2::ParticleList{
        T2, ST2}) where {T1, T2, ST1, ST2}
    (
        T1 == T2 && ST1 == ST2
        && pl1.list == pl2.list
        && pl1.views == pl2.views
        && pl1.params == pl2.params
        && pl1.particles == pl2.particles
        && pl1.variables == pl2.variables
        && pl1.indices == pl2.indices
        && pl1.species == pl2.species
        && pl1.speciesindex == pl2.speciesindex)
end

@inline function Base.hasproperty(::ParticleList{T, ST, VT, PT}, s::Symbol) where {
        T, ST, VT, PT}
    hasfield(VT, s) || hasfield(PT, s) || hasfield(ParticleList, s)
end

@inline function Base.getproperty(p::ParticleList{T, ST, VT, PT}, s::Symbol) where {
        T, ST, VT, PT}
    if hasfield(VT, s)
        return getfield(p, :views)[s]
    elseif hasfield(PT, s)
        return getfield(p, :params)[s]
    else
        return getfield(p, s)
    end
end

Base.eltype(::ParticleList{T}) where {T} = T

# iteration yields `Particle`s, not elements of type `eltype`
Base.IteratorEltype(::Type{<:ParticleList}) = Base.EltypeUnknown()

Base.length(pl::ParticleList) = length(pl.particles)

Base.size(pl::ParticleList) = size(pl.list)

Base.getindex(pl::ParticleList, i::Int) = getindex(pl.particles, i)

Base.getindex(pl::ParticleList, I::Vararg{Int}) = getindex(pl.list, I...)

Base.getindex(pl::ParticleList, I...) = getindex(pl.list, I...)

Base.setindex!(pl::ParticleList, v, i::Int) = setindex!(pl.particles, v, i)

Base.setindex!(pl::ParticleList, v, I::Vararg{Int}) = setindex!(pl.list, v, I...)

Base.setindex!(pl::ParticleList, X, I...) = setindex!(pl.list, X, I...)

Base.eachindex(pl::ParticleList) = eachindex(pl.particles)

"""
    eachparticle(pl::ParticleList)

Return the vector of the `Particle`s in `pl`. Each particle is a view into a column of `pl.list`.
"""
eachparticle(pl::ParticleList) = pl.particles

Base.iterate(pl::ParticleList, state...) = iterate(pl.particles, state...)

"""
    species(pl::ParticleList, i::Integer)

Return the [`Species`](@ref) of particle `i` in `pl`, that is `pl.species[pl.speciesindex[i]]`.
"""
@inline species(pl::ParticleList, i::Integer) = pl.species[pl.speciesindex[i]]

"""
    charge(pl::ParticleList, i::Integer)

Return the charge of particle `i` in `pl`, the charge of its [`Species`](@ref).
"""
@inline charge(pl::ParticleList, i::Integer) = species(pl, i).charge

"""
    mass(pl::ParticleList, i::Integer)

Return the mass of particle `i` in `pl`, the mass of its [`Species`](@ref).
"""
@inline mass(pl::ParticleList, i::Integer) = species(pl, i).mass

"""
    ChargeWeights{T} <: AbstractMatrix{T}

The charge-weighted weights `q_i · w_i` of the particles in a [`ParticleList`](@ref), as a lazy
`1 × np` matrix whose `[1, i]` element is the charge of particle `i` times its weight. Returned by
[`chargeweights`](@ref).
"""
struct ChargeWeights{T, PL <: ParticleList} <: AbstractMatrix{T}
    parent::PL
    row::Int
end

Base.size(cw::ChargeWeights) = (1, length(cw.parent))

@inline function Base.getindex(cw::ChargeWeights, i::Int, j::Int)
    @boundscheck checkbounds(cw, i, j)
    return charge(cw.parent, j) * cw.parent.list[cw.row, j]
end

"""
    chargeweights(pl::ParticleList)

Return the charge-weighted weights of the particles in `pl` as a lazy `1 × np` matrix, whose
`[1, i]` element is `charge(pl, i) * w_i`, the weight of particle `i`. This is the weight a charge
deposit reads, so a deposit that weights each particle by its charge changes one argument and no
signature.

It throws an `ArgumentError` when `pl` has no variable `w`, or when `w` spans more than one row.
"""
function chargeweights(pl::ParticleList{T}) where {T}
    haskey(pl.indices, :w) || throw(ArgumentError("the ParticleList has no variable w"))
    return ChargeWeights{T, typeof(pl)}(pl, _wrow(pl.indices.w))
end

_wrow(w::Integer) = Int(w)

function _wrow(w)
    length(w) == 1 ||
        throw(ArgumentError("the variable w must span exactly one row, got $(length(w))"))
    return Int(first(w))
end

function ParticleList(h5::H5DataStore, path::AbstractString = "/")
    group = h5[path]

    particles = read(group["particles"])

    vars = group["variables"]
    vinds = Symbol.(keys(vars))
    vvals = (_bounds_to_indices(read(vars[key])) for key in keys(vars))
    variables = NamedTuple{Tuple(vinds)}(Tuple(vvals))

    pgroup = group["parameters"]
    paramkeys = Tuple(Symbol.(keys(pgroup)))
    paramvals = Tuple(read(pgroup[key]) for key in keys(pgroup))

    params = NamedTuple{paramkeys}(paramvals)

    species, speciesindex = if haskey(group, "species")
        sgroup = group["species"]
        names = Symbol.(read(sgroup["name"]))
        charges = read(sgroup["charge"])
        masses = read(sgroup["mass"])
        ([Species(n, q, m) for (n, q, m) in zip(names, charges, masses)],
            convert(Vector{Int}, read(sgroup["index"])))
    else
        (nothing, nothing)
    end

    ParticleList(particles; variables = variables, parameters = params,
        species = species, speciesindex = speciesindex)
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
        vars[string(key)] = inds isa Integer ? [inds] : [inds[begin], inds[end]]
    end

    for key in keys(p.params)
        params[string(key)] = p.params[key]
    end

    sgroup = _create_group(group, "species")
    sgroup["name"] = String[String(s.name) for s in p.species]
    sgroup["charge"] = [s.charge for s in p.species]
    sgroup["mass"] = [s.mass for s in p.species]
    sgroup["index"] = p.speciesindex

    group["particles"] = p.list
end

function h5load(::Type{ParticleList}, h5::H5DataStore; path::AbstractString = "/")
    ParticleList(h5, path)
end

# Base.length(pl::ParticleList) = length(pl.w)
