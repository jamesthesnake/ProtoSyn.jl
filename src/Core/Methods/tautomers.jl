

"""
# TODO
# uses first atom of template
"""
function find_tautomer(tautomer::Tautomer, target::Residue)
    target_res   = copy(target)
    target_atoms = ProtoSyn.travel_graph(target_res[1], sort_bonds = true)
    target_graph = [a.symbol for a in target_atoms]
    for template_residue in tautomer.list
        template_res   = copy(template_residue.graph[1])
        template_atoms = ProtoSyn.travel_graph(template_res[1], sort_bonds = true)
        template_graph = [a.symbol for a in template_atoms]

        match = all(target_graph .=== template_graph)
        match && return template_residue
    end

    return nothing
end