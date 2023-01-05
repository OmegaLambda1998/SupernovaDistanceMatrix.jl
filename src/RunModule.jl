module RunModule

# External Packages
using YAML

# Internal Packages
include("SimModule.jl")
using .SimModule

include("LCModule.jl")
using .LCModule

include("SupernovaModule.jl")
using .SupernovaModule

include("DatasetModule.jl")
using .DatasetModule

include("DistanceMatrixModule.jl")
using .DistanceMatrixModule

include("AnalysisModule.jl")
using .AnalysisModule

# Exports
export run_SupernovaDistanceMatrix

function prepare_dataset_info(pippin_output::AbstractString, pippin_name::String, yml::AbstractString="")
    if !isdir(pippin_output)
        throw(ErrorException("Pippin output director: $(pippin_output) does not exits. Check that your base path and dataset path keys are correct!"))
    end
    if yml == ""
        dirs = readdir(pippin_output)
        yml = dirs[findfirst(x -> contains(x, "yml"), dirs)]
    end
    yml = joinpath(pippin_output, yml)
    if !isfile(yml)
        throw(ErrorException("Pippin yml file $(yml) does not exist, please check that your yml key is correct!"))
    end
    @debug "Loading in pippin input file: $yml"
    pippin_input = YAML.load_file(yml)
    sim_dict = pippin_input["SIM"]
    sim_info = Dict{String, Dict{String, Any}}()
    for name in keys(sim_dict)
        # Skip Biascors
        if !contains(name, "BIAS")
            GLOBAL = get(sim_dict[name], "GLOBAL", Dict())
            ω0 = get(GLOBAL, "W0_LAMBDA", -1.0)
            Ωm = get(GLOBAL, "OMEGA_MATTER", 0.3)
            ΩΛ = get(GLOBAL, "OMEGA_LAMBDA", 1 - Ωm)
            num_datasets = 1
            combine_datasets = true
            if "RANSEED_CHANGE" in keys(GLOBAL)
                ranseed_change = GLOBAL["RANSEED_CHANGE"]
                num_datasets = parse(Int64, split(ranseed_change)[1])
                combine_datasets = false
            end
            sim_info[name] = Dict("ω0" => ω0, "Ωm" => Ωm, "ΩΛ" => ΩΛ, "num_datasets" => num_datasets, "combine_datasets" => combine_datasets)
        else
            @debug "Skipping SIM $name, likely a biascor run"
        end
    end
    lc_dict = pippin_input["LCFIT"]
    dataset_info = Dict{String, Dict{String, Any}}()
    for name in keys(lc_dict)
        mask = get(lc_dict[name], "MASK", "")
        sims = [k for k in keys(sim_info) if contains(k, mask)]
        if length(sims) == 0
            @debug "Skipping LCFIT $name with mask $mask, likely a biascor run"
        elseif length(sims) > 1
            @debug "LCFIT $name with mask $mask matched multiple sims ($sims), will create a new dataset for each"
        end
        for sim in sims
            lc_name = "$(name)_$(sim)"
            job_name = "$(pippin_name)_$(lc_name)"
            dataset_info[job_name] = sim_info[sim]
            dataset_info[job_name]["sim"] = sim
            dataset_info[job_name]["lc"] = lc_name
            dataset_info[job_name]["pippin_output"] = pippin_output
        end
    end
    return dataset_info
end

function load_all_datasets(options::Vector, global_config::Dict)
    datasets = Dict{String, Vector{AbstractString}}()
    for option in options
        path = option["path"]
        if !isdir(path)
            path = joinpath(global_config["base_path"], path)
        end
        @info "Loading supernova datasets from $path"
        yml = get(option, "yml", "")
        dataset_info = prepare_dataset_info(path, option["path"], yml)
        for key in keys(dataset_info)
            @info "Loading $key dataset"
            datasets[key] = get_dataset_paths(dataset_info[key], key, global_config["dataset_path"], global_config["rerun"])
        end
    end
    return datasets
end

function calculate_all_distance_matrices(dataset_paths::Dict{String, Vector{AbstractString}}, options::Vector, global_config::Dict)
    distance_matrix_paths = Dict{String, Vector{AbstractString}}()
    for option in options
        for key in keys(dataset_paths)
            method = option["method"]
            @info "Creating distance matrix for dataset $key with method $method"
            dkey = "$(method)_$(key)"
            distance_matrix_paths[dkey] = get_distance_matrix_paths(dataset_paths[key], method, dkey, global_config["distance_matrix_path"], global_config["rerun"])
        end
    end
    return distance_matrix_paths
end

function run_analysis(distance_matrix_paths::Dict{String, Vector{AbstractString}}, dataset_paths::Dict{String, Vector{AbstractString}}, options::Vector, global_config::Dict)
    output_path = global_config["analysis_path"]
    rerun = global_config["rerun"]
    for option in options
        analysis_type = option["analysis"]
        analysis_opts = get(option, options, Dict())
        analyse(analysis_type, dataset_paths, distance_matrix_paths, analysis_opts, output_path, rerun)
    end
end

function run_SupernovaDistanceMatrix(toml::Dict)
    global_config = toml["global"]
    dataset_options = get(toml, "dataset", Vector())
    if length(dataset_options) > 0
        dataset_paths = load_all_datasets(dataset_options, global_config)
        @info "Loaded all datasets"
    else
        @warn "No datasets loaded, please load a dataset via [[ dataset ]]"
        dataset_paths = Dict{String, Vector{AbstractString}}()
    end
    distance_matrix_options = get(toml, "distance_matrix", Vector())
    if length(distance_matrix_options) > 0 
        distance_matrix_paths = calculate_all_distance_matrices(dataset_paths, distance_matrix_options, global_config)
        @info "Calculated all distance matrices"
    else
        @warn "No distance matrices created, please create a distance matrix via [[ distance_matrix ]]"
        distance_matrix_paths = Dict{String, Vector{AbstractString}}()
    end
    analysis_options = get(toml, "analysis", Vector())
    if length(analysis_options) > 0
        run_analysis(distance_matrix_paths, dataset_paths, analysis_options, global_config)
    end
end

end
