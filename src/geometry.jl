@doc """
    longlat2isrm() -> trans

Returns a `Proj.Transformation` for converting from (lon, lat) to the LCC coordinate system used by ISRM:
    
    $ISRM_CRS.
"""
function longlat2isrm()
    Proj.Transformation("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs", ISRM_CRS)
end
export longlat2isrm

@doc """
    isrm2longlat() -> trans

Returns a `Proj.Transformation` for converting to (lon, lat) from the LCC coordinate system used by ISRM:
    
    $ISRM_CRS.
"""
function isrm2longlat()
    Proj.Transformation(ISRM_CRS, "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
end
export isrm2longlat

"""
    get_isrm_cell_geom() -> geom::Vector{Box{2, Float64}}
"""
function get_isrm_cell_geom()
    fs = get_isrm_fs()
    ee = fs["E"][1:NSR]::Vector{Float64}
    ww = fs["W"][1:NSR]::Vector{Float64}
    nn = fs["N"][1:NSR]::Vector{Float64}
    ss = fs["S"][1:NSR]::Vector{Float64}
    
    geom = map(zip(nn,ss,ee,ww)) do (n,s,e,w)
        Box((w,s),(e,n))
    end
end
export get_isrm_cell_geom

function get_isrm_cell_geom_longlat()
    get_isrm_cell_geom_longlat(get_isrm_cell_geom())
end

"""
    get_isrm_cell_geom_longlat(geom::Vector{Box{2, Float64}}) -> geom::Vector{Quadrangle{2, Float64}}

Returns the cell geometry of the SRM in longlat form.
"""
function get_isrm_cell_geom_longlat(geom::Vector{<:Box{2}})
    trans = isrm2longlat()

    # Transform geometry to lon, lat form.
    map(geom) do b
        ws = minimum(b)
        en = maximum(b)
        w,s = coordinates(ws)
        e,n = coordinates(en)

        # We want to use Quadrangles here because the box might get distorted by transformation.
        Quadrangle(
            trans(w,s),
            trans(w,n),
            trans(e,n),
            trans(e,s),
        )
    end
end
export get_isrm_cell_geom_longlat


"""
    get_cell_idxs(longlats, cell_geom::Vector; threshold = 1000) -> cell_idxs

    get_cell_idxs(longs, lats, cell_geom::Vector; threshold = 1000) -> cell_idxs

Return the indices of the closest cells (in `cell_geom`) for each of the longs and lats supplied. If there is no grid cell within `threshold` meters from the point in `geo_df`, gives an index of 0. `cell_geom` can either be the original geometry (represented as `Box`es), or the longlat geometry (represented as `Quadrangle`s).
"""
function get_cell_idxs(longlats, cell_geom::Vector{Box{2,Float64}}; threshold= 1000)
    n_unmapped = 0
    trans = longlat2isrm()
    cell_idxs = map(longlats) do (lon, lat)
        p = Point(trans(lon,lat))
        i = findfirst(area -> p ∈ area, cell_geom)
        i === nothing || return i
        d, i2 = findmin(b->dist(b,p), cell_geom)
        d <= threshold && return i2
        n_unmapped += 1
        return 0
    end

    n_unmapped > 0 && @warn "$n_unmapped points were over $threshold meters away from the nearest grid cell."
    return cell_idxs
end
function get_cell_idxs(longlats, cell_geom_longlat::Vector{Quadrangle{2,Float64}}; threshold= 1000)
    n_unmapped = 0
    cell_idxs = map(longlats) do (lon, lat)
        p = Point(lon,lat)
        i = findfirst(area -> p ∈ area, cell_geom)
        i === nothing || return i
        d, i2 = findmin(b->dist(b,p), cell_geom)
        d <= threshold && return i2
        n_unmapped += 1
        return 0
    end

    n_unmapped > 0 && @warn "$n_unmapped points were over $threshold meters away from the nearest grid cell."
    return cell_idxs
end
get_cell_idxs(longs, lats, cell_geom; kwargs...) = get_cell_idxs(zip(longs, lats), cell_geom; kwargs...)
get_cell_idxs(longlats, cell_data::DataFrame; kwargs...) = get_cell_idxs(longlats, cell_data.geometry; kwargs...)
export get_cell_idxs

function dist(b::Box{2,T}, p::Point{2,T}) where {T}
    p ∈ b && return zero(T)
    px, py = coordinates(p)
    minb = minimum(b)
    maxb = maximum(b)
    minx, miny = coordinates(minb)
    maxx, maxy = coordinates(maxb)

    if px <= minx
        if py > maxy
            return norm((px - minx, py - maxy))
        elseif py < miny
            return norm((px - minx, py - miny))
        else
            return minx - px
        end
    elseif px >= maxx
        if py > maxy
            return norm((px - maxx, py - maxy))
        elseif py < miny
            return norm((px - maxx, py - miny))
        else
            return px - maxx
        end
    elseif py >= maxy
        return py - maxy
    elseif py <= miny
        return miny - py
    else
        @warn "Edge case not handled!"
    end
end
dist(p::Point{2}, b::Box{2}) = dist(b,p)
dist(p1::Point, p2::Point) = norm(p1-p2)



