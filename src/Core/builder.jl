module Builder

using ..ProtoSyn

export StochasticRule, LGrammar
export derive, build, lgfactory

struct StochasticRule{K,V}
    p::Float64
    # rule::T
    source::K
    production::V
    StochasticRule(p::Float64, rule::Pair{K,V}) where {K,V} = begin
        (p > 1 || p < 0) && error("Invalid probability")
        new{K,V}(p, rule.first, rule.second)
    end
end


mutable struct LGrammar{K,V}
    rules::Dict{K, Vector{StochasticRule{K,V}}}
    variables::Dict{K, Fragment}
    operators::Dict{K, Function}
    defop::Opt{Function}
end


LGrammar{K,V}() where {K,V} = LGrammar(
    Dict{K, Vector{StochasticRule{K,V}}}(),
    Dict{K, Fragment}(),
    Dict{K, Function}(),
    nothing
)


getrule(g::LGrammar, r) = begin
    if !haskey(g.rules, r)
        return r
    end
    
    i = 1
    p = rand()
    ruleset = g.rules[r]
    x = ruleset[1].p
    while x < p
        x += ruleset[(i+=1)].p
    end
    ruleset[i].production
end


getvar(g::LGrammar, k) = begin
    !haskey(g.variables, k) && throw(KeyError(k))
    g.variables[k]
end


getop(g::LGrammar, k) = begin
    !haskey(g.operators, k) && throw(KeyError(k))
    g.operators[k]
end

hasrule(g::LGrammar, r) = haskey(g.rules, r)

Base.push!(g::LGrammar{K,V}, r::StochasticRule{K,V}) where {K,V} = begin
    push!(
        get!(g.rules, r.source, []),
        r
    )
    g
end


Base.setindex!(g::LGrammar{K,V}, x::Fragment, key::K) where {K,V} = begin
    g.variables[key] = x
    g
end


Base.setindex!(g::LGrammar{K,V}, x::Function, key::K) where {K,V} = begin
    g.operators[key] = x
    g
end


derive(lg::LGrammar, axiom) = begin
    derivation = []
    for x in axiom
        if hasrule(lg, x)
            append!(derivation, getrule(lg, x))
        else
            push!(derivation, x)
        end
    end
    derivation
end
# [
#     x
#     for r in axiom
#         for x in getrule(lg,r) ]

derive(lg::LGrammar, axiom, niter::Int) = begin
   niter > 0 ? derive(lg, derive(lg, axiom), niter-1) : axiom
end


isop(lg::LGrammar, k) = haskey(lg.operators, k)
isvar(lg::LGrammar, k) = haskey(lg.variables, k)

function fragment(::Type{T}, grammar::LGrammar, derivation) where {T<:AbstractFloat}

    state = State{T}()
    seg = Segment("UNK", 1)
    seg.code = 'A'

    stack = Fragment[]
    opstack = Function[]
    parent::Opt{Fragment} = nothing

    for letter in derivation
        if isop(grammar, letter)
            op = getop(grammar, letter)
            push!(opstack, op)
        elseif letter == '['
            push!(stack, parent)
        elseif letter == ']'
            parent = pop!(stack)
        elseif isvar(grammar, letter)
            frag = getvar(grammar, letter)
            
            frag2 = copy(frag)

            push!(seg, frag2.graph.items...)
            append!(state, frag2.state)
            if parent !== nothing
                join = isempty(opstack) ? grammar.defop : pop!(opstack)
                #println(join)
                join(parent, frag2)
            end
            parent = frag2
        end
    end
    reindex(seg)
    seg.id = state.id = ProtoSyn.genid()

    return Pose(seg, state)
end


function build(::Type{T}, grammar::LGrammar, derivation) where {T<:AbstractFloat}
    top = Topology("UNK", 1)
    state = State{T}()
    state.id = top.id
    pose = Pose(top, state)

    if !isempty(derivation)
        frag = fragment(T, grammar, derivation)
        append(pose, frag)
        # reindex(top)
        ProtoSyn.request_i2c(state; all=true)
    end
    pose
end
build(grammar::LGrammar, derivation) = build(Float64, grammar, derivation)

export @seq_str
macro seq_str(s); [string(c) for c in s]; end

function opfactory(args)
    return function(f1::Fragment, f2::Fragment)
        r1 = f1.graph[end]
        r2 = f2.graph[ 1 ]
        ProtoSyn.join(r1, args["residue1"], r2, args["residue2"])
        state = f2.state
        
        if haskey(args, "presets")
            for (atname,presets) in args["presets"]
                atomstate = state[r2[atname]]
                for (key,value) in presets
                    setproperty!(atomstate, Symbol(key), value)
                end
            end
        end

        if haskey(args, "offsets")
            for (atname,offset) in args["offsets"]
                setoffset!(state, r2[atname], offset)
            end
        end

    end
end



"""
# Example
```yml
amylose:
  rules:
    A:
      - {p: 0.75, production: [A,α,A]}
      - {p: 0.25, production: [B,"[",α,A,"]",β,A]}
      - {p: 0.25, production: [B,+,α,A,-,β,A]}
      - {p: 0.25, production: [B,↓,α,A,↑,β,A]}
  variables:
    A: resources/Sugars/GLC14.pdb
  operators:
    α14:
      residue1: C1
      residue2: O4
      presets:
        O4: {θ: 127, ϕ: -90.712, b: 1.43}
        C4: {θ: 100, ϕ: -103.475}
      offsets:
        H4: 0
  defop: α14
```
"""
function lgfactory(::Type{T}, template::Dict) where T
    grammar = LGrammar{String,Vector{String}}()

    vars = template["variables"]
    for (key,name) in vars
        println(name)
        pose = ProtoSyn.load(T, name)
        #if !hasgraph(pose.graph)
        #    build_graph!(pose.graph)
        #    ProtoSyn.c2i!(pose.state, pose.graph)
        #end
        grammar[key] = ProtoSyn.fragment(pose)
    end

    ops = template["operators"]
    for (opname,opargs) in ops
        grammar[opname] = opfactory(opargs)
    end
    grammar.defop = Builder.getop(grammar, template["defop"])

    if haskey(template, "rules")
        for (key,rules) in template["rules"]
            for rule in rules
                sr = StochasticRule(rule["p"], key => rule["production"])
                push!(grammar, sr)
            end
        end
    end
    grammar
end

end