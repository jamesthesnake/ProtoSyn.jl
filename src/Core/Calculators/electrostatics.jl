module Electrostatics

    using ProtoSyn
    using ProtoSyn.Calculators: EnergyFunctionComponent, VerletList, MaskMap
    
    # TODO: Documentation

    """
    # TODO
    """
    function assign_acc2_eem_charges_from_file!(pose::Pose, filename::String)
        data = split(open(f->read(f, String), filename), "\n")[2]
        T = eltype(pose.state)
        charges = map((value) -> parse(T, value), split(data))
        for (i, atom) in enumerate(eachatom(pose.graph))
            pose.state[atom].δ = charges[i]
        end

        return charges
    end 
    

    """
    # TODO
    """
    function assign_default_charges!(pose::Pose, res_lib::LGrammar; supress_warn::Bool = false)

        for residue in eachresidue(pose.graph)

            # Get template residue by residue name
            name = string(ProtoSyn.three_2_one[residue.name.content])          
            template = res_lib.variables[name]
            if isa(template, Tautomer)
                # If multiple templates exist for a particular residue type,
                # find the correct tautomer matching the strucure's graph
                tautomer = ProtoSyn.find_tautomer(template, residue)
                if tautomer === nothing
                    # In case we don't have a template, for example, in
                    # no-sidechain models, try to apply the first tautomer
                    template = template.list[1]
                else
                    template = tautomer
                end
            end
            
            # Apply the template atom's charge to each of the residue's atoms
            for atom in residue.items
                if template.graph[1][atom.name] === nothing
                    !supress_warn && @warn "Template doesn't have atom $atom"
                    continue
                end # if
                δ = template.state[template.graph[1][atom.name]].δ
                pose.state[atom].δ = δ
            end # for
        end # for

        # Adjust the overall charge of all atoms so that the resulting charge of
        # the structure is ≈ 0.0
        cc = sum(getproperty.(pose.state.items, :δ)) / length(pose.state.items)
        for (i, atom) in enumerate(pose.state.items)
            atom.δ    -= cc
        end # for

        return getproperty.(pose.state.items, :δ)
    end # function

    # ---

    function calc_coulomb(::Type{A}, pose::Pose, selection::Opt{AbstractSelection}, update_forces::Bool; mask::MaskMap = nothing, vlist::Opt{VerletList} = nothing, potential::Function = (x) -> 0.0) where {A <: ProtoSyn.AbstractAccelerationType}
        e, f = ProtoSyn.Calculators.apply_potential(A, pose, potential, update_forces, vlist, selection, mask)
        if e === 0.0 && all(x -> x.δ === 0.0, pose.state.items[4:end])
            @warn "The calculated Coulomb energy is 0.0 and it seems the evaluated Pose does not have any assigned charges. Consider using the `ProtoSyn.Calculators.Electrostatics.assign_default_charges!` method."
        end # if

        return e, f
    end # function

    calc_coulomb(pose::Pose, selection::Opt{AbstractSelection}, update_forces::Bool; mask::MaskMap = nothing, vlist::Opt{VerletList} = nothing, potential::Function = (x) -> 0.0) = begin
        calc_coulomb(ProtoSyn.acceleration.active, pose, selection, update_forces; mask = mask, vlist = vlist, potential = potential)
    end

    function get_default_coulomb(;α::T = 1.0) where {T <: AbstractFloat}
        # _mask = ProtoSyn.Calculators.get_bonded_mask()
        # _mask = ProtoSyn.Calculators.get_intra_residue_mask(!SidechainSelection())
        return EnergyFunctionComponent(
            "Coulomb",
            calc_coulomb,
            # !SidechainSelection(),
            nothing, 
            Dict{Symbol, Any}(
                :mask => nothing,
                :vlist => nothing,
                :potential => ProtoSyn.Calculators.get_bump_potential_charges(c = 11.0, r = 8.5)),
            α,
            true)
    end

end