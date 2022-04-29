
function _create_group(h5::H5DataStore, name)
    if haskey(h5, name)
        g = h5[name]
    else
        g = create_group(h5, name)
    end
    return g
end


"""
Particles struct.
fields: positon x, velocity v, weight w
"""
struct ParticleList{T}
    x::Vector{T}
    v::Vector{T}
    w::Vector{T}

    function ParticleList(x::AbstractArray{T}, v::AbstractArray{T}, w::AbstractArray{T}) where {T}
        new{T}(x, v, w)
    end
end

function ParticleList(h5::H5DataStore, path::AbstractString = "/")
    group = h5[path]

    x = read(group["x"])
    v = read(group["v"])
    w = read(group["w"])

    ParticleList(x, v, w)
end

function ParticleList(fpath::AbstractString, path::AbstractString = "/")
    h5open(fpath, "r") do file
        ParticleList(file, path)
    end
end

function h5save(h5::H5DataStore, p::ParticleList; path::AbstractString = "/")
    group = _create_group(h5, path)

    group["x"] = p.x
    group["v"] = p.v
    group["w"] = p.w
end

function h5load(::Type{ParticleList}, h5::H5DataStore; path::AbstractString = "/")
    ParticleList(h5, path)
end

Base.length(pl::ParticleList) = length(pl.w)
