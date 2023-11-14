module InMAPSRM

using AWS
using Zarr
using Meshes
using Proj
using SparseArrays
using DataFrames

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
    connect_to_isrm!(; region="us-east-2", creds = nothing, url="s3://inmap-model/isrm_v1.2.1.zarr/")

Connects to AWS, opens the INMAP source receptor matrix with `zopen` (from Zarr.jl)
"""
function connect_to_isrm!(;region="us-east-2", creds=nothing, url="s3://inmap-model/isrm_v1.2.1.zarr/")
    aws_config = AWSConfig(; creds, region)
    global_aws_config(aws_config)
    fs = zopen(url)
    global _isrm_state = ISRMState(fs)
    return fs
end
export connect_to_isrm!

"""
    get_isrm_fs() -> fs

Return the AWS file system. 
"""
function get_isrm_fs()
    isdefined(_isrm_state, :fs) ? _isrm_state.fs : connect_to_isrm!()
end
export get_isrm_fs

"""
    run_sr(source_emis::DataFrame, [cell_variables]) -> receptor_emis::DataFrame

Runs the source receptor matrix for the given source emissions, where each row represents an emitter.  Note that `source_emis` must have the following columns:
* `latitude <: Number` - latitude of the source
* `longitude <: Number` - longitude of the source
* `layer_idx <: Integer` - layer index ∈ {1,2,3}, for ground-level, low-stack, and high-stack emissions, respectively
* `<emis_type> <: Number` - the average emissions rate, in μg / s, for emission type `<emis_type>` ∈ `{PM2_5, NOx, SO2, VOC, NH3}`.  There can be between 1 and 5 of these columns.
* (optional) `source_idx <: Int64` - which grid cell index corresponds to the source.  If given, `latitude` and `longitude` no longer used.

Returns the `receptor_emis` table which contains columns for each of the PM types created by the source emissions, as well as columns for each of the variables in `cell_variables`, and a column for `geometry_longlat`, which contains the `(lon, lat)` geometry of each grid cell.
"""
function run_sr(source_emis::DataFrame, cell_variables=String[]; cell_distance_threshold = 1000)
    # check that we have the input variables we need
    @assert (hasproperty(source_emis, :latitude) && hasproperty(source_emis, :longitude)) || (hasproperty(source_emis, :source_idx)) "source_emis must have either (:latitude, :longitude) columns or :source_idx column."
    @assert hasproperty(source_emis, :layer_idx) "source_emis must have (:layer_idx) column"

    receptor_emis = get_isrm_cell_data(cell_variables; geometry_longlat=true)

    if hasproperty(source_emis, :source_idx)
        source_idx = source_emis.source_idx
    else
        source_idx = get_cell_idxs(source_emis.longitude, source_emis.latitude, receptor_emis.geometry, threshold = cell_distance_threshold)
    end

    layer_idx = source_emis.layer_idx

    emis_types = intersect!(["PM2_5", "NOx", "SO2", "VOC", "NH3"], names(source_emis))

    for emis_type in emis_types
        pm_emis_type = primary2pm(emis_type)
        emis = source_emis[!, emis_type]
        receptor_emis[!, pm_emis_type] = compute_receptor_emis(pm_emis_type, source_idx, layer_idx, emis)
    end
    return receptor_emis
end
export run_sr



end # module InMAPSRM
