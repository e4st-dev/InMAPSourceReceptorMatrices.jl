module InMAPSRM

using AWS
using Zarr
using Meshes
using Proj
using SparseArrays
using DataFrames

const ISRM_URL = "s3://inmap-model/isrm_v1.2.1.zarr/"
const ISRM_CRS = "+proj=lcc +lat_1=33.000000 +lat_2=45.000000 +lat_0=40.000000 +lon_0=-97.000000 +x_0=0 +y_0=0 +a=6370997.000000 +b=6370997.000000 +to_meter=1" # from https://github.com/spatialmodel/inmap/blob/master/cmd/inmap/configExample.toml#L103C5-L103C5
const NSR = 52411 # Number of sources / receptors that we care about

export ISRM_CRS
export NSR

include("srm.jl")
include("data.jl")
include("geometry.jl")

##################################################################################
# Handling the ISRM connection
##################################################################################
struct ISRMState
    fs::Zarr.ZGroup{Zarr.S3Store}
    ISRMState() = new()
    ISRMState(fs) = new(fs)
end

_isrm_state = ISRMState()

"""
    connect_to_isrm!(; region="us-east-2")

Connects to AWS, opens the INMAP source receptor matrix with `zopen` (from Zarr.jl)
"""
function connect_to_isrm!(;region="us-east-2")
    aws_config = AWSConfig(; creds=nothing, region)
    global_aws_config(aws_config)
    fs = zopen(ISRM_URL)
    global _isrm_state = ISRMState(fs)
    return fs
end

"""
    get_isrm_fs() -> fs

Return the 
"""
function get_isrm_fs()
    isdefined(_isrm_state, :fs) ? _isrm_state.fs : connect_to_isrm!()
end
export get_isrm_fs



end # module InMAPSRM
