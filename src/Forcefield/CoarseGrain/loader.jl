@doc raw"""
    load_solv_pairs_from_file(c_αs::Vector{Int64}, input_file::String[, λ::Float64 = 1.0])::Vector{SolvPair}

Read an RSA map file and apply each solvation coeficient to the correspondent residue in [`SolvPair`] (@ref)'s.

# Examples
```julia-repl
julia> Forcefield.CoarseGrain.load_solv_pairs_from_file(c_αs, "rsa_map.txt", λ = 2.0)
[Forcefield.CoarseGrain.SolvPair(i=1, coef=-3.5), Forcefield.CoarseGrain.SolvPair(i=2, coef=2.0), ...]
```
"""
function load_solv_pairs_from_file(c_αs::Vector{Int64}, input_file::String; λ::Float64 = 1.0)::Vector{SolvPair}

    coefs::Vector{Int64} = Int64[]
    confidences::Vector{Int64} = Int64[]
    solv_pairs::Vector{SolvPair} = SolvPair[]
    open(input_file) do f
        index::Int64 = 1
        for line in eachline(f)
            if index == 1
                coefs = [parse(Int64, x) for x in line]
                coefs .-= 3
            else
                confidences = [parse(Int64, x) for x in line]
            end # end if
            index += 1
        end # end for
    end # end do

    for (index, c_α) in enumerate(c_αs)
        push!(solv_pairs, SolvPair(c_α, coefs[index] * confidences[index] * λ))
    end # end for
    printstyled("(SETUP) ▲ Loaded $(length(solv_pairs)) solvation pairs\n", color = 9)
    return solv_pairs
end # end function

@doc raw"""
    compile_solv_pairs(phi_dihedrals::Vector{Common.Dihedral}[, λ::Float64])::Vector{SolvPair}

Apply default solvation coeficients to the correspondent residue in [`SolvPair`] (@ref)s.
Return list of [`SolvPair`] (@ref)s.

# Examples
```julia-repl
julia> Forcefield.CoarseGrain.compile_solv_pairs(phi_dihedrals, λ=0.01)
[Forcefield.CoarseGrain.SolvPair(i=1, coef=-3.5), Forcefield.CoarseGrain.SolvPair(i=2, coef=2.0), ...]
```
"""
function compile_solv_pairs(phi_dihedrals::Vector{Common.Dihedral}; λ::Float64 = 1.0)::Vector{SolvPair}
    solv_pairs = map(x -> SolvPair(x.a3, default_aa_coef[string(x.residue.name[1])] * λ), phi_dihedrals)
    printstyled("(SETUP) ▲ Compiled $(length(solv_pairs)) solvation pairs\n", color = 9)
    return solv_pairs
end # end function

@doc raw"""
    compile_hb_network(atoms::Vector{Common.AtomMetadata}[, lib::Dict{String, Any} = Dict{String, Any}(), λ::Float64 = 1.0])::HbNetwork

Compile hydrogen bonding groups from atom metadata. Return an instance of HbNetwork.

# Examples
```julia-repl
julia> Forcefield.CoarseGrain.compile_hb_network(metadata.atoms, lib = hb_lib, λ=1.0)
Forcefield.CoarseGrain.HbNetwork(donors=10, acceptors=10, coef=1.0)
```
"""
function compile_hb_network(atoms::Vector{Common.AtomMetadata}; lib::Dict{String, Any} = Dict{String, Any}(), λ::Float64 = 1.0)::HbNetwork

    function retrieve_pairs!(target::Vector{HbPair}, source::Vector{Any}, residue::Vector{Common.AtomMetadata})
        if length(source) > 0
            for pair in source
                base = filter(atom -> atom.name == pair[1], residue)
                chargeds = filter(atom -> atom.name == pair[2], residue)
                if length(base) > 0 && length(chargeds) > 0
                    for charged in chargeds
                        push!(target, HbPair(charged.index, base[1].index))
                    end # end for
                end # end if
            end # end for
        end # end if
    end # end function

    hbNetwork = HbNetwork(coef = λ)
    for residue in Common.iterate_by_residue(atoms)
        aa = Aux.conv321(residue[1].res_name)
        if Aux.conv123(aa) == "PRO"
            continue
        end # end if

        # Backbone hydrogen bonds
        push!(hbNetwork.donors, HbPair(
            filter(atom -> atom.name == "H", residue)[1].index,
            filter(atom -> atom.name == "N", residue)[1].index))
        push!(hbNetwork.acceptors, HbPair(
            filter(atom -> atom.name == "O", residue)[1].index,
            filter(atom -> atom.name == "C", residue)[1].index))

        # Sidechains hydrogen bonds
        if length(lib) > 0 && aa in keys(lib)
            retrieve_pairs!(hbNetwork.donors, lib[aa]["D"], residue)
            retrieve_pairs!(hbNetwork.acceptors, lib[aa]["A"], residue)
        end # end if
    end # end for
    printstyled("(SETUP) ▲ Compiled $(length(hbNetwork)[1]) donor and $(length(hbNetwork)[2]) acceptor hydrogen bonding groups\n", color = 9)
    return hbNetwork
end # end function