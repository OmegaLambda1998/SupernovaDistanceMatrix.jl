module DistanceMatrixModule

# External Packages
using ProgressMeter
using JLD2

# Internal Packages
using ..DatasetModule

# Exports
export DistanceMatrix
export load_distance_matrix
export get_distance_matrix_paths

struct DistanceMatrix
    ω0::Tuple{Float64, Float64}
    Ωm::Tuple{Float64, Float64}
    ΩΛ::Tuple{Float64, Float64}
    matrix::AbstractArray
end

function save_distance_matrix(distance_matrix::DistanceMatrix, distance_matrix_path::AbstractString)
    save(distance_matrix_path, Dict(string(key) => getfield(distance_matrix, key) for key in fieldnames(DistanceMatrix)))
end

function load_distance_matrix(distance_matrix_path::AbstractString)
    d = load(distance_matrix_path)
    val = [d[string(key)] for key in fieldnames(DistanceMatrix)]
    return DistanceMatrix(val...)
end

# Load in all distance matrix functions 
# All functions must export themselves
methods_path = joinpath(@__DIR__, "methods")
methods = Vector{String}() 
for path in readdir(methods_path, join=true)
    if isfile(path)
        include(path)
        push!(methods, splitpath(splitext(path)[1])[end])
    end
end

function get_method(method_name::String)
    try
        method = getfield(DistanceMatrixModule, Symbol(method_name))
        return method
    catch e
        @error "Can not find distance matrix method named '$method_name', options include: $methods"
        return nothing
    end
end

function get_distance_matrix_paths(dataset_paths::Vector{AbstractString}, method_name::String, distance_matrix_name::String, output_path::AbstractString, rerun::Bool)
    distance_matrix_path = joinpath(output_path, distance_matrix_name)
    if !isdir(distance_matrix_path)
        mkpath(distance_matrix_path)
    end
    distance_matrix_paths = Vector{AbstractString}(undef, length(dataset_paths))
    p = Progress(length(dataset_paths))
    lk = ReentrantLock()
    Threads.@threads for i in 1:length(dataset_paths)
        path = dataset_paths[i]
        save_path = joinpath(distance_matrix_path, basename(path))
        if rerun || !isfile(save_path)
            method = get_method(method_name)
            dataset = load_dataset(path)
            distance_matrix = method(dataset)
            lock(lk) do
                save_distance_matrix(distance_matrix, save_path)
            end
        end
        distance_matrix_paths[i] = save_path
        next!(p)
    end
    @assert length(Set(distance_matrix_paths)) == length(dataset_paths) "Number of distance matrix paths $(length(Set(dataset_paths))) not equal to number of datasets $(length(dataset_paths))"
    return distance_matrix_paths 
end

end
