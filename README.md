# ParticlesMethods.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://juliagni.github.io/ParticleMethods.jl/stable)
[![Latest](https://img.shields.io/badge/docs-latest-blue.svg)](https://juliagni.github.io/ParticleMethods.jl/latest)
[![PkgEval Status](https://juliaci.github.io/NanosoldierReports/pkgeval_badges/P/ParticleMethods.svg)](https://juliaci.github.io/NanosoldierReports/pkgeval_badges/P/ParticleMethods.html)
[![Build Status](https://github.com/JuliaGNI/ParticleMethods.jl/workflows/CI/badge.svg)](https://github.com/JuliaGNI/ParticleMethods.jl/actions)
[![Coverage](https://codecov.io/gh/JuliaGNI/ParticleMethods.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/JuliaGNI/ParticleMethods.jl)

This package implements a general framework for particle methods.

## Installation

*ParticleMethods.jl* and all of its dependencies can be installed via the Julia REPL by typing 
```julia
]add ParticleMethods
```

## Development

### Git hooks

Two hooks live in `.githooks`. They are **not active in a fresh clone** — `core.hooksPath` is local
configuration and does not travel with a push — so enable them once per clone:

```sh
git config core.hooksPath .githooks
```

**`pre-commit`** acts on **staged `.jl` files only**, and exits immediately when a commit stages
none, so a documentation- or workflow-only commit is not slowed down by it:

- **JuliaFormatter `--check`**, honouring this repository's own `.JuliaFormatter.toml` — **blocks**
  the commit. Formatting is mechanical and always fixable.
- **`fatou lint`**, when `fatou` is installed — **advisory only**, and deliberately so: its
  `unused-import` rule does not follow `include`, so it flags the load-bearing imports of every
  module file.
- **`using <Package>`**, which catches a syntax error or a broken `include` — **blocks**.

**`pre-push`** runs the full test suite with `--check-bounds=auto`, but **only when pushing to
`main` or `master`**; a topic branch is left to CI. It prints nothing for **10–30 minutes**, which
looks exactly like a network hang and is not one. If you do interrupt it, check for an orphaned
Julia process that the killed hook left behind.

Either hook can be bypassed for a single command with `--no-verify`, for a change you know it does
not apply to:

```sh
git commit --no-verify
git push --no-verify
```

The hooks are generated from one shared copy and are byte-identical across the related
repositories, so edit them there rather than here — a local edit is silently undone by the next
install.
