using ProtoSyn.Calculators: EnergyFunction
using ProtoSyn.Mutators: AbstractMutator

Base.@kwdef mutable struct MonteCarloState{T <: AbstractFloat} <: DriverState
    step::Int        = 0
    converged::Bool  = false
    completed::Bool  = false
    stalled::Bool    = false
    acceptance_count = 0
    temperature::T   = 0.0
end


mutable struct MonteCarlo <: Driver
    eval!::Union{Function, EnergyFunction}
    sample!::Union{Function, AbstractMutator, Driver}
    callback::Opt{Callback}
    max_steps::Int
    temperature::Function
end


function (driver::MonteCarlo)(pose::Pose)
    
    T = eltype(pose.state)
    driver_state = MonteCarloState{T}()
    driver_state.temperature = driver.temperature(0)
    
    previous_state  = copy(pose)
    previous_energy = driver.eval!(pose, update_forces = false)
    driver.callback !== nothing && driver.callback(pose, driver_state)
    
    while driver_state.step < driver.max_steps
            
        driver.sample!(pose)
        sync!(pose)
        energy = driver.eval!(pose, update_forces = false)
        
        n = rand()
        driver_state.temperature = driver.temperature(driver_state.step)
        m = exp((-(energy - previous_energy)) / driver_state.temperature)
        if (energy < previous_energy) || (n < m)
            previous_energy = energy
            previous_state = copy(pose)
            driver_state.acceptance_count += 1
            println("Accepted:\n Current E: $(pose.state.e[:Total])\n Saved: $(previous_state.state.e[:Total])")
        else
            e = pose.state.e[:Total]
            ProtoSyn.recoverfrom!(pose, previous_state)
            println("Not accepted:\n Was: $e\n Current: $(pose.state.e[:Total]) ($(previous_state.state.e[:Total]))")
        end

        driver_state.step += 1
        driver.callback !== nothing && driver.callback(pose, driver_state)
        println("Here: $(pose.state.e[:Total])")
        println("ID: $(pose.state.id)")
    end

    driver_state.completed = true
    driver_state
    println("FINAL saved: $(pose.state.e[:Total])")
    println("FINAL eval : $(driver.eval!(pose))")
    println("ID: $(pose.state.id)")
    return pose
end