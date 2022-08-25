# jl #! format: off
# # Serializing PowerSystem Data

# **Originally Contributed by**: Clayton Barrows

# ## Introduction

# PowerSystems.jl supports serializing/deserializing data with JSON. This notebook
# provides an example of how to write and read a `System` to/from disk.

# ### Dependencies
# Let's use a dataset from the [tabular data parsing example](https://nbviewer.jupyter.org/github/NREL-SIIP/SIIPExamples.jl/blob/master/notebook/2_PowerSystems_examples/parse_matpower.ipynb)

using PowerSystems
using TimeSeries

base_dir = PowerSystems.download(PowerSystems.TestData; branch="master");
sys = System(joinpath(base_dir, "matpower", "case5_re.m"))
sys

# ### Write data to a temporary directory

folder = mktempdir()
@show folder, typeof(folder)

# ### Test

path_to_file = joinpath(folder, "system.json")
println("Serializing to $path")
to_json(sys, path_to_file, force=true)

filesize(path_to_file) / (1024 * 1024)

# ### Read the JSON file and create a new `System`

sys2 = System(path_to_file)
