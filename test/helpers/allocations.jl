# Function barriers for the allocation assertions. Each method has a fixed arity and concrete
# argument types; it calls `f` once to warm it, then returns the bytes that the second call
# allocates.
allocations(f::F, a::A) where {F, A} = (f(a); @allocated f(a))
allocations(f::F, a::A, b::B) where {F, A, B} = (f(a, b); @allocated f(a, b))
allocations(f::F, a::A, b::B, c::C) where {F, A, B, C} = (f(a, b, c); @allocated f(a, b, c))
function allocations(f::F, a::A, b::B, c::C, d::D) where {F, A, B, C, D}
    f(a, b, c, d)
    @allocated f(a, b, c, d)
end

# The positive control: it allocates a new vector on every call, so each barrier above reads more
# than zero bytes for it.
_allocating(args...) = zeros(length(args))
