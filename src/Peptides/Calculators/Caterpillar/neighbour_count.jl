"""
    ProtoSyn.Peptides.Calculators.Caterpillar.neighbour_count([::A], pose::Pose, update_forces::Bool = false; selection::AbstractSelection = ProtoSyn.TrueSelection{Atom}(), identification_curve::Function = null_identification_curve, hydrophobicity_weight::Function = null_hydrophobicity_weight, rmax::T = 9.0, sc::T = 1.0, Ω::Union{Int, T} = 750.0, hydrophobicity_map::Dict{String, T} = ProtoSyn.Peptides.doolitle_hydrophobicity) where {A, T <: AbstractFloat}

Calculate the given [`Pose`](@ref) `pose` caterpillar solvation energy using the
Neighbour Count (NC) algorithm (see [this article](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0020853)).
In this model, the burial degree `Ωi` of each atom is equal to the number
(count) os neighbouring [`Atom`](@ref) instances (within the defined `rmax`
cut-off (in Angstrom Å)) multiplied by a `w1` weight, provided by the 
`identification_curve` `Function`. This `Function` receives the distance between
each pair of neighbouring atoms (as a float), the `rmax` value and, optionally,
a slope control `sc` value, and return a weight `w1` (as a float). The
`identification_curve` signature is as follows:

```
identification_curve(distance::T; rmax::T = 9.0, sc::T = 1.0) where {T <: AbstractFloat}
```

In order to use pre-defined `identification_curve` `Function` instances defined
in ProtoSyn, check [`linear`](@ref) and [`sigmoid`](@ref).

Note that:
    - Shorter `rmax` value identify buried residues in the local environment (i.e.:
    in the scale of the secondary structure, recommended) while a larger `rmax`
    value identifies buried residues in the global scale (i.e.: in comparison with
    the whole structure).
    - The slope control `sc` value only has effect in sigmoid
    `identification_curve` `Function` instances. A smaller value augments the
    prevalence of distance information in the `w1` weight calculation, while a
    larger value defines a more strict cut-off (recommended);

An [`Atom`](@ref) is, therefore, considered buried if the number of neighbors 
(multiplied by `w1`) is over a defined cut-off value `Ω`. Buried hydrophobic
aminoacids receive an energetic reward, while exposed hydrophobic
[`Residue`](@ref) instances receive a penalty (and vice-versa for hydrophylic
aminoacids), defined in the provided `hydrophobicity_map` (hydrophobicity map
examples can be found in `Peptides.constants.jl`) and multiplied by `w2`,
calculated by the `hydrophobicity_weight` `Function`. This `Function` receives
the neighbor count `Ωi`, the `hydrophobicity_map_value` and the cut-off value
`Ω`, returning a `w2` weight (as a float).  The `hydrophobicity_weight`
signature is as follows:

```
hydrophobicity_weight(Ωi::Union{Int, T}; hydrophobicity_map_value::T = 0.0, Ω::Union{Int, T} = 0.0) where {T <: AbstractFloat}
```

In order to use pre-defined `hydrophobicity_weight` `Function` instances defined
in ProtoSyn, check [`scalling_exposed_only`](@ref),
[`non_scalling_exposed_only`](@ref), [`scalling_all_contributions`](@ref)
(recommended) and [`non_scalling_all_contributions`](@ref).

The optional `A` parameter defines the acceleration
mode used (SISD_0, SIMD_1 or CUDA_2). If left undefined the default
`ProtoSyn.acceleration.active` mode will be used. This function does not
calculate forces (not applicable), and therefore the `update_forces` flag serves
solely for uniformization with other energy-calculating functions.

# See also
[`neighbour_vector`](@ref)

# Examples
```
julia> ProtoSyn.Peptides.Calculators.Caterpillar.neighbour_count(pose, false)
(0.0, nothing)
```
"""
function neighbour_count(::Type{A}, pose::Pose, update_forces::Bool; selection::AbstractSelection = ProtoSyn.TrueSelection{Atom}(), identification_curve::Function = null_identification_curve, hydrophobicity_weight::Function = null_hydrophobicity_weight, rmax::T = 9.0, sc::T = 1.0, Ω::Union{Int, T} = 750.0, hydrophobicity_map::Dict{String, T} = ProtoSyn.Peptides.doolitle_hydrophobicity, kwargs...) where {A <: ProtoSyn.AbstractAccelerationType, T <: AbstractFloat}
    
    dm    = ProtoSyn.Calculators.full_distance_matrix(A, pose, selection)
    if A === ProtoSyn.CUDA_2
        dm = collect(dm)
    end
    atoms = selection(pose, gather = true)
    
    if length(atoms) != length(eachresidue(pose.graph))
        @warn "The number of selected residues doesn't match the number of residues in the pose ($(length(atoms)) ≠ $(length(eachresidue(pose.graph))))"
        return 0.0, nothing
    end
    
    Ωis = Vector{T}() # !
    esols = Vector{T}() # !
    esol = T(0.0)
    for i in 1:size(dm)[1]
        Ωi = 0.0
        for j in 1:size(dm)[2]
            i === j && continue
            Ωi += identification_curve(dm[i, j]; rmax = rmax, sc = sc)
        end

        DHI = hydrophobicity_map[atoms[i].container.name]
        esol_i = hydrophobicity_weight(Ωi, hydrophobicity_map_value = DHI, Ω = Ω)
        esol += esol_i
        
        push!(Ωis, Ωi) # !
        push!(esols, esol_i) # !
    end

    # return esol, nothing
    return esol, nothing, Ωis, esols 
end


neighbour_count(pose::Pose, update_forces::Bool; selection::AbstractSelection = ProtoSyn.TrueSelection{Atom}(), identification_curve::Function = null_identification_curve, hydrophobicity_weight::Function = null_hydrophobicity_weight, rmax::T = 9.0, sc::T = 1.0, Ω::Union{Int, T} = 750.0, hydrophobicity_map::Dict{String, T} = ProtoSyn.Peptides.doolitle_hydrophobicity, kwargs...) where {A <: ProtoSyn.AbstractAccelerationType, T <: AbstractFloat} = begin
    neighbour_count(ProtoSyn.acceleration.active, pose, update_forces,
        selection = selection,
        identification_curve = identification_curve,
        hydrophobicity_weight = hydrophobicity_weight,
        rmax = rmax,
        sc = sc, Ω = Ω,
        hydrophobicity_map = hydrophobicity_map)
end