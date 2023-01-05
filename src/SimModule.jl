module SimModule

# External Packages

# Internal Packages

# Exports
export Sim
export get_sims

struct Sim
    cid::Int64
    z::Float64
    mu::Float64
    mjd::Float64
end

function get_sims(sim_path::AbstractString, i::String="")
    sim_dirs = readdir(sim_path)
    output_dir = joinpath(sim_path, sim_dirs[findfirst(x -> (contains(x, i)) && (contains(x, "PIP")), sim_dirs)])
    sim_files = readdir(output_dir)
    dump_file = joinpath(output_dir, sim_files[findfirst(x -> contains(x, "DUMP"), sim_files)])
    sims = Dict{Int64, Sim}()
    open(dump_file, "r") do io
        lines = [line for line in readlines(io) if (line != "")] # Remove empty lines
        lines = [line for line in lines if !contains(line, "#")] # Remove comments
        header = split(lines[1], " ")
        values = [split(line, " ") for line in lines[2:end]]
        cid_ind = findfirst(x -> x == "CID", header)
        z_ind = findfirst(x -> x == "GENZ", header)
        mu_ind = findfirst(x -> x == "MU", header)
        mjd_ind = findfirst(x -> x == "MJD0", header)
        for value in values
            cid = parse(Int64, value[cid_ind])
            z = parse(Float64, value[z_ind])
            mu = parse(Float64, value[mu_ind])
            mjd = parse(Float64, value[mjd_ind])
            sims[cid] = Sim(cid, z, mu, mjd)
        end
    end
    return sims
end

end
