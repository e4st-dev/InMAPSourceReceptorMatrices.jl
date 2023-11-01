@doc """
    lonlat2isrm() -> trans

Returns a `Proj.Transformation` for converting from (lon, lat) to the LCC coordinate system used by ISRM:
    
    $ISRM_CRS.
"""
function lonlat2isrm()
    Proj.Transformation("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs", ISRM_CRS)
end
export lonlat2isrm

@doc """
    isrm2lonlat() -> trans

Returns a `Proj.Transformation` for converting to (lon, lat) from the LCC coordinate system used by ISRM:
    
    $ISRM_CRS.
"""
function isrm2lonlat()
    Proj.Transformation(ISRM_CRS, "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
end
export isrm2lonlat

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

function get_isrm_cell_geom_lonlat()
    get_isrm_cell_geom_lonlat(get_idrm_cell_geom())
end

"""
    get_isrm_cell_geom_lonlat(geom::Vector{Box{2, Float64}}) -> geom::Vector{Quadrangle{2, Float64}}


"""
function get_isrm_cell_geom_lonlat(geom::Vector{<:Box{2}})
    trans = isrm2lonlat()

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
export get_isrm_cell_geom_lonlat


