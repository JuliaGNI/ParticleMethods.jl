"""
    Species(name::Symbol, charge, mass)
    Species{T}(name::Symbol, charge, mass)

A particle species: a name, a charge `q` and a mass `m`, shared by every particle of that species.
`Species(name, charge, mass)` promotes the charge and the mass to their common type, and
`Species{T}(s::Species)` converts an existing species to the element type `T` of a
[`ParticleList`](@ref).

The mass must be positive: a mass that is not, `NaN` included, throws an `ArgumentError`, and the
conversion to `T` checks again, so a mass that rounds to zero in `T` throws too. The charge may be
zero.

# Example

```julia
s = Species(:e, -1.0, 0.5)
s.charge   # -1.0
s.mass     # 0.5
```
"""
struct Species{T}
    name::Symbol
    charge::T
    mass::T

    function Species{T}(name::Symbol, charge, mass) where {T}
        m = convert(T, mass)
        m > zero(T) ||
            throw(ArgumentError("the mass of species $name must be positive, got $m"))
        new{T}(name, convert(T, charge), m)
    end
end

function Species(name::Symbol, charge, mass)
    Species{promote_type(typeof(charge), typeof(mass))}(
        name, charge, mass)
end

Species{T}(s::Species) where {T} = Species{T}(s.name, s.charge, s.mass)

"""
    charge(s::Species)

Return the charge `q` of the species `s`.
"""
charge(s::Species) = s.charge

"""
    mass(s::Species)

Return the mass `m` of the species `s`.
"""
mass(s::Species) = s.mass
