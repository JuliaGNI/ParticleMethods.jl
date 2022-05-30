```@meta
CurrentModule = ParticleMethods
```

# ParticlesMethods.jl


## Installation

*ParticleMethods.jl* and all of its dependencies can be installed via the Julia REPL by typing 
```julia
]add ParticleMethods
```


## Data Stuctures

The particles package provides flexible data structures for particles and particle lists.
While particle states are stored as vectors and particle lists as matrices, the package provides
convenient access to different fields in the state of a particle as well as to parameters.

### Particle

A typical particle state could be
```
s = | x | v |w|
```
where `s` is a vector of length 7, `x` is the particle position with length 3, `v` is the particle velocity with length 3, and `w` is the particle weight, which is scalar. In order to create a particle with such a structure, one can either initialize the particle with a prescribed data type,
```julia
p = Particle(Float64, 7; variables = (x = 1:3, v = 4:6, z = 1:6, w = 7))
```
or  with a prescribed state,
```julia
p = Particle(rand(7); variables = (x = 1:3, v = 4:6, z = 1:6, w = 7))
```
The former constructor will default to using an `MVector` from StaticArrays.jl to store the particle state. The latter will use whichever vector type is specified by the user.

In both cases, the particle state is accessible via fields corresponding to the index ranges specified by the user:
```@repl
using Particles
p = Particle([1.0, 0.0, 0.0, 0.5, 0.2, 0.0, 0.1];
             variables = (x = 1:3, v = 4:6, z = 1:6, w = 7))
p.state
p.z
p.x
p.v
p.w
```
