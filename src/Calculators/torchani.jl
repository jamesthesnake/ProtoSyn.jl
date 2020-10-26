module TorchANI

    using ProtoSyn: Pose, get_ani_species, get_cartesian_matrix
    using ProtoSyn.Calculators: EnergyFunctionComponent
    using PyCall

    const torch    = PyNULL()
    const torchani = PyNULL()
    const device   = PyNULL()
    const _model   = PyNULL()


    function calc_torchani_model(pose::Pose; model_index::Int = 3)
        
        c           = get_cartesian_matrix(pose)
        coordinates = torch.tensor([c], requires_grad = true, device = device).float()
        
        s           = get_ani_species(pose)
        species     = torch.tensor([s], device = device)
        
        m1 = _model.species_converter((species, coordinates))
        m2 = _model.aev_computer(m1)
        return get(_model.neural_networks, model_index)(m2)[2].item()
    end


    function calc_torchani_ensemble(pose::Pose)
        
        c           = get_cartesian_matrix(pose)
        coordinates = torch.tensor([c], requires_grad = true, device = device).float()
        
        s           = get_ani_species(pose)
        species     = torch.tensor([s], device = device)

        m1 = _model.species_converter((species, coordinates))
        m2 = _model.aev_computer(m1)
        return _model.neural_networks(m2)[2].item()
    end


    function __init__()
        copy!(torch, pyimport("torch"))
        copy!(torchani, pyimport("torchani"))

        if torch.cuda.is_available()
            copy!(device, torch.device("cuda"))
        else
            copy!(device, torch.device("cpu"))
        end
        
        copy!(_model, torchani.models.ANI2x(periodic_table_index = true).to(device))
    end

    torchani_model    = EnergyFunctionComponent("TorchANI_ML_Model", calc_torchani_model)
    torchani_ensemble = EnergyFunctionComponent("TorchANI_ML_Ensemble", calc_torchani_ensemble)
end
