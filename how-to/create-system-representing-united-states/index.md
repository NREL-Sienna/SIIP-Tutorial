# Creating a `System` representing the entire U.S.

**Originally Contributed by**: Clayton Barrows

## Introduction

This example demonstrates how to assemble a `System` representing the entire U.S. using
[PowerSystems.jl](https://github.com/NREL-SIIP/powersystems.jl) and the data assembled by
[Xu, et. al.](https://arxiv.org/abs/2002.06155). We'll use the same tabular data parsing
capability [demonstrated on the RTS-GMLC dataset](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/master/notebook/2_PowerSystems_examples/04_parse_tabulardata.ipynb).

```!
# hideall
using Pkg
Pkg.activate(joinpath(Utils.path(:folder), "how-to/create-system-representing-united-states/"))
Pkg.instantiate()
```

```!
using PowerSystems
using TimeSeries
using Dates
using TimeZones
using DataFrames
using CSV

if Sys.iswindows()
    const OS = Windows
elseif Sys.isapple()
    const OS = MacOS
else
    const OS = Linux
end

function unzip(::Type{<:BSD}, filename, directory)
    @assert success(`tar -xvf $filename -C $directory`) "Unable to extract $filename to $directory"
end

function unzip(::Type{Windows}, filename, directory)
    path_7z = if Base.VERSION < v"0.7-"
        "$JULIA_HOME/7z"
    else
        sep = Sys.iswindows() ? ";" : ":"
        withenv(
            "PATH" => string(
                joinpath(Sys.BINDIR, "..", "libexec"),
                sep,
                Sys.BINDIR,
                sep,
                ENV["PATH"],
            ),
        ) do
            Sys.which("7z")
        end
    end
    @assert success(`$path_7z x $filename -y -o$directory`) "Unable to extract $filename to $directory"
end
```

### Fetch Data

PowerSystems.jl links to some test data that is suitable for this example.
Let's download the test data.

```!
println("downloading data...")
datadir = joinpath(Utils.path(:folder), "how-to/create-system-representing-united-states/data")
if !isdir(datadir)
  mkpath(datadir)
  tempfilename = download("https://zenodo.org/record/3753177/files/USATestSystem.zip?download=1")
  unzip(SIIPExamples.os, tempfilename, datadir)
end
```
