# How to interact with data in a `PowerSystems.System` `struct`

In this tutorial, we will walk through how to use the `PowerSystems.System` `struct`.

## Loading a system

Let's start first by loading the same system we did in [the previous tutorial](/day-ahead-market).

```julia!
using PowerSystems
using PowerSystemCaseBuilder

system = build_system(PSITestSystems, "modified_RTS_GMLC_DA_sys");
```

We have already learnt that the `system` is a `PowerSystems.System`.

```!
typeof(system) === PowerSystems.System
```

\note{
Up until now, we have been using `PowerSystemCaseBuilder` to load a system.
However, we can use the parsers in `PowerSystems` to load other systems as well.
Here's an example of loading the 24 bus system from MATPOWER.

```!
System("./data/case24_ieee_rts.m")
show(stdout, "text/plain", System("./data/case24_ieee_rts.m")) # hide
```

`PowerSystems` has similar parsing features for PSSE, CSV and other data formats.
}

In a `PowerSystems.System`, there may be a bunch of `PowerSystems.Component` types.
`PowerSystems.Component` is a parent abstract type, and has a number of children.
Here is a hierarchical tree of the children of `PowerSystems.Component`:

```julia
include("utils.jl")
D3PowerSystemTypes(PowerSystems.Component)
```

{{ d3types_component }}

Hover over the various labels to see the `struct` definition.
The bold types are the leaf concrete types, and are the ones you may be particularly interested in.

## getter and setter accessor functions

This `System` type is a `struct`, an instance of which can contains all the data that represents a 73 bus test system.

Let's say hypothetically we wanted to get all the buses in this system.
Maybe we want to verify that it is indeed a 73 bus test system.
We can do that using the `get_components` function from `PowerSystems`.

```!
buses = collect(get_components(Bus, system))
show(stdout, "text/plain", buses) # hide
```

Now the `buses` variable contains a `Vector` of all the `Bus` components.

```!
typeof(buses)
```

\note{
In Julia, some types can be parameterized.
In this case, `Vector` is a abstract type and `Vector{Bus}` is a concrete parameterized type.
}

\exercise{
What do you think the result of the following will be?

```julia
numbers = [1,2,3,4]
typeof(numbers)
```

What about the following?

```julia
numbers = [1.,2,3,4]
typeof(numbers)
```
}

We can count the number of buses by getting the `length` of the `Vector{Bus}` instance.

```!
length(buses)
```

\tip{

When you are writing code for an analysis, often you will want to assert that your code is doing the right thing.
You can do this by using the `@assert` macro.

```!
@assert length(buses) == 73
```

This line will silently pass if the assertion returns `true` and can be a easy way to sanity check your code.
Assertions that fail will result in errors.

It can also come in handy to write tests to verify that your code is working as expected.
Julia has a package as part of the standard library for testing.

```!
using Test
@test length(buses) == 73
```
}

\exercise{
How many "areas" are in this test system? Can you find the answer programmatically?

  \collapse{Click to expand and view the solution}{

We can use the `Area` type, the `get_components` function and the `length` to get the number of areas.

```!
length(get_components(Area, system))
```

Note that we did not need to call `collect` to get the length.

  }
}

## Get attributes

A `struct` in Julia like a `dataclass` in Python.
And these `struct`s can have many fields.
This is an example of what the `PowerSystems` `struct` looks like:

```julia
struct System
    data
    frequency
    bus_numbers
    runchecks
    units_settings
end
```

You'll notice that `frequency` is a field on the `System` `struct`.
This means you can access the system's frequency by using the `.` operator:

```!
system.frequency
```

However, these fields in `PowerSystems` are considered implementation details, and may change in future versions of the package.

For accessing data, `PowerSystems` provide a number of accessor functions.
Instead of using `system.frequency`, it is recommended for example to use `get_frequency`.
You'll see that this yields the same answer.

```!
get_frequency(system)
```

You can find the full list of these accessor functions in [the PowerSystems public API reference](https://nrel-siip.github.io/PowerSystems.jl/stable/api/public/).

The function we used earlier, i.e. `get_components` is one such accessor function.
This function takes in two arguments, a `PowerSystems.Component` type as the first argument and the system as the second argument, and returns a collection of components.

\note{

For performance and implementation-detail reasons, `get_components` actually returns a Iterator type.

```!
typeof(get_components(Bus, system))
```

However, you can call the Julia standard library `collect` to convert the iterator to a `Vector{PowerSystem.Bus}`.
}

If you are using a Julia REPL where the `PowerSystems` package is already loaded, you can type `PowerSystems.get_` and hit the `<TAB>` key twice in quick succession.
This should show a list of autocompletion options for the `get_` accessor functions.

\exercise{
Can you print the names of all the `Bus` components in the RTS test system?
How many unique base voltage levels are there in the RTS test system?

  \collapse{Click to expand and view the solution}{

We can get the names using Julia's broadcasting operator.

```!
names = get_name.(get_components(Bus, system))
show(stdout, "text/plain", names) # hide
```

We can use Julia's `unique` function for this:

```!
unique(get_base_voltage.(get_components(Bus, system)))
```

  }
}

Another reason to use `get_*` accessor functions is that data can be transformed appropriately when using these functions.
For example, it is possible to change the base units on the system and have the accessors return the corresponding values.

```!
set_units_base_system!(system, "SYSTEM_BASE")
gen = first(get_components(ThermalStandard, system))
get_active_power_limits(gen)
```

```!
set_units_base_system!(system, "NATURAL_UNITS")
gen = first(get_components(ThermalStandard, system))
get_active_power_limits(gen)
```

You can think about these accessor functions as the API through which you can interact with the `PowerSystems.System` `struct`.

Similar to `get_*` accessor functions, there are `set_*` accessor functions

Here is the name of the first `ThermalStandard` generator.

```!
gen = first(get_components(ThermalStandard, system))
get_name(gen)
```

Let's say we wanted to change it to include the power rating.

```!
n = get_name(gen)
min_p, max_p = get_active_power_limits(gen)
set_name!(system, gen, "$(n)_$(Int(min_p))_$(Int(max_p))")
get_name(gen)
```

## Add and remove components

Let's say you wanted to add a new component to an existing system.
You can do that by using the `add_component!` function.
In the Julia REPL, hit `?` to enter the documentation mode and type `add_component!`.

```
help?> add_component!
```

```!
Base.Docs.doc(add_component!) # hide
```

This function takes a `PowerSystems.System` and a `PowerSystems.Component`.
Let's create a battery storage and attach it to a bus.

```!
try # hide
  remove_component!(system, get_component(GenericBattery, system, "battery")) # hide
catch # hide
end # hide
battery = GenericBattery(; name = "battery",
  available = true,
  bus = get_bus(first(loads)),
  prime_mover=PrimeMovers.BA,
  initial_energy=0.0,
  state_of_charge_limits=(min=0.0, max=0.0),
  rating=0.0,
  active_power=0.0,
  input_active_power_limits=(min=0.0, max=0.0),
  output_active_power_limits=(min=0.0, max=0.0),
  efficiency=(in=0.0, out=0.0),
  reactive_power=0.0,
  reactive_power_limits=(min=0.0, max=0.0),
  base_power=0.0,
)
add_component!(system, battery)
battery
show(stdout, "text/plain", battery) # hide
```

And if you want to remove the component, you can use the `remove_component!` function:

```!
try # hide
remove_component!(system, battery)
catch # hide
end # hide
# OR
try # hide
remove_component!(system, get_component(GenericBattery, system, "battery"))
catch # hide
end # hide
```

During the next session, we will explore building a formulation that includes batteries as part of the scheduling problem.

## Working with time series data

Let's say we wanted to retrieve the load profile data.
First, we can get all the `PowerLoad` components.


```!
loads = collect(get_components(PowerLoad, system))
```

We can call `get_time_series_names` to see the names of all the time series attached to the loads

```!
[names for names in get_time_series_names.(Deterministic, loads)]
```

\tip{

You can use the broadcast operator for this instead:

```
get_time_series_names.(Deterministic, loads);
```
}


There's a lot of time series in there that appear to have the same name.
Let's find all unique names of the kinds of time series data that we are dealing with.

```!
only(unique(Iterators.flatten(get_time_series_names.(Deterministic, loads))))
```

It looks like, in this test system, there's only one kind of time series data in all the `PowerLoad` components, i.e.  the `max_active_power` time series, which makes sense for `Deterministic` loads.

You may be wondering what other kinds of time series data is possible to store:

```
D3PowerSystemTypes(supertype(supertype(supertype(Deterministic))))
# Or
D3PowerSystemTypes(PowerSystems.TimeSeriesData)
```


{{ d3types_timeseries }}


Now that we know that there's only a `"max_active_power"` type of time series data.

```!
data = [get_time_series_array(Deterministic, load, "max_active_power") for load in loads];
(length = length(data), type = typeof(data))
```

`PowerGraphics` has some utility functions for plotting load profiles but lets do this one manually as an exercise.

```!
using Plots
p = plot(popfirst!(data), label = popfirst!(names))
for (name, timeseries) in zip(names, data)
  plot!(p, timeseries, label = name)
end
p
```

\note{
In Julia, by convention, functions that modify the first argument have a `!` at the end of the function name.
For plotting, the first plot object is stored in the variable `p`, and the subsequent function calls to plot are "modifying" the same plot object.
This is why the first function doesn't have a `!` but other calls for plotting do.
This lets us plot all the load profiles and display them together in the same plot.
}

\tip{
In all our code samples, we have been importing a package using the `using` keyword.
This adds all the exported symbols to the current namespace.
Sometimes this might not be what you want.
You can instead import a package using the `import` keyword.

```
import Plots
p = Plots.plot(popfirst!(data), label = popfirst!(names))
for (name, timeseries) in zip(names, data)
  Plots.plot!(p, timeseries, label = name)
end
p
```

This makes it more clearer in the code which packages the functions are coming from.

}


## Summary

We explored the type hierarchy of the `PowerSystems.Component`.
We also looked at how to use the accessor functions to get and set data.
And finally we did some simple plots after getting time series data on the system.

\exercise{
Can you find the names of 10 "largest on average" loads in this system?
  \collapse{Click to expand and view the solution}{

We can use the standard library's `Statistics` package for the `mean` function.


```!
using Statistics

function get_largest_loads(system)
  reverse(
    sort(
      collect(get_components(PowerLoad, system)),
      by = load -> mean(
        values(
          get_time_series_array(
            Deterministic,
            load,
            "max_active_power"
          )
        )
      )
    )
  )
end

get_largest_load_names(system, n = 10) =
  get_name.(Iterators.take(get_largest_loads(system), n))

get_largest_load_names(system, 10)

v = get_largest_load_names(system, 10) # hide
show(stdout, "text/plain", v) # hide
```

  }
}

\exercise{
Can you plot the network graph of the RTS system?

\collapse{Click to expand and view the solution}{

I like using `Graphs.jl` for a light weight networks / graphs package.
Additionally, I like using `MetaGraphs` for storing additional metadata on the graphs.

```!
using Graphs, MetaGraphs
using GraphRecipes
using JSONTables

function create_graph(sys::PowerSystems.System)
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

function create_plot(g)
    n = first(size(g))
    graphplot(
        g,
        curves = false,
        names = rpad.(lpad.(string.(1:n), 2), 2),
        nodesize = 0.2,
        nodeshape = :circle,
        method = :sfdp,
    )
end

create_plot(create_graph(system))
```

Unfortunately, this is not very useful for larger systems.
We can also use D3.js to plot the graph of the system.
Run the following in a vscode Julia session to see an example of this.

```
include("utils.jl")
D3NetworkLayout(create_graph(system))
```

}
}
