using Documenter, InMAPSRM

makedocs(
    modules = [InMAPSRM],
    doctest = false,
    sitename = "InMAPSRM.jl",
    pages = [
        "Home" => "index.md",
        "API" => "api.md",
    ],
    format = Documenter.HTML(
        prettyurls = false
    ),
    warnonly=true,
)

deploydocs(
    repo = "https://github.com/e4st-dev/E4ST.jl",
    devbranch = "main"
)