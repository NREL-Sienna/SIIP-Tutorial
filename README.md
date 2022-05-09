# SIIP-Tutorials

This package contains examples and tutorials for [Scalable Integrated Infrastructure Planning (SIIP) packages developed at the National Renewable Energy Laboratory (NREL)](https://www.nrel.gov/analysis/siip.html).

The examples included here are intended as practical examples of using [SIIP packages](https://github.com/nrel-siip).
However, in many cases users may find the documentation pages for each package more informative:

- [InfrastructureSystems.jl docs](https://nrel-siip.github.io/InfrastructureSystems.jl/stable/)
- [PowerSystems.jl docs](https://nrel-siip.github.io/PowerSystems.jl/stable/)
- [PowerSimulations.jl docs](https://nrel-siip.github.io/PowerSimulations.jl/stable/)
- [PowerGraphics.jl docs](https://nrel-siip.github.io/PowerGraphics.jl/stable/)
- [PowerSimulationsDynamics.jl docs](https://nrel-siip.github.io/PowerSimulationsDynamics.jl/stable/)

## Debugging

On occasion, you may have constructed a `System` using PowerSystemsCaseBuilder.jl that needs
to be reconstructed. In this case, you may receive an error such as:

```julia
ERROR: UndefVarError: PowerSystems.ReserveUp not defined
```

To resolve this issue, you can purge the serialized system data from your
PowerSystemsCaseBuilder.jl instance by running:

```julia
using PowerSystemCaseBuilder
PowerSystemCaseBuilder.clear_all_serialized_system()
```
