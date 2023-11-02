InMAPSRM.jl
===========
![GitHub contributors](https://img.shields.io/github/contributors/e4st-dev/InMAPSRM.jl?logo=GitHub)
![GitHub last commit](https://img.shields.io/github/last-commit/e4st-dev/InMAPSRM.jl/main?logo=GitHub)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![CI](https://github.com/e4st-dev/InMAPSRM.jl/workflows/CI/badge.svg)](https://github.com/e4st-dev/InMAPSRM.jl/actions?query=workflow%3ACI)
[![Code Coverage](https://codecov.io/gh/e4st-dev/InMAPSRM.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/e4st-dev/InMAPSRM.jl)
[![In Development](https://img.shields.io/badge/docs-dev-blue.svg)](https://e4st-dev.github.io/InMAPSRM.jl/dev/)

Provides a julia interface to access the **In**tervention **M**odel for **A**ir **P**ollution (InMAP) **S**ource **R**eceptor **M**atrix (SRM).  Uses [AWS.jl](https://github.com/JuliaCloud/AWS.jl) and [Zarr.jl](https://github.com/JuliaIO/Zarr.jl) to access the compressed version of the matrix from `s3://inmap-model/isrm_v1.2.1.zarr/`.

For information about InMAP, see their website at `https://inmap.run/`

## Installation
```julia
using Pkg
Pkg.add("InMAPSRM")
```