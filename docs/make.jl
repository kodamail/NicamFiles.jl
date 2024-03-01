using NicamFiles
using Documenter

DocMeta.setdocmeta!(NicamFiles, :DocTestSetup, :(using NicamFiles); recursive=true)

makedocs(;
    modules=[NicamFiles],
    authors="Chihiro Kodama",
    repo="https://github.com/kodamail/NicamFiles.jl/blob/{commit}{path}#{line}",
    sitename="NicamFiles.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://kodamail.github.io/NicamFiles.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/kodamail/NicamFiles.jl",
    devbranch="main",
)
