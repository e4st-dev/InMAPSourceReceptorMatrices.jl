pm_emis_types() = ("PrimaryPM25", "SOA", "pNO3", "pSO4", "pNH4")
primary_emis_types() = ("PM2_5", "VOC", "NOx", "SO2", "NH3")
function primary2pm(emis_type)
    (emis_type == "PM2_5" || emis_type == "pm25") && return "PrimaryPM25"
    (emis_type == "VOC" || emis_type == "voc") && return "SOA"
    (emis_type == "NOx" || emis_type == "nox") && return "pNO3"
    (emis_type == "SO2" || emis_type == "so2") && return "pSO4"
    (emis_type == "NH3" || emis_type == "nh3") && return "pNH4"
    error("Primary emission type $emis_type not found, choose from $(primary_emis_types())")
end
export pm_emis_types, primary_emis_types, primary2pm


@doc """
    SRM(emis_type) -> srm::Array{Float32, 3}

Returns source receptor matrix retrieved from `fs`, with `emis_type` ∈ $(pm_emis_types())

Note that these are huge ($NSR x $NSR x 3) and will require ~60-70GB of RAM to hold onto. Index via `(receptor, source, layer)`. Care should be taken if multiple stored in memory.  May take 5-10 minutes to fetch from AWS.

To create a sparse SRM for only a select group of source locations, see [`make_sparse_srm`](@ref).  (that will still call `SRM`, but will call garbage collection before returning the sparse matrix)
"""
function SRM(emis_type)
    fs = get_isrm_fs()
    emis_type in pm_emis_types() || error("Emission type $emis_type not in ISRM.  Please choose from $possible_emis_types")
    zarr = fs[emis_type]::ZArray{Float32, 3, Zarr.BloscCompressor, S3Store}
    arr = zarr[:,:,:]::Array{Float32, 3}
    return arr
end
export SRM

_SparseSRM = Vector{SparseMatrixCSC{Float32, UInt32}}

@doc """
    SparseSRM(emis_type, source_idxs, [layer_idxs]; threshold=0.0)

Make a sparse source receptor matrix, indexable via `(receptor, source, layer)`.
* `emis_type` - The emission type for which to make the sparse matrix, ∈ $(pm_emis_types())
* `source_idxs` - A vector of source indexes for which to add the pollution effects to the matrix
* `layer_idxs` - A vector of layer_idxs for which to 
* `threshold=0.0` - The threshold, in units (μg / m³) / (μg / s), above which to add the value to the sparse matrix.  Adds every nonzero value by default.
"""
function SparseSRM(var::AbstractString, source_idxs::AbstractVector, layer_idxs::AbstractVector; threshold=0.0)
    @assert length(source_idxs) == length(layer_idxs)
    sparse_srm = _make_sparse_srm(var, source_idxs, layer_idxs; threshold)
    GC.gc()
    return sparse_srm
end

export SparseSRM

_size(srm::_SparseSRM) = (size(first(srm))..., length(srm))

SparseSRM(var::AbstractString, source_idxs::AbstractVector; kwargs...) = SparseSRM(var, source_idxs, ones(eltype(source_idxs), length(source_idxs)); kwargs...)

"""
    SparseSRM(srm, source_idxs, [layer_idxs]; threshold=0.0)

Make a sparse source receptor matrix from an SRM (`Array{Float32, 3}`).
* `emis_type` - The emission type for which to make the sparse matrix.
* `source_idxs` - A vector of source indexes for which to add the pollution effects to the matrix
* `layer_idxs` - A vector of layer_idxs for which to 
* `threshold=0.0` - The threshold, in units (μg / m³) / (μg / s), above which to add the value to the sparse matrix.  Adds every nonzero value by default.
"""
function SparseSRM(srm, source_idxs::AbstractVector, layer_idxs::AbstractVector; kwargs...)
    return _make_sparse_srm(srm, source_idxs, layer_idxs; kwargs...)
end

function _make_sparse_srm(var::AbstractString, source_idxs, layer_idxs; threshold=0.0)
    # Fetch the array from sr
    @info "Fetching variable $var from ISRM"
    srm = SRM(var)
    @info "Done Fetching variable $var"

    _make_sparse_srm(srm, source_idxs, layer_idxs; threshold)
end

function _make_sparse_srm(srm::Array{Float32, 3}, source_idxs, layer_idxs; threshold=0.0)
    # Loop through and add the values to the matrix
    @info "Allocating data to sparse array"
    II = [UInt32[]  for _ in 1:3]
    JJ = [UInt32[]  for _ in 1:3]
    VV = [Float32[] for _ in 1:3]
    for (source_idx, layer_idx) in unique(zip(source_idxs, layer_idxs))
        source_idx == 0 && continue
        for receptor_idx in 1:NSR
            val = srm[receptor_idx, source_idx, layer_idx] # TODO: is this the right indexing
            val <= threshold && continue
            push!(II[layer_idx], receptor_idx)
            push!(JJ[layer_idx], source_idx)
            push!(VV[layer_idx], val)
        end
    end
    
    sparr = map(1:3) do layer_idx
        sparse(II[layer_idx], JJ[layer_idx], VV[layer_idx], NSR, NSR)
    end

    return sparr
end

@doc """
    compute_receptor_emis(srm, source_idx(s), layer_idx(s), val(s)) -> receptor_emis::Vector

Compute the emissions at each receptor from `srm` for each source specified by `source_idx` and `layer_idx`, which correspond to `val(s)`

    compute_receptor_emis(srm, source_emis::Matrix) -> receptor_emis::Vector

Compute the emissions at each receptor from `srm` for `source_emis`, a `NSR x 3` matrix containing annual average emission rates at each grid cell and layer, in units of micrograms per second.

`srm` can be any of the following types:
* `Array{Float64, 3}` - returned by [`SRM`](@ref)
* [`SparseSRM`](@ref)
* `String` - pm emission type ∈ `$(pm_emis_types())`
"""
function compute_receptor_emis(srm::_SparseSRM, source_idx::Integer, layer_idx::Integer, val::Number)
    return val .* view(srm[layer_idx], source_idx, :)
end
export compute_receptor_emis

function compute_receptor_emis(srm::AbstractArray, source_idxs::AbstractVector{<:Integer}, layer_idxs::AbstractVector{<:Integer}, vals::AbstractVector{<:Number})
    source_emis = zeros(size(srm, 1), size(srm, 3))
    for (source_idx, layer_idx, val) in zip(source_idxs, layer_idxs, vals)
        source_idx <= 0 && continue
        source_emis[source_idx, layer_idx] += val
    end
    return compute_receptor_emis(srm, source_emis)
end    

function compute_receptor_emis(srm::_SparseSRM, source_emis::Matrix{<:Number})
    receptor_emis = sum(1:size(srm,3)) do layer_idx
        srm[layer_idx] * view(source_emis, :, layer_idx)
    end
    return receptor_emis
end

function compute_receptor_emis(srm::Array{Float32, 3}, source_emis::Matrix{<:Number})
    receptor_emis = sum(1:size(srm,3)) do layer_idx
        view(srm, :, :, layer_idx) * view(source_emis, :, layer_idx)
    end
    return receptor_emis
end

function compute_receptor_emis(srm::Array{Float32, 3}, source_idx::Integer, layer_idx::Integer, val::Number)
    return val .* view(srm, :, source_idx, layer_idx)
end


function compute_receptor_emis(emis_type::AbstractString, args...; kwargs...)
    res = _compute_receptor_emis(emis_type, args...; kwargs...)
    GC.gc()
    return res
end

function _compute_receptor_emis(emis_type, args...; kwargs...)
    srm = SRM(emis_type)
    return compute_receptor_emis(srm, args...; kwargs...)
end