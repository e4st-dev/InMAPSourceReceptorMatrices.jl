using Documenter, InMAPSourceReceptorMatrices

makedocs(
    modules = [InMAPSourceReceptorMatrices],
    doctest = false,
    sitename = "InMAPSourceReceptorMatrices.jl",
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
    repo = "https://github.com/e4st-dev/InMAPSourceReceptorMatrices.jl",
    devbranch = "main"
)