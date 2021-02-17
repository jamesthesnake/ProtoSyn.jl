using Printf

mutable struct EnergyFunction{T <: AbstractFloat}

    components::Dict{EnergyFunctionComponent, T}
    clean_cache_every::Int16
    cache::Int16
end

EnergyFunction() = begin
    return EnergyFunction(ProtoSyn.Units.defaultFloat)
end

EnergyFunction(::Type{T}) where {T <: AbstractFloat} = begin
    return EnergyFunction(Dict{EnergyFunctionComponent, T}())
end

EnergyFunction(components::Dict{EnergyFunctionComponent, T}) where {T <: AbstractFloat} = begin
    return EnergyFunction{T}(components, ProtoSyn.Units.defaultCleanCacheEvery, Int16(0))
end


function (energy_function::EnergyFunction)(pose::Pose; update_forces::Bool = false)
    e = 0.0
    performed_calc = false
    for (component, ɑ) in energy_function.components
        if ɑ > 0.0
            energy, forces = component.calc(pose, update_forces = update_forces)
            performed_calc = true
            e_comp         = ɑ * energy
            pose.state.e[Symbol(component.name)] = e_comp
            e += e_comp

            if update_forces & !(forces === nothing)
                for atom_index in 1:pose.state.size
                    pose.state.f[:, atom_index] += forces[:, atom_index] .* ɑ
                end
            end
        end
    end

    # Perform memory allocation clean-up and maintenance
    if performed_calc
        energy_function.cache += 1
        if energy_function.cache % energy_function.clean_cache_every == 0
            GC.gc(false)
            energy_function.cache = 0
        else
            alloc = ProtoSyn.gpu_allocation()
            if alloc > ProtoSyn.Units.max_gpu_allocation
                GC.gc(false)
                energy_function.clean_cache_every = energy_function.cache
                energy_function.cache = 0
            end
        end
    end

    pose.state.e[:Total] = e
    return e
end


function Base.show(io::IO, efc::EnergyFunction)
    println(io, "\n+"*repeat("-", 58)*"+")
    @printf(io, "| %-5s | %-35s | %-10s |\n", "Index", "Component name", "Weight (ɑ)")
    println(io, "+"*repeat("-", 58)*"+")
    for (index, (component, ɑ)) in enumerate(efc.components)
        @printf(io, "| %-5d | %-35s | %-10.3f |\n", index, component.name, ɑ)
    end
    println(io, "+"*repeat("-", 58)*"+")
end

function Base.copy(ef::EnergyFunction)
    nef = EnergyFunction()
    nef.clean_cache_every = ef.clean_cache_every
    for (component, α) in ef.components
        nef.components[component] = α
    end
    return nef
end

function component_by_name(ef::EnergyFunction, component_name::String)
    for (component, α) in ef.components
        if component.name == component_name
            return component
        end
    end
    return nothing
end