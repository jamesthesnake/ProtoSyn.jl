module SteepestDescent

using ..Aux
using ..Common
using ..Drivers
using Printf
using LinearAlgebra

@doc raw"""
    SteepestDescentDriver(evaluator!::Function[, n_steps::Int64 = 0, f_tol::Float64 = 1e-3, max_step:Float64 = 0.1])

Define the runtime parameters for the Steepest Descent simulation.
If `n_steps` is zero, a `single point` energy calculation is performed.

# Arguments
- `evaluator!::Function`: Responsible for evaluating the current `state.energy` and calculate the resulting forces. This function should have the following signature:
```
evaluator!(state::Common.State, do_forces::Bool)
```
- `n_steps`: (Optional) Total amount of steps to be performed (if convergence is not achieved before) (Default: 0).
- `f_tol`: (Optional) Force tolerance. Defines a finalization criteria, as the steepest descent is considered converged if the maximum force calculated is below this value (Default = 1e-3).
- `max_step`: (Optional) Defines the maximum value ɣ that the system can jump when applying the forces (Default: 0.1).

# Examples
```julia-repl
julia> Drivers.SteepestDescent.SteepestDescentDriver(my_evaluator!, 100, 1e-3, 0.1)
SteepestDescentDriver(evaluator=my_evaluator!, n_steps=100, f_tol=1e-3, max_step=0.1)

julia> Drivers.SteepestDescent.SteepestDescentDriver(my_evaluator!, f_tol = 1e-6)
SteepestDescentDriver(evaluator=my_evaluator!, n_steps=0, f_tol=1e-6, max_step=0.1)
```
!!! tip
    The `my_evaluator!` function often contains an aggregation of pre-defined functions avaliable in [Forcefield](@ref Forcefield). It is possible to combine such functions using the [`@faggregator`](@ref Common) macro.

See also: [`Amber.evaluate!`](@ref Forcefield) [`run!`](@ref)
"""
mutable struct Driver <: Drivers.AbstractDriver
    
    run!::Function
    evaluator!::Function
    n_steps::Int64
    f_tol::Float64        # (Default: 1e-3)
    max_step::Float64     # (Default: 0.1)
    callbacks::Tuple

end
Driver(evaluator!::Function, n_steps::Int64 = 0, f_tol::Float64 = 1e-3, max_step::Float64 = 0.1, callbacks::Common.CallbackObject...) = Driver(run!, evaluator!, n_steps, f_tol, max_step, callbacks)
Base.show(io::IO, b::Driver) = print(io, "SteepestDescent.Driver(evaluator=$(string(b.evaluator!)), n_steps=$(b.n_steps), f_tol=$(b.f_tol))")

# ----------------------------------------------------------------------------------------------------------
#                                                   RUN

@doc raw"""
    run!(state::Common.State, driver::SteepestDescentDriver[, callback::Union{Common.CallbackObject, Nothing} = nothing])

Run the main body of the Driver. If `driver.n_steps` is zero, a `single point` energy calculation is performed.

# Arguments
- `state::Common.State`: Current state of the system to be modified.
- `driver::SteepestDescentDriver`: Defines the parameters for the SteepestDescent simulation. See [`SteepestDescentDriver`](@ref).
- `callbacks::Vararg{Common.CallbackObject, N}`: (Optional) Tuple of [`CallbackObject`](@ref Common)s (Default: empty).

The [`CallbackObject`](@ref Common) in this Driver returns the following extra Varargs (in order):
- `max_force::Float64`: The maximum force experienced by the system in the current step.
- `gamma::Float64`: The simulation gamma (ɣ) value for the current step.

!!! tip
    The callback function often contains a [Print](@ref) function.

# Examples
```julia-repl
julia> Drivers.SteepestDescent.run(state, steepest_descent_driver, callback1, callback2, callback3)
```
"""
function run!(state::Common.State, driver::Driver, callbacks::Common.CallbackObject...)

    @inline function get_max_force(f::Array{Float64, 2})
        return sqrt(maximum(sum(f.*f, dims = 2)))
    end

    @inline function system_converged()::Bool
        if max_force < driver.f_tol
            println("Achieved convergence (f_tol < $(driver.f_tol)) in $step steps.\n")
            return true
        end
        if gamma < eps()
            println("Gamma below machine precision! Exiting after $step steps...\n")
            return true
        end
        return false
    end

    # Evaluate initial energy and forces
    step::Int64 = 1
    gamma::Float64 = driver.max_step
    energy::Float64 = driver.evaluator!(state, true)
    max_force::Float64  = get_max_force(state.forces)
    if system_converged()
        return
    end
    energy_old = energy
        
    # Initial callback
    @Common.cbcall driver.callbacks..., callbacks... step state driver max_force gamma
    
    while step < driver.n_steps
        gamma = min(gamma, driver.max_step)
        step_size = gamma / get_max_force(state.forces)
        @. state.xyz += step_size * state.forces

        # Housekeep variables
        energy_old = energy

        # Calculate new energy and forces
        fill!(state.forces, 0.0)
        energy = driver.evaluator!(state, true)
        max_force = get_max_force(state.forces)

        if system_converged()
            break
        end
        
        # Update gamma
        if energy >= energy_old
            gamma *= 0.90
        else
            gamma *= 1.05
        end

        step += 1
        @Common.cbcall driver.callbacks..., callbacks... step state driver max_force gamma
    end
end

end