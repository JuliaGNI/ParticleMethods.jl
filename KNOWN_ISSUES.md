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
