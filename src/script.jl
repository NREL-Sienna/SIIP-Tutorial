using Logging

@info "Building the RTS test system"
using PowerSystems
using PowerSystemCaseBuilder

# uses RTS Test System with Time Series data
system = build_system(PSITestSystems, "modified_RTS_GMLC_DA_sys")

@info "Building a template for unit commitment"
using PowerSimulations

template = template_unit_commitment()

@info "Creating a solver"
using HiGHS

optimizer = optimizer_with_attributes(HiGHS.Optimizer, "mip_rel_gap" => 0.05)

@info "Create a model"
model = DecisionModel(
    template,
    system;
    optimizer = optimizer,
    horizon = 24
)

@info "Build the model"
build!(model, output_dir = mktempdir())

@info "Solve the model"
solve!(model)

@info "Get results"
results = ProblemResults(model)

using PowerGraphics

p = plot_fuel(results)
