
export @sym_str, @sn_str, @rn_str, @an_str, @x_str
export select


struct ById end
struct ByName end
struct BySymbol end

struct Stateless end
struct Statefull end

abstract type AbstractSelection end


state_rule(::Type{Stateless}, ::Type{Stateless}) = Stateless
state_rule(::Type{Statefull}, ::Type{Stateless}) = Statefull
state_rule(::Type{Stateless}, ::Type{Statefull}) = Statefull
state_rule(::Type{Statefull}, ::Type{Statefull}) = Statefull


clear(s::AbstractSelection...) = foreach(x->x.isentry=false, s)


#region LEAF SELECTORS

# =========================================================
mutable struct TrueSelection <: AbstractSelection
    isentry::Bool
    TrueSelection() = new(true)
end

state_type(::Type{TrueSelection}) = Stateless

name(io::IO, s::TrueSelection, prefix="", suffix="") = begin
    print(io, prefix)
    print(io, "TrueSelection()")
    println(io, suffix)
end

# =========================================================
mutable struct Selection{T} <: AbstractSelection
    isentry::Bool
    pattern::Union{AbstractString,Regex}
    match::Function
    Selection{T}(n::AbstractString) where T = begin
        if startswith(n, '@')
            return new{T}(true, Regex(n[2:end]), occursin)
        end
        new{T}(true, n, isequal)
    end
end

state_type(::Type{Selection{T}}) where {T} = Stateless

name(io::IO, s::Selection{T}, prefix="", suffix="") where T = begin
    print(io, prefix)
    print(io, "Selection{$(nameof(T))}($(s.pattern))")
    println(io, suffix)
end

#endregion

#region COMPOUND SELECTORS
# =========================================================
mutable struct BinarySelection{L,R} <: AbstractSelection
    isentry::Bool
    op::Function
    left::AbstractSelection
    right::AbstractSelection
    BinarySelection(op::Function, l::L, r::R) where {L,R} = begin
        clear(l, r)
        new{state_type(L),state_type(R)}(true, op, l, r)
    end
end

state_type(::Type{BinarySelection{L,R}}) where {L,R} = state_rule(L,R)

name(io::IO, s::BinarySelection{L,R}, prefix="",suffix="") where {L,R} = begin
    print(io, prefix)
    println(io, "BinarySelection{$(nameof(L)),$(nameof(R))}($(s.op),")
    name(io, s.left,  prefix*"  ", ",")
    name(io, s.right, prefix*"  ")
    println(io, prefix, ")", suffix)
end

# =========================================================
mutable struct UnarySelection{T} <: AbstractSelection
    isentry::Bool
    op::Function
    sele::AbstractSelection
    element_wise::Bool
    UnarySelection(op::Function, sele::T; element_wise::Bool) where T = begin
        clear(sele)
        new{state_type(T)}(true, op, sele, element_wise)
    end
end

state_type(::Type{UnarySelection{T}}) where {T} = T

name(io::IO, s::UnarySelection{T}, prefix="",suffix="") where T = begin
    print(io, prefix)
    println(io, "UnarySelection{$(nameof(T))}($(s.op), element_wise=$(s.element_wise),")
    name(io, s.sele,  prefix*"  ")
    println(io, prefix, ")", suffix)
end

# =========================================================
mutable struct DistanceSelection{T} <: AbstractSelection
    isentry::Bool
    distance::Number
    sele::AbstractSelection
    DistanceSelection(distance::Number, sele::T) where T = begin
        clear(sele)
        new{state_type(T)}(true, distance, sele)
    end
end

state_type(::Type{DistanceSelection{T}}) where T = Statefull

name(io::IO, s::DistanceSelection{T}, prefix="", suffix="") where T = begin
    print(io, prefix)
    println(io, "DistanceSelection{$(nameof(T))}($(s.distance),")
    name(io, s.sele, prefix*"  ")
    println(io, prefix, ")", suffix)
end

#endregion COMPOUND SELECTORS


Base.show(io::IO, s::AbstractSelection) = name(io, s)


macro sym_str(s); Selection{BySymbol}(s); end
macro  sn_str(s); Selection{Segment}(s); end
macro  rn_str(s); Selection{Residue}(s); end
macro  an_str(s); Selection{Atom}(s); end

macro x_str(s)
    println("this macro could return a special selector that checks all fields in a simple pass")
    fields = reverse(split(s, '/'))
    nfields = length(fields)
    s = TrueSelection()
    if nfields > 0
        s = isempty(fields[1]) ? s : s & Selection{Atom}(fields[1])
    end
    if nfields > 1
        s = isempty(fields[2]) ? s : s & Selection{Residue}(fields[2])
    end
    if nfields > 2
        s = isempty(fields[3]) ? s : s & Selection{Segment}(fields[3])
    end
    s
end



@inline _collect(ac::AbstractContainer, s::AbstractSelection, m::BitVector) =
    s.isentry ? select(ac, m) : m

@inline select(ac::AbstractContainer, mask::BitVector) =
    collect(at for (m,at) in zip(mask,eachatom(ac)) if m)

select(ac::AbstractContainer, s::TrueSelection) = _collect(ac, s, trues(count_atoms(ac)))
select(ac::AbstractContainer, s::Selection{BySymbol}) = _select(ac, s, :symbol)
select(ac::AbstractContainer, s::Selection{Residue}) = _select(ac, s, :container, :name)
select(ac::AbstractContainer, s::Selection{Atom}) = _select(ac, s, :name)
select(top::Topology, s::Selection{Segment}) = _select(top, s, :container, :container, :name)



#getf(ac, fields::Symbol...) = isempty(fields) ? ac : getf(getproperty(ac, fields[1]), fields[2:end]...)
getf(ac, fields::Symbol...) = begin
    for field in fields;
        ac = getproperty(ac, field)
    end
    ac
end


_select(ac::AbstractContainer, s::Selection, fields::Symbol...) = begin
    println("evaluating static")
    mask = falses(count_atoms(ac))
    for (i,atom) in enumerate(eachatom(ac))
        mask[i] = s.match(s.pattern, getf(atom, fields...))
    end
    _collect(ac, s, mask)
end



Base.:&(l::AbstractSelection, r::AbstractSelection) = BinarySelection(&, l, r)
Base.:&(l::AbstractSelection, r::TrueSelection) = l
Base.:&(l::TrueSelection, r::AbstractSelection) = r
Base.:&(l::TrueSelection, r::TrueSelection) = l

Base.:|(l::AbstractSelection, r::AbstractSelection) = BinarySelection(|, l, r)
Base.:|(l::AbstractSelection, r::TrueSelection) = r
Base.:|(l::TrueSelection, r::AbstractSelection) = l
Base.:|(l::TrueSelection, r::TrueSelection) = l

# Base.:(:)(l::Number, r::AbstractSelection) = DistanceSelection(l, r)
# Base.:(:)(l::AbstractSelection, r::Number) = DistanceSelection(r, l)
Base.:(:)(s::AbstractSelection, w::Number, of::AbstractSelection) = BinarySelection(&, s, DistanceSelection(w, of))

Base.:!(l::AbstractSelection) = UnarySelection(!, l; element_wise=true)
Base.any(l::AbstractSelection) = UnarySelection(any, l; element_wise=false)
Base.all(l::AbstractSelection) = UnarySelection(all, l; element_wise=false)


# select(ac::AbstractContainer, s::BinarySelection) = begin
#     lmask = select(ac, s.left)
#     rmask = select(ac, s.right)
#     mask = (s.op).(lmask, rmask)
#     _collect(ac, s, mask)
# end

# # select(ac::AbstractContainer, s::NegateSelection) = begin
# #     mask = .!select(ac, s.sele)
# #     _collect(ac, s, mask)
# # end


# # Base.:&(l::AbstractStatefullSelection, r::AbstractSelection) =
# #    StatefullBinarySelection(&, l, r)
# # Base.:&(l::AbstractSelection, r::AbstractStatefullSelection) =
# #     StatefullBinarySelection(&, l, r)

# # select(ac::AbstractContainer, s::DistanceSelection) = begin
# #     mask = select(ac, s.sele)
# #     return function (state::State)
# #         println(mask)
# #         println(state.id)
# #         println("selecting atom within $(s.distance) of $(s.sele)")
# #         _collect(ac,s,mask)
# #     end
# # end



# -------------------------

select(ac::AbstractContainer, s::UnarySelection{Stateless}) = begin
    mask = select(ac, s.sele)
    if s.element_wise
        mask = (s.op).(mask)
    else
        mask .= s.op(mask)
    end
    _collect(ac, s, mask)
end

# -------------------------
select(ac::AbstractContainer, s::DistanceSelection{Stateless}) = begin
    mask = select(ac, s.sele)
    return function (state::State)
        println("processing state\n$s")
        # <calc distances> & mask
        _collect(ac, s, mask)
    end
end

select(ac::AbstractContainer, s::DistanceSelection{Statefull})::Function = begin
    selector = select(ac, s.sele)
    println("evaluating dynamic\n$s")
    return function (state::State)
        mask = selector(state)
        println("processing state $s")
        # <calc distances> & mask
        _collect(ac, s, mask)
    end
end

# -------------------------

select(ac::AbstractContainer, s::BinarySelection{Stateless,Stateless}) = begin
    lmask = select(ac, s.left)
    rmask = select(ac, s.right)
    _collect(ac, s, (s.op).(lmask, rmask))
end

select(ac::AbstractContainer, s::BinarySelection{Stateless,Statefull}) = _select(ac, s, s.left, s.right)
select(ac::AbstractContainer, s::BinarySelection{Statefull, Stateless}) = _select(ac, s, s.right, s.left)

_select(ac::AbstractContainer, s::BinarySelection, sless::AbstractSelection, sfull::AbstractSelection) = begin
    lmask = select(ac, sless)
    rselector = select(ac, sfull)
    return function (state::State)
        rmask = rselector(state)
        _collect(ac, s, (s.op).(lmask, rmask))
    end
end

select(ac::AbstractContainer, s::BinarySelection{Statefull,Statefull}) = begin
    lselector = select(ac, s.left)
    rselector = select(ac, s.right)
    return function (state::State)
        lmask = lselector(state)
        rmask = rselector(state)
        _collect(ac, s, (s.op).(lmask, rmask))
    end
end