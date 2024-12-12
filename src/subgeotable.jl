# -------------------------------------------------------------------
# Licensed under the GPL-3.0 License. See LIENSE in the project root.
# -------------------------------------------------------------------


"""
    SubRWLTable(rwltable, inds)

Return a view of `rwltable` at indices `inds`.
"""
struct SubRWLTable{T<:AbstractRWLTable,I<:AbstractVector{Int}} <: AbstractRWLTable
  rwltable::T
  inds::I
end

# getters
getdendrotable(v::SubRWLTable) = getfield(v, :rwltable)
getinds(v::SubRWLTable) = getfield(v, :inds)

# specialize constructor to avoid infinite loops
SubRWLTable(v::SubRWLTable, inds::AbstractVector{Int}) = SubRWLTable(getdendrotable(v), getinds(v)[inds])

# ----------------------------
# ABSTRACT rwltable INTERFACE
# ----------------------------

function years(v::SubRWLTable)
  rwltable = getdendrotable(v)
  inds = getinds(v)
  view(years(rwltable), inds)
end

function Base.values(v::SubRWLTable, rank=nothing)
  rwltable = getdendrotable(v)
  inds = getinds(v)
  dim = paramdim(years(rwltable))
  r = isnothing(rank) ? dim : rank
  table = values(rwltable, r)
  if r == dim && !isnothing(table)
    Tables.subset(table, inds)
  else
    nothing
  end
end

# specialize methods for performance
Base.:(==)(v₁::SubRWLTable, v₂::SubRWLTable) = getdendrotable(v₁) == getdendrotable(v₂) && getinds(v₁) == getinds(v₂)

Base.parent(v::SubRWLTable) = getdendrotable(v)

Base.parentindices(v::SubRWLTable) = getinds(v)
