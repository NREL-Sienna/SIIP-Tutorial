module SIIP_Tutorial

export precompile_tutorial

using PowerSystems
using PowerSystemCaseBuilder
using PowerSimulations
using PowerGraphics
using TimeSeries
using DataFrames
using Plots
using HiGHS
using Logging

function precompile_tutorial()
    system = build_system(SIIPExampleSystems, "5_bus_matpower_DA"; force_build = true, skip_serialization = true)
    template = template_unit_commitment()
    optimizer = optimizer_with_attributes(HiGHS.Optimizer, "mip_rel_gap" => 0.05)
    model = DecisionModel(
        template,
        system;
        optimizer = optimizer,
        horizon = 1
    )
    build!(model, output_dir = mktempdir())
    solve!(model)
    ProblemResults(model)
    nothing
end

end # module SIIP_Tutorial
