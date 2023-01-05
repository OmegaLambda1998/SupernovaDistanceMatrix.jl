module DatasetModule

# External Packages
using ProgressMeter
using JLD2

# Internal Packages
using ..SupernovaModule
using ..SimModule
using ..LCModule

# Exports
export Dataset 
export get_dataset_paths
export load_dataset

struct Dataset 
    ω0::Float64
    Ωm::Float64
    ΩΛ::Float64
    supernovae::Vector{Supernova}
end

function Dataset(supernovae::Vector{Supernova})
    return Dataset(NaN, NaN, supernovae)
end

function save_dataset(dataset::Dataset, dataset_path::AbstractString)
    save(dataset_path, Dict(string(key) => getfield(dataset, key) for key in fieldnames(Dataset)))
end

function load_dataset(dataset_path::AbstractString)
    d = load(dataset_path)
    val = [d[string(key)] for key in fieldnames(Dataset)]
    return Dataset(val...)
end

function get_dataset_paths(dataset_info::Dict{String, Any}, dataset_name::String, output_path::AbstractString, rerun::Bool)
    dataset_path = joinpath(output_path, dataset_name) 
    if !isdir(dataset_path)
        mkpath(dataset_path)
    end
    ω0 = dataset_info["ω0"]
    Ωm = dataset_info["Ωm"]
    ΩΛ = dataset_info["ΩΛ"]
    num_datasets = dataset_info["num_datasets"]
    combine_datasets = dataset_info["combine_datasets"]
    pippin_output = dataset_info["pippin_output"]
    sim_path = joinpath(pippin_output, "1_SIM", dataset_info["sim"])
    lc_path = joinpath(pippin_output, "2_LCFIT", dataset_info["lc"], "output")
    if !combine_datasets
        dataset_paths = Vector{AbstractString}(undef, num_datasets)
    else
        dataset_paths = Vector{AbstractString}(undef, 1)
        # Only need supernova_datasets allocated for combine_datasets
        supernova_datasets = Vector{Vector{Supernova}}(undef, num_datasets)
    end
    # num_datasets == 1 and combine_datasets have the same save_path
    p = Progress(num_datasets)
    lk = ReentrantLock()
    Threads.@threads for i in 1:num_datasets
        # Update save path if multiple datasets should be created
        if ((num_datasets == 1) || combine_datasets)
            save_path = joinpath(dataset_path, "$(dataset_name).jld2")
        else
            save_path = joinpath(dataset_path, "$(dataset_name)_$(i).jld2")
        end
        # Only run if you haven't already
        if rerun || !isfile(save_path)
            # Ensure correct naming of supernova file
            if num_datasets == 1
                supernovae = get_supernovae(sim_path, lc_path, 0)
            else
                supernovae = get_supernovae(sim_path, lc_path, i)
            end
            # combine_datasets will merge all supernovae later on
            if !combine_datasets
                dataset = Dataset(ω0, Ωm, ΩΛ, supernovae)
                lock(lk) do
                    save_dataset(dataset, save_path)
                end
            else
                @inbounds supernova_datasets[i] = supernovae
            end
        end
        # combine_datasets pushes save_path later
        if !combine_datasets
            @inbounds dataset_paths[i] = save_path
        end
        next!(p)
    end
    # Combine all supernovae, then create and save dataset
    if combine_datasets
        # Only run if you haven't already
        if rerun || !isfile(save_path)
            @assert length(Set(supernova_datasets)) == num_datasets "Number of supernovae $(length(Set(supernova_datasets))) not equal to number of datasets $num_datasets"
            supernovae = vcat(supernova_datasets...)
            dataset = Dataset(ω0, Ωm, ΩΛ, supernovae)
            save_dataset(dataset, save_path)
        end
        dataset_paths[1] = save_path
    else
        @assert length(Set(dataset_paths)) == num_datasets "Number of dataset paths $(length(Set(dataset_paths))) not equal to number of datasets $num_datasets"
    end
    return dataset_paths
end

end
