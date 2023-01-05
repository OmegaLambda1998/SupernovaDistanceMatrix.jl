module SupernovaModule

# External Packages

# Internal Packages
using ..SimModule
using ..LCModule

# Exports
export Supernova 
export get_supernovae

struct Supernova
    cid::Int64
    sim::Sim
    lc::LC
end

function get_supernovae(sim_path::AbstractString, lc_path::AbstractString, i::Int64=0)
    if i > 0
        i = lpad(i, 4, "0")
    else
        i = ""
    end
    sims = get_sims(sim_path, i)
    lcs = get_lcs(lc_path, i)
    supernovae = Vector{Supernova}()
    for cid in keys(lcs)
        sim = sims[cid]
        lc = lcs[cid]
        push!(supernovae, Supernova(cid, sim, lc))
    end
    return supernovae
end

end
