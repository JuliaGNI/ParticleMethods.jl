# Known issues

### K1 · `ChargeWeights` and `chargeweights` are exported API with no caller.

- **location:** `src/particle_list.jl:199`
- **evidence:** No code in this package or in its dependents calls `chargeweights`. The type and
  the function add about 40 lines of source and about 46 lines of tests. A deposit that weights
  each particle by its charge can write `charge(pl, i) * pl.list[wrow, i]` inline: at `np = 10⁶`
  the inline form and `chargeweights(pl)[1, i]` measured 692 µs and 695 µs, in one run. Removing
  the pair after a release is a breaking change, so the decision is cheapest before the next
  release: remove it, or keep it until the first deposit that uses a species charge calls it.
- **kind:** dead code
- **found:** PR #20

### K2 · `isempty` on an empty `ParticleList` raises `BoundsError` in the released 0.1.2.

- **location:** `src/particle_list.jl:94 (v0.1.2)`
- **evidence:** Release 0.1.2 defines `Base.iterate(pl::ParticleList) = (pl[1], 1)`, which reads
  element 1 before anything checks that the list is empty, and `isempty` falls back to `iterate`.
  Probe on the registered 0.1.2, Julia 1.13: `isempty(ParticleDistribution(1, 1, 0).particles)`
  throws `BoundsError: attempt to access 0-element Vector{Particle{…}} at index [1]`, with the
  stack `getindex @ particle_list.jl:80` → `iterate @ particle_list.jl:94` →
  `isempty @ essentials.jl:1130`. `main` (`b738f80`) replaces the two `iterate` methods with
  `iterate(pl::ParticleList, state...) = iterate(pl.particles, state...)`
  (`src/particle_list.jl:169`), so the same call returns `true` there; the released 0.1.2 still
  carries the defect, and a dependent that works around it cites nothing. VlasovMethods'
  extension checks the length instead and says why at `ext/VlasovMethodsMakieExt.jl:21-22`.
- **kind:** defect
- **found:** PR #20
