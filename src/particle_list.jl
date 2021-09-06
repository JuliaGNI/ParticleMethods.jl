
"""
Particles struct.
fields: positon x, velocity v, weight w
"""
struct ParticleList{T}
    x::Vector{T}
    v::Vector{T}
    w::Vector{T}
end
