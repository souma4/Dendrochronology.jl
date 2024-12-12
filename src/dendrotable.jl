# -------------------------------------------------------------------
# Licensed under the GPL-3.0 License. See LIENSE in the project root.
# -------------------------------------------------------------------


"""
    RWLTable(years, values)

`years` together with a dictionary of RWLTable (ring-width-length) `values`.
## Examples

```julia
# attach ring-width and length to years
RWLTable(Years,
  Dict(2 => (width=rand(100), length=rand(100)))
)
```
"""
struct RWLTable{Y::Union{UnitRange,AbstractVector{Int}},T} <: AbstractRWLTable
  Years::Y
  values::Dict{Int,T}
end

# getters
getyears(gtb::RWLTable) = getfield(gtb, :Years)
getvalues(gtb::RWLTable) = getfield(gtb, :values)

# ----------------------------
# ABSTRACT GEOTABLE INTERFACE
# ----------------------------

years(rwltable::RWLTable) = getyears(rwltable)

function Base.values(rwltable::RWLTable, rank=nothing)
  years = getyears(rwltable)
  values = getvalues(rwltable)
  r = isnothing(rank) ? paramdim(years) : rank
  get(values, r, nothing)
end
