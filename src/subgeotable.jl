# -------------------------------------------------------------------
# Licensed under the GPL-3.0 License. See LIENSE in the project root.
# -------------------------------------------------------------------


"""
    SubDendroTable(dendrotable, inds)

Return a view of `dendrotable` at indices `inds`.
"""
struct SubDendroTable{T<:AbstractDendroTable,I<:AbstractVector{Int}} <: AbstractDendroTable
  dendrotable::T
  inds::I
end

# getters
getdendrotable(v::SubDendroTable) = getfield(v, :dendrotable)
getinds(v::SubDendroTable) = getfield(v, :inds)

# specialize constructor to avoid infinite loops
SubDendroTable(v::SubDendroTable, inds::AbstractVector{Int}) = SubDendroTable(getdendrotable(v), getinds(v)[inds])

# ----------------------------
# ABSTRACT dendroTABLE INTERFACE
# ----------------------------

function years(v::SubDendroTable)
  dendrotable = getdendrotable(v)
  inds = getinds(v)
  view(years(dendrotable), inds)
end

function Base.values(v::SubDendroTable, rank=nothing)
  dendrotable = getdendrotable(v)
  inds = getinds(v)
  dim = paramdim(years(dendrotable))
  r = isnothing(rank) ? dim : rank
  table = values(dendrotable, r)
  if r == dim && !isnothing(table)
    Tables.subset(table, inds)
  else
    nothing
  end
end

# specialize methods for performance
Base.:(==)(v₁::SubDendroTable, v₂::SubDendroTable) = getdendrotable(v₁) == getdendrotable(v₂) && getinds(v₁) == getinds(v₂)

Base.parent(v::SubDendroTable) = getdendrotable(v)

Base.parentindices(v::SubDendroTable) = getinds(v)