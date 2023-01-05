module SupernovaDistanceMatrix

# External packages
using TOML
using OLUtils
using ArgParse
using OrderedCollections

# Internal Packages
include("RunModule.jl")
using .RunModule: run_SupernovaDistanceMatrix

# Exports
export main 
export run_SupernovaDistanceMatrix

Base.@ccallable function julia_main()::Cint
    try
        main()
    catch
        Base.invokelatest(Base.display_error, Base.catch_stack())
        return 1
    end
    return 0
end

function get_args()
    s = ArgParseSettings()
    @add_arg_table s begin
        "--verbose", "-v"
            help = "Increase level of logging verbosity"
            action = :store_true
        "--rerun", "-r"
            help = "Rerun al jobs"
            action = :store_true
        "input"
            help = "Path to .toml file"
            required = true
    end
    return parse_args(s)
end

function main()
    args = get_args()
    verbose = args["verbose"]
    rerun = args["rerun"]
    toml_path = args["input"]
    toml = TOML.parsefile(abspath(toml_path))
    paths = OrderedDict(
        "dataset_path" => ("output_path", "Datasets"),
        "distance_matrix_path" => ("output_path", "DistanceMatrices"),
        "analysis_path" => ("output_path", "Analysis")
    )
    setup_global!(toml, toml_path, verbose, paths)
    toml["global"]["rerun"] = rerun
    run_SupernovaDistanceMatrix(toml)
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end

end
