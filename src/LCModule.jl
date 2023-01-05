module LCModule

# External Packages
using GZip

# Internal Packages

# Exports
export LC
export get_lcs

struct LC
    cid::Int64
    zHD::Float64
    zHDERR::Float64
    x1::Float64
    x1ERR::Float64
    c::Float64
    cERR::Float64
    x0::Float64
    x0ERR::Float64
end

function get_lcs(lc_path::AbstractString, i::String="")
    lc_dirs = readdir(lc_path)
    fitres_file = joinpath(lc_path, lc_dirs[findfirst(x -> (contains(x, i)) && (contains(x, "PIP")), lc_dirs)], "FITOPT000.FITRES.gz")
    lcs = Dict{Int64, LC}()
    GZip.open(fitres_file, "r") do io
        lines = [line for line in readlines(io) if (line != "")] # Remove empty lines
        lines = [line for line in lines if !contains(line, "#")] # Remove comments
        header = split(lines[1], " ")
        values = [split(line, " ") for line in lines[2:end]]
        cid_ind = findfirst(x -> x == "CID", header) - 1
        zHD_ind = findfirst(x -> x == "zHD", header) - 1
        zHDERR_ind = findfirst(x -> x == "zHDERR", header) - 1
        x1_ind = findfirst(x -> x == "x1", header) - 1
        x1ERR_ind = findfirst(x -> x == "x1ERR", header) - 1
        c_ind = findfirst(x -> x == "c", header) - 1
        cERR_ind = findfirst(x -> x == "cERR", header) - 1
        x0_ind = findfirst(x -> x == "x0", header) - 1
        x0ERR_ind = findfirst(x -> x == "x0ERR", header) - 1
        for value in values
            cid = parse(Int64, value[cid_ind])
            zHD = parse(Float64, value[zHD_ind])
            zHDERR = parse(Float64, value[zHDERR_ind])
            x1 = parse(Float64, value[x1_ind])
            x1ERR = parse(Float64, value[x1ERR_ind])
            c = parse(Float64, value[c_ind])
            cERR = parse(Float64, value[cERR_ind])
            x0 = parse(Float64, value[x0_ind])
            x0ERR = parse(Float64, value[x0ERR_ind])
            lcs[cid] = LC(cid, zHD, zHDERR, x1, x1ERR, c, cERR, x0, x0ERR)
        end
    end
    return lcs
end

end
