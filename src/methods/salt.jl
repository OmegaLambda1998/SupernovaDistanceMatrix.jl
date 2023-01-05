export salt

function salt(dataset::Dataset)
    return salt(dataset, dataset)
end

function salt(dataset_1::Dataset, dataset_2::Dataset)
    ω0_1 = dataset_1.ω0
    Ωm_1 = dataset_1.Ωm
    ΩΛ_1 = dataset_1.ΩΛ
    supernovae_1 = dataset_1.supernovae
    ω0_2 = dataset_2.ω0
    Ωm_2 = dataset_2.Ωm
    ΩΛ_2 = dataset_2.ΩΛ
    supernovae_2 = dataset_2.supernovae
    matrix = zeros(Float64, length(supernovae_1), length(supernovae_2))
    for i in 1:length(supernovae_1)
        sn_1 = supernovae_1[i]
        lc_1 = sn_1.lc
        zHD_1 = lc_1.zHD
        x1_1 = lc_1.x1
        c_1 = lc_1.c
        x0_1 = lc_1.x0
        mb_1 = -2.5 * log10(x0_1)
        mu_1 = mb_1 + x1_1 - c_1
        for j in 1:length(supernovae_2)
            sn_2 = supernovae_2[j]
            lc_2 = sn_2.lc
            zHD_2 = lc_2.zHD
            x1_2 = lc_2.x1
            c_2 = lc_2.c
            x0_2 = lc_2.x0
            mb_2 = -2.5 * log10(x0_2)
            mu_2 = mb_2 + x1_2 - c_2
            @inbounds matrix[i, j] = mu_1 - mu_2
        end
    end
    return DistanceMatrix((ω0_1, ω0_2), (Ωm_1, Ωm_2), (ΩΛ_1, ΩΛ_2), matrix)
end

