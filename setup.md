# Setup

This document describes that you'll need in your local environment to participate in this tutorial.

## Requirements

1. **git**: Download the 64 bit git installer and use the default options to install it.
   - <https://git-scm.com/>
1. **Julia**: Download the Julia 64 bit installer and use the default options to install it.
   - <https://julialang.org/downloads/>
1. **vscode**: Download the vscode 64 bit installer and use the default options to install it.
   - <https://code.visualstudio.com/Download>
1. **vscode Julia Extension**: Install the Visual Studio Julia Extension:
   - <https://marketplace.visualstudio.com/items?itemName=julialang.language-julia>
   - <https://github.com/julia-vscode/julia-vscode#installing-juliavs-codevs-code-julia-extension>
1. `git clone https://github.com/NREL-SIIP/SIIP-Tutorial.git`
   - After installing vscode, use `git` to clone this repository anywhere you choose.
   - On MacOS, I like to clone it into `~/gitrepos/SIIP-Tutorial
   - On Windows, I like to clone it into `C:\gitrepos\SIIP-Tutorial
     - On Windows, you might have to use `Git Bash` to clone the repository.
   - Use vscode to open this folder.

\exercise{
Explore other extensions in the vscode Extension tab.
}

## Instantiate

For the tutorial, we want to install some packages in a isolated, reproducible environment.

This repository contains a `Project.toml` and a `Manifest.toml` file.
The "environment" defined by these files is all you'll need for this tutorial today.

\tip{
Julia environments are useful for providing reproducible environments for running your analysis.
Make sure you check in your `Project.toml` and `Manifest.toml` file as part of your analysis script.
}

You can read more about Julia's package manager in the official documentation: <https://docs.julialang.org/en/v1/stdlib/Pkg/>.

In order to instantiate our environment, we want to run `instantiate` in the Package mode in the Julia REPL. Follow the steps below to do this using vscode.

\note{
If you are doing this for the first time, it may take 15 minutes or more to download and precompile all the packages.
}

1. On Windows, hit:
   - `Ctrl` + `Shift` + `P` to open the vscode command palette.
1. On Mac, hit:
   - `Cmd` + `Shift` + `P` to open the vscode command palette.
1. You'll see a command palette. Type "Julia Start REPL" and hit enter:
1. You should see a REPL open inside vscode.
1. Hit `]` to open the Pkg mode.
1. Type `instantiate` and hit enter.
1. Type `status` in the package manager mode to see whether the current environment was instantiated correctly:

\exercise{
vscode's command palette is a powerful feature.
Try to experiment with other actions in the command palette.
Can you change the color theme of your vscode editor using the command palette?
Choose your favorite theme for your editor before proceeding.
}

If you want to do this from your terminal instead, you can run the following from the root of the repository.

```bash
julia --project -e "using Pkg; Pkg.instantiate()"
```

Once you have your environment instantiated correctly you are ready to go.

## Using external terminal (_optional_)

Alternatively, you can run `julia --project` in a terminal from the root directory of this repository.

In vscode, open the command palette and type "Julia: Connect external REPL".
You should see a pop up open at the bottom right of your screen.

If you hit the Copy Code button, you can then paste it in a terminal of your choice.
