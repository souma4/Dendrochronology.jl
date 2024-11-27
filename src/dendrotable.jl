# -------------------------------------------------------------------
# Licensed under the GPL-3.0 License. See LIENSE in the project root.
# -------------------------------------------------------------------


"""
    DendroTable(years, values)

`years` together with a dictionary of dendroable `values`.
## Examples

```julia
# attach ring-width and length to years
DendroTable(Years,
  Dict(2 => (width=rand(100), length=rand(100)))
)
```
"""
struct DendroTable{Y::Union{UnitRange, AbstractVector{Int}},T} <: AbstractDendroTable
  Years::Y
  values::Dict{Int,T}
end

# getters
getyears(gtb::DendroTable) = getfield(gtb, :Years)
getvalues(gtb::DendroTable) = getfield(gtb, :values)

# ----------------------------
# ABSTRACT GEOTABLE INTERFACE
# ----------------------------

years(dendrotable::DendroTable) = getyears(dendrotable)

function Base.values(dendrotable::DendroTable, rank=nothing)
  years = getyears(dendrotable)
  values = getvalues(dendrotable)
  r = isnothing(rank) ? paramdim(years) : rank
  get(values, r, nothing)
end

