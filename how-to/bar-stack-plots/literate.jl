# # Bar and stack plots with PowerGraphics.jl

# PowerGraphics also provides some basic specifications for plotting `SimulationResults`.
# This example demonstrates some simple plotting capabilities using different Plots.julia
# backends.
#
# The plotting capabilities use the Julia Plots package which can generate plots using
# several different graphics packages. We'll use GR.jl and PlotlyJS.jl.
#
# ## Dependencies
using PowerSystems # to load results
using PowerSimulations # to load results
using PowerGraphics
using PowerSystemCaseBuilder

# ### Results file
# If you have already run some of the other examples, you should have generated some results
# (If you haven't run some of the other simulations, you can run

using Dates
using DataFrames
using HiGHS # mip solver
solver = optimizer_with_attributes(HiGHS.Optimizer, "mip_rel_gap" => 0.5)
sys_DA = build_system(SIIPExampleSystems, "5_bus_matpower_DA")
sys_RT = build_system(SIIPExampleSystems, "5_bus_matpower_RT")
template_uc = template_unit_commitment(use_slacks=true)
template_ed = template_economic_dispatch(
    network=NetworkModel(CopperPlatePowerModel, duals=[CopperPlateBalanceConstraint]),
)
models = SimulationModels(
    decision_models=[
        DecisionModel(template_uc, sys_DA, name="UC", optimizer=solver),
        DecisionModel(template_ed, sys_RT, name="ED", optimizer=solver),
    ],
)
feedforward = Dict(
    "ED" => [
        SemiContinuousFeedforward(
            component_type=ThermalStandard,
            source=OnVariable,
            affected_values=[ActivePowerVariable],
        ),
    ],
)
DA_RT_sequence = SimulationSequence(
    models=models,
    ini_cond_chronology=InterProblemChronology(),
    feedforwards=feedforward,
)
file_path = mktempdir(cleanup=true)
sim = Simulation(
    name="5bus-test",
    steps=1,
    models=models,
    sequence=DA_RT_sequence,
    simulation_folder=file_path,
)

build!(sim)

execute!(sim, enable_progress_bar=false)
results = SimulationResults(sim);
uc_results = get_decision_problem_results(results, "UC")
ed_results = get_decision_problem_results(results, "ED");
list_dual_names(ed_results)
prices = read_dual(ed_results, "CopperPlateBalanceConstraint__System")
read_realized_dual(ed_results, "CopperPlateBalanceConstraint__System")

# Alternatively, you can load the results into memory with:
# ```julia
# simulation_folder = joinpath(pkgdir(SIIPExamples), "rts-test")
# simulation_folder =
#     joinpath(simulation_folder, "$(maximum(parse.(Int64,readdir(simulation_folder))))")
#
# results = SimulationResults(simulation_folder);
# uc_results = get_decision_problem_results(results, "UC")
# ```

# Since some of the plotting capabilities rely on input data as well as output data (e.g. fuel plots)
# but the result deserialization doesn't load the `System`, we can add the `System` to the `results`
# so that the plotting routines can find the requisite data.
set_system!(uc_results, sys_DA)

# ## Plots
# By default, PowerGraphics uses the GR graphics package as the backend for Plots.jl to
# generate figures. This creates static plots and should execute without any extra steps.
# For example, we can create a plot of a particular variable in the `uc_results` object:
gr() # loads the GR backend
timestamps = get_realized_timestamps(uc_results)
variable = read_realized_variable(uc_results, "ActivePowerVariable__ThermalStandard")

plot_dataframe(variable, timestamps)

# However, interactive plotting can generate much more insightful figures, especially when
# creating somewhat complex stacked figures. So, we can use the PlotlyJS backend for Plots,
# but it requires that PlotlyJS.jl is installed in your Project.toml (if in a notebook,
# WebIO.jl is required too). To startup the PlotlyJS backend, run:
# plotlyjs()

# PowerGraphics creates an un-stacked line plot by default, but supports kwargs to
# create a variety of different figure styles. For example, a stacked area figure can be
# created with the `stack = true` kwarg:

plot_dataframe(variable, timestamps; stack=true)

# Or a bar chart can be created with `bar = true`:
plot_dataframe(variable, timestamps; bar=true)

# Or a stacked bar chart...
plot_dataframe(variable, timestamps; bar=true, stack=true)

# PowerGraphics also supports some basic aggregation to create cleaner plots. For example,
# we can create a plot of the different variables:
generation = get_generation_data(uc_results)
plot_pgdata(generation, stack=true)

reserves = get_service_data(uc_results)
plot_pgdata(reserves)

# Another standard aggregation is available to plot demand values:
plot_demand(uc_results)

# The `plot_demand` function can also be called with the `System` rather than the `StageResults`
# to inspect the input data. This method can also display demands aggregated by a specified
# `<:Topology`:

## plot_demand(uc_results.system, aggregation=Area)

# Another standard aggregation exists based on the fuel categories of the generators in the
# `System`
plot_fuel(uc_results)
