module AnalysisModule

# External Packages

# Internal Packages
using ..DatasetModule
using ..DistanceMatrixModule

# Exports
export analyse 

function analyse(analysis_type::String, dataset_paths::Dict{String, Vector{AbstractString}}, distance_matrix_paths::Dict{String, Vector{AbstractString}}, analysis_opts::Dict, output_path::AbstractString, rerun::Bool)
    if analysis_type == "print"
        print_matrices(distance_matrix_paths)
    else
        @warn "Unkown analysis type: $analysis_type"
    end
end

function print_matrices(distance_matrix_paths::Dict{String, Vector{AbstractString}})
    for (name, paths) in distance_matrix_paths
        distance_matrix = load_distance_matrix(paths[1])
        ω0 = distance_matrix.ω0
        Ωm = distance_matrix.Ωm
        ΩΛ = distance_matrix.ΩΛ
        sizes = Vector{Tuple{Int64, Int64}}()
        distance_matrix_checks = Vector{Bool}()
        for path in paths
            distance_matrix = load_distance_matrix(path)
            matrix = distance_matrix.matrix
            push!(sizes, size(matrix))
            push!(distance_matrix_checks, isdistancematrix(matrix))
        end
        @info """Distance Matrix $name has
            ω0: $ω0
            Ωm: $Ωm
            ΩΛ: $ΩΛ
            Matrices:
                Sizes = $(sizes)
                All matrices are distance matrices (A[i, j] == -A[j, i] & A[i, i] == 0]: $(all(distance_matrix_checks))
        """
    end
end

function isdistancematrix(A)
    if size(A, 1) != size(A, 2)
        return false
    end
    @simd for i in 1:size(A, 1)
        @simd for j in 1:size(A, 2)
            if i != j
                @inbounds if (A[i, j] != -A[j, i])
                    return false
                end
            else
                @inbounds if A[i, j] != 0
                    return false
                end
            end
        end
    end
    return true
end

end
