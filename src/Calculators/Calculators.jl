module Calculators

using ProtoSyn
using Base.Cartesian

@time begin
    include("verlet_list.jl")
    include("serial.jl")

    @info " | Loading SIMD"
    using SIMD
    include("simd.jl")

    @info " | Loading CUDA"
    include("cuda.jl")

    # Load energy function components
    struct EnergyFunctionComponent

        name::String
        calc::Function
    end

    @info " | Loading TorchANI"
    include("torchani.jl")

    @info " | Loading Caterpillar Model"
    include("caterpillar.jl")

    @info " | Loading Energy Function"
    include("energy_function.jl")
end

end