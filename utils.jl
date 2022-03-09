using Literate
using Plots
using Graphs, MetaGraphs
using GraphRecipes
using NetworkLayout
using Logging
using JSON3
using PowerSystems
using PowerSystemCaseBuilder
using PowerSimulations
using InteractiveUtils
using Base64
using REPL
using Markdown
using JSONTables
import Literate

export D3PowerSystemTypes
export D3NetworkLayout

disable_logging() = configure_logging(console_level = Logging.AboveMaxLevel, filename = nothing)


function lx_textinput(p)
    rpath = Xranklin.unixify(strip(p[1]))
    lc = Xranklin.cur_lc()
    Xranklin.attach(lc, rpath)
    Xranklin.html(open(f->read(f, String), rpath), lc)
end


#################################################################

struct D3LoadProfile
    names
    data
end

function render(loadprofile::D3LoadProfile)
    t = read(joinpath(@__DIR__, "./templates/d3loadprofile.html"), String)
    r = replace(t, "{{data}}" => JSON3.write(Dict([n => JSON3.read(arraytable(d)) for (n, d) in zip(loadprofile.names, loadprofile.data)]...)))
    return r
end

Base.showable(::MIME"juliavscode/html", ::D3LoadProfile) = true
Base.show(io::IO, ::MIME"juliavscode/html", t::D3LoadProfile) = print(io, render(t))

#################################################################

struct D3PowerSystemTypes
    datatype::DataType
end

function get_field_doc(t, x)
    try
        REPL.fielddoc(t, x)
    catch
        try
            REPL.fielddoc(Base.Docs.Binding(PowerSystems, Symbol(t)), x)
        catch
            Markdown.MD()
        end
    end
end
function children!(data, t)
    # @show t
    data["name"] = string(t)

    if !isabstracttype(t)
        data["fieldnames"] = [x for x in string.(fieldnames(t))]
        data["fieldtypes"] = [x for x in string.(fieldtypes(t))]
        data["fielddocs"] = [get_field_doc(t, x) for x in fieldnames(t)]
        data["fielddocs"] = map(data["fielddocs"]) do d
            if startswith(string(d), "`$(string(t))`")
                Markdown.MD()
            else
                Markdown.MD(d)
            end
        end
        data["fielddocs"] = [strip(Markdown.string(x)) for x in data["fielddocs"]]
        data["value"] = length(fieldnames(t))
    else
        data["children"] = []
        for subtype in subtypes(t)
            c = Dict()
            push!(data["children"], c)
            children!(c, subtype)
        end
    end
end

function render(types::D3PowerSystemTypes, id = "graph")
    t = read(joinpath(@__DIR__, "./templates/d3powersystemtypes.html"), String)
    data = Dict()
    children!(data, types.datatype)
    r = replace(t, "{{data}}" => JSON3.write(data), "{{id}}" => id)
    return r
end

function hfun_d3types_component()
    return render(D3PowerSystemTypes(PowerSystems.Component), "component")
end

function hfun_d3types_timeseries()
    return render(D3PowerSystemTypes(PowerSystems.TimeSeriesData), "timeseries")
end

Base.showable(::MIME"juliavscode/html", ::D3PowerSystemTypes) = true
Base.show(io::IO, ::MIME"juliavscode/html", t::D3PowerSystemTypes) = print(io, render(t))

#################################################################

function create_plot(g)
    n = first(size(g))
    graphplot(
        g,
        curves = false,
        names = rpad.(lpad.(string.(1:n), 2), 2),
        nodesize = 0.2,
        nodeshape = :circle,
        method = :sfdp,
        # layout_kw=Dict(:tol=>0.000001,  :iterations=>10000)
    )
end

function create_graph(sys::PowerSystems.System, res::Union{Nothing,ProblemResults} = nothing)
    buses = collect(get_components(Bus, sys))
    n_bus = length(buses)
    gens = collect(get_components(Generator, sys))
    n_gen = length(gens)
    loads = collect(get_components(PowerLoad, sys))
    n_load = length(loads)
    graph = MetaGraph(SimpleGraph(n_bus + n_gen + n_load))
    from_to_buses = map(get_components(Branch, sys)) do branch
        (
            only(findall(x -> x.name === get_arc(branch).from.name, buses)),
            only(findall(x -> x.name === get_arc(branch).to.name, buses))
        )
    end
    for (f, t) in from_to_buses
        add_edge!(graph, f, t)
    end
    for (i, bus) in enumerate(buses)
        set_prop!(graph, i, :group, get_bustype(bus).value)
        set_prop!(graph, i, :name, get_name(bus))
    end
    for (i, gen) in enumerate(gens)
        gen_node = i + n_bus
        add_edge!(graph, gen_node, only(findall(x -> x.name === get_bus(gen).name, buses)))
        set_prop!(graph, gen_node, :group, 0)
        set_prop!(graph, gen_node, :name, get_name(gen))
    end
    for (i, load) in enumerate(loads)
        load_node = i + n_bus + n_gen
        add_edge!(graph, load_node, only(findall(x -> x.name === get_bus(load).name, buses)))
        set_prop!(graph, load_node, :group, 6)
        set_prop!(graph, load_node, :name, get_name(load))
        set_prop!(graph, load_node, :timeseries, arraytable(get_time_series_array(Deterministic, load, "max_active_power")))
    end
    graph
end
struct D3NetworkLayout
    graph
    marked
end

D3NetworkLayout(graph) = D3NetworkLayout(graph, [])

function render(l::D3NetworkLayout)
    t = read(joinpath(@__DIR__, "./templates/d3networklayout.html"), String)
    data = Dict("nodes" => [], "links" => [])
    graph = l.graph
    for node in vertices(graph)
        d = Dict(
            "id" => node,
            "name" => get_prop(graph, node, :name),
            "group" => get_prop(graph, node, :group),
        )
        if d["group"] == 6
            d["timeseries"] = JSON3.read(get_prop(graph, node, :timeseries))
        end
        push!(data["nodes"], d)
    end
    for (i, edge) in enumerate(edges(graph))
        push!(data["links"], Dict("id" => i, "source" => src(edge), "target" => dst(edge)))
    end
    r = replace(t, "{{time_series_data}}" => JSON3.write([]), "{{graph}}" => JSON3.write(data), "{{marked}}" => JSON3.write(l.marked))
    return r
end

Base.showable(::MIME"juliavscode/html", ::D3NetworkLayout) = true
Base.show(io::IO, ::MIME"juliavscode/html", l::D3NetworkLayout) = print(io, render(l))

function hfun_d3networklayout()
    system = build_system(PSITestSystems, "modified_RTS_GMLC_DA_sys");
    graph = create_graph(system)
    return render(D3NetworkLayout(graph))
end
