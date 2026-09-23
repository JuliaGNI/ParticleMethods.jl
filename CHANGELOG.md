# Release Notes

All notable changes to ParticleMethods.jl.

This package is pre-1.0, so *every* minor release is potentially breaking in the sense of
[SemVer](https://semver.org) for `0.x` versions. The sections below name what actually
changed, so that a compat-only bump can be told apart from a rename or a change in results.

This file was started on 2026-08-31 and deliberately holds no entries. 4 versions were
released before it, the most recent `v0.1.2`, and none of them are written up here: the
record of that history is `git log` and the tags. It is named as a gap rather than
reconstructed, because a changelog assembled after the fact loses exactly the reasoning that
makes it worth keeping. The `[Unreleased]` target below is provisional — confirm it when the
first entry is written.

## [Unreleased] — targeting 0.2.0

### New Features

- **`scripts/particle_list_profile.jl` is under version control**, and lives in `scripts/` rather
  than `test/`. It builds a `ParticleList` of 10⁶ particles with six components and profiles an
  in-place update over `pl.x` and `pl.v` under `--track-allocation`. It measures rather than
  asserts, so `test/` was the wrong home: a profiling harness that runs as part of the suite costs
  a minute and checks nothing.

### Changed

- **`makeclean.sh` is tracked.** The same script is tracked in the other ten repositories that
  carry it, and this copy is byte-identical to them; this package was the only one where it had
  never been added.
- **`.gitignore` now covers `*.h5` and `*.hdf5`.** The suite writes `temp.h5`
  (`test/particle_list_tests.jl:81`) and never removes it, so it sat untracked and visible in
  every `git status`. `VlasovMethods` already ignored both patterns.
- **`ParticleList` constructor from matrix now builds variable views lazily.** Previously
  it eagerly materialized, for every declared variable, a `Vector` of one `SubArray` view
  per particle — a redundant representation of the underlying matrix. It now uses
  `eachslice` over each variable's view, yielding a zero-allocation `AbstractVector` with
  the same element type and values. Measured at `np = 10⁶` particles, `nd = 6`
  components, three variables: allocation reduced from 328.0 MB to 184.0 MB (43.9%
  reduction).
- **`StaticArrays` removed from `[deps]` in Project.toml.** The `using StaticArrays: MVector` import
  in `src/ParticleMethods.jl` was the only use in `src/` and was removed by the `Particle(DT, len)`
  change. It remains in `[compat]` and as a test-only dependency in `[extras]` because the test suite
  uses it. `Aqua.test_stale_deps` now passes on this package.
- **`SafeTestsets` removed from the test dependencies.** No test file used it. `Test` has a
  `[compat]` entry, so every test-only dependency now declares one.
- **`Base.iterate(pl::ParticleList, state)` forwards to `pl.particles`.** One method covers the
  first and the later steps, and the state is the state of `iterate` over the particle vector:
  the index of the next particle, not of the last one.
- **Aqua.jl 0.8 added as a test dependency.** `Aqua.test_all(ParticleMethods)` runs inside
  its own `@testset "Aqua"` in `test/runtests.jl`, so a failing check fails the suite. All
  11 checks pass with Aqua 0.8.18, among them undefined exports, piracy, ambiguities and
  stale dependencies.
- **Docstrings written for the module, `Particle` and `ParticleList`.** These were the only
  exported names without one (`eachparticle` had one).
  `Base.Docs.undocumented_names(ParticleMethods)` is now empty, and the library page renders
  all four.

### Bug Fixes

- **`Base.hasproperty(::ParticleList, s)` now checks the correct struct.** Previously it fell through
  to `hasfield(Particle, s)` instead of `hasfield(ParticleList, s)`, so `hasproperty(pl, :list)` and
  other `ParticleList`-only field names incorrectly returned `false`.
- **`Base.iterate(pl::ParticleList)` terminates correctly.** Previously it returned `(pl[1], 1)`
  unconditionally, so iterating an empty `ParticleList` threw `BoundsError` instead of returning
  `nothing`.
- **`collect(pl::ParticleList)` returns the particles.** It threw a `MethodError`, because
  `eltype` gives the numeric element type but iteration yields `Particle`s. `ParticleList` now
  declares `Base.IteratorEltype` as `EltypeUnknown()`, and `eltype` still gives the numeric type.
- **`eachparticle` is now defined.** It was exported from the module but never defined, so calling it
  threw `UndefVarError`. It is defined as `eachparticle(pl::ParticleList) = pl.particles`.
- **HDF5 round-trip preserves scalar vs. range indices.** Previously `h5save`/`ParticleList(::H5DataStore)`
  converted a scalar variable index (e.g., `w = 7`) to a 1-element `UnitRange` (`7:7`), silently
  changing type and shape. The write path now stores a 1-element array for scalars and 2-element for
  ranges; the read path distinguishes them by length. (An HDF5 file written before this change stores
  `[i, i]` for a scalar index `i`, which reads back as the 1-element range `i:i` since the read path
  uses length only.)

### Breaking Changes

- **`Particle(DT, len; kwargs...)` now returns fully inferred state.** The length-based constructor
  previously built state as `MVector{len}(zeros(DT, len))`, using runtime `len::Int` as a type
  parameter and making return type uninferrable. It now builds plain `zeros(DT, len)` (a `Vector`),
  which is fully inferred regardless of runtime length. The `state` field type remains generic
  (`AbstractVector`), but this constructor's concrete return type is now correct. This changes
  equality semantics: `Particle(Float64, 7) == Particle(MVector{7}(zeros(7)))` was `true` before
  and is now `false`, because `==` requires the state types to match.

## Open Issues
