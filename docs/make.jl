using Documenter, BitInformation

makedocs(
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true"),
    sitename="BitInformation.jl",
    authors="M Klöwer",
    modules=[BitInformation],
    pages=["Home"=>"index.md",
            "Bitwise information"=>"bitinformation.md",
            "Transformations"=>"transformations.md",
            "Rounding"=>"rounding.md",
            "Function index"=>"functions.md"]
)

deploydocs(
    repo = "github.com/milankl/BitInformation.jl.git",
)