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

### New Features

### Bug Fixes

### Breaking Changes

## Open Issues
