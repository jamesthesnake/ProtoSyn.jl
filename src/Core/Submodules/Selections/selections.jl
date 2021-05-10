export AbstractSelection
abstract type AbstractSelection end

abstract type AbstractStateMode end

struct Stateful <: AbstractStateMode end  # * Needs state to get selection
struct Stateless <: AbstractStateMode end # * Doesn't need state to get selection

export select

# --- Show ---------------------------------------------------------------------

function get_lead(levels::Opt{BitArray} = nothing)
    lead = ""
    levels === nothing && return lead

    for level in levels[1:(end - 1)]
        lead *= level ? " |  " : "   "
    end

    ending = levels[end] ? " ├── " : " └── "
    return lead * ending
end

# ------------------------------------------------------------------------------

include("masks.jl")
include("promotion.jl")
include("binary.jl")
include("field.jl")
include("serial.jl")
include("unary.jl")
include("true.jl")
include("distance.jl")
include("random.jl")
include("terminal.jl")


# --- Resolve Function ---------------------------------------------------------
function (sele::AbstractSelection)(container::AbstractContainer; gather::Bool = false)
    mask = select(sele, container)
    if gather
        return ProtoSyn.gather(mask, container)
    end
    return mask
end

function (sele::AbstractSelection)(container::AbstractContainer, state::State; gather::Bool = false)
    if state_mode_type(sele) == Stateful
        mask = select(sele, container)(state)
        if gather
            return ProtoSyn.gather(mask, container)
        end
        return mask
    else
        mask = select(sele, container)
        if gather
            return ProtoSyn.gather(mask, container)
        end
        return mask
    end
end

(sele::AbstractSelection)(pose::Pose; gather::Bool = false) = sele(pose.graph, pose.state; gather = gather)


# --- Gather Function ----------------------------------------------------------
"""
    ProtoSyn.gather(mask::Mask{T}, container::AbstractContainer) where {T <: AbstractContainer}

Gather all instances of type `T` from `container` whose relative position is
marked as `true` in the given `mask`.

# Examples
```jldoctest
julia> ProtoSyn.gather(rn"ALA"(pose), pose.graph)
2-element Array{Residue,1}:
 Residue{/UNK:1/UNK:1/ALA:1}
 Residue{/UNK:1/UNK:1/ALA:2}
```
"""
function gather(mask::Mask{T}, container::AbstractContainer) where {T <: AbstractContainer}
    results = Vector{T}()
    for (index, item) in enumerate(iterator(T)(container))
        if mask[index]
            push!(results, item)
        end
    end
    return results
end


# ---

# --- Polarity
# export PolarSelection
# mutable struct PolarSelection{M, T} <: AbstractSelection
#     PolarSelection{}() = new{Stateless, Residue}(true)
# end

# # --- Select -------------------------------------------------------------------
# function select(::PolarSelection, container::AbstractContainer)

#     n_residues = count_residues(container)
#     mask = Mask{Residue}(n_residues)

#     for residue in eachresidue(container)
#         if residue.name in ["ARG", "ASN", "ASP", "GLU", "GLN", "HIS", "LYS", "SER", "THR", "TYR"]
#             mask[residue.index] = true
#         end
#     end
#     return mask
# end

# state_mode_type(::PolarSelection{M, T}) where {M, T} = M

export print_selection
function print_selection(pose::Pose{Topology}, mask::Mask{T}, filename::String) where {T <: AbstractContainer}

    io = open(filename, "w")

    if selection_type(mask) != Atom
        mask  = promote(mask, Atom, pose.graph)
    end
    
    Base.write(io, "MODEL\n")
    for (atom_index, atom) in enumerate(eachatom(pose.graph))
        sti = pose.state[atom.index] # returns and AtomState instance

        # In this file, selected atoms will be displayed in red while
        # non-selected atoms will be displayed in blue
        atom_symbol = mask[atom_index] ? "O" : "N"

        s = @sprintf("ATOM  %5d %4s %3s %s%4d    %8.3f%8.3f%8.3f%24s\n",
            atom.index, atom_symbol,
            atom.container.name, atom.container.container.code,
            atom.container.id,
            sti.t[1], sti.t[2], sti.t[3],
            atom_symbol)
            Base.write(io, s)
    end

    for atom in eachatom(pose.graph)
        Base.write(io, @sprintf("CONECT%5d", atom.index))
       foreach(n->Base.write(io, @sprintf("%5d",n.index)), atom.bonds)
       Base.write(io,"\n")
    end
    Base.write(io, "ENDMDL")
    close(io)
end