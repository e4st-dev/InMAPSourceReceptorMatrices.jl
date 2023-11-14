"""
    get_isrm_cell_data(vars::AbstractVector{<:AbstractString}; geometry=true) -> cell_data::DataFrame

To see list of available variables, see [`get_isrm_variable_summary`](@ref)
"""
function get_isrm_cell_data(vars::AbstractVector{<:AbstractString}; geometry=true, geometry_longlat=false)
    df = DataFrame()
    for var in vars
        df[!, var] = get_isrm_cell_data(var)
    end
    if geometry === true
        df[!, :geometry] = get_isrm_cell_geom()
    end
    if geometry_longlat === true
        if geometry === true
            geom = df.geometry
        else
            geom = get_isrm_cell_geom()
        end
        df[!, :geometry_longlat] = get_isrm_cell_geom_longlat(geom)
    end

    return df
end
export get_isrm_cell_data

function get_isrm_cell_data(::Colon; kwargs...)
    fs = get_isrm_fs()
    vars = collect(keys(fs.arrays))
    filter!(is_isrm_cell_data_var, vars)
    return get_isrm_cell_data(vars; kwargs...)
end

function is_isrm_cell_data_var(var::AbstractString)
    fs = get_isrm_fs()
    haskey(fs, var) || return false
    
    z = fs[var]
    ndims(z) == 1 || return false
    length(z) < NSR && return false
    return true
end

"""
    get_isrm_cell_data(var::AbstractString) -> v::Vector

Fetch the grid-cell data for the variable `var`.
"""
function get_isrm_cell_data(var::AbstractString)
    fs = get_isrm_fs()
    haskey(fs, var) || error("No variable $var found in InMAP.")
    
    z = fs[var]

    ndims(z) == 1 || error("Cell data variables should have only 1 dimension.  $var has $(ndims(z)) dimensions.")

    return z[1:NSR]
end
export get_isrm_cell_data

"""
    get_isrm_variable_summary() -> summary::DataFrame

Returns a summary of the variables in the source receptor matrix
"""
function get_isrm_variable_summary()
    fs = get_isrm_fs()
    df = DataFrame(variable=>String[], size=>[])
    for (var, z) in fs.arrays
        push!(df, (var, size(z)))
    end
    sort!(df)
    return df
end
export get_isrm_variable_summary
