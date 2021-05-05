
abstract type PoissonSolver{dType} end


"""
Solves the Poisson equation for periodic boundary conditions

```
function solve!(p::PoissonSolver, x::AbstractVector, w::AbstractVector) end
```

"""
function solve! end


"""
Evaluates the charge density field
"""
function eval_density end

"""
Evaluates the electrostatic potential
"""
function eval_potential end

"""
Evaluates the electric field
"""
function eval_field end



function eval_density(p::PoissonSolver{DT}, x::AbstractVector{DT}) where {DT}
    [eval_density(p,x_) for x_ in x]
end

function eval_potential(p::PoissonSolver{DT}, x::AbstractVector{DT}) where {DT}
    [eval_potential(p,x_) for x_ in x]
end

function eval_field(p::PoissonSolver{DT}, x::AbstractVector{DT}) where {DT}
    [eval_field(p,x_) for x_ in x]
end


function eval_density!(y::AbstractVector{DT}, p::PoissonSolver{DT}, x::AbstractVector{DT}) where {DT}
    for i in eachindex(x,y)
        y[i] = eval_density(p,x[i])
    end
    return y
end

function eval_potential!(y::AbstractVector{DT}, p::PoissonSolver{DT}, x::AbstractVector{DT}) where {DT}
    for i in eachindex(x,y)
        y[i] = eval_potential(p,x[i])
    end
    return y
end

function eval_field!(y::AbstractVector{DT}, p::PoissonSolver{DT}, x::AbstractVector{DT}) where {DT}
    for i in eachindex(x,y)
        y[i] = eval_field(p,x[i])
    end
    return y
end
