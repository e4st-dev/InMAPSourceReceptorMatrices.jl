InMAPSRM.jl
===========
![GitHub contributors](https://img.shields.io/github/contributors/e4st-dev/InMAPSRM.jl?logo=GitHub)
![GitHub last commit](https://img.shields.io/github/last-commit/e4st-dev/InMAPSRM.jl/main?logo=GitHub)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![CI](https://github.com/e4st-dev/InMAPSRM.jl/workflows/CI/badge.svg)](https://github.com/e4st-dev/InMAPSRM.jl/actions?query=workflow%3ACI)
[![Code Coverage](https://codecov.io/gh/e4st-dev/InMAPSRM.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/e4st-dev/InMAPSRM.jl)
[![In Development](https://img.shields.io/badge/docs-dev-blue.svg)](https://e4st-dev.github.io/InMAPSRM.jl/dev/)

Provides a julia interface to access the **In**tervention **M**odel for **A**ir **P**ollution (InMAP) **S**ource **R**eceptor **M**atrix (SRM).  Uses [AWS.jl](https://github.com/JuliaCloud/AWS.jl) and [Zarr.jl](https://github.com/JuliaIO/Zarr.jl) to access the compressed version of the matrix from `s3://inmap-model/isrm_v1.2.1.zarr/`.  Source-receptor matrices allow users to approximate an air quality model simulation without having to run a full air quality model simulation.

For information about InMAP, see their website at [`https://inmap.run/`](https://inmap.run/).

## Installation
```julia
using Pkg
Pkg.add("InMAPSRM")
```

## Usage
See documentation [here](https://e4st-dev.github.io/InMAPSRM.jl/dev/)

Here is an example - given a set of latitudes, longitudes and layers and their associated emissions:

```julia
using InMAPSRM, DataFrames
df = DataFrame(
    latitude = [38.90938938381084],
    longitude = [-77.03759400518372],
    layer_idxs = [2],
    PM2_5 = [1.0],
    VOC = [1.0],
    NOx = [1.0],
    SO2 = [1.0],
    NH3 = [1.0]
)
results = run_sr(df, ["MortalityRate"])
```