# -------------------------------------------------------------------
# Licensed under the GPL-3.0 License. See LIENSE in the project root.
# -------------------------------------------------------------------

"""
    AbstractRWLTable

    Implements the [`Year`](@ref) trait together with tables
    of values for years.
        """
abstract type AbstractRWLTable end

"""
years(rwltable)

return underlying years of the `rwltable`.
"""
function years end

"""
values(rwltable)
returns the values of the rwltable
"""
values

# ---------
# FALLBACKS
# ---------

function Base.:(==)(rwltable₁::AbstractRWLTable, dentable₂::AbstractRWLTable)
  #same years
  if years(rwltable₁) != years(rwltable₂)
    return false
  end

  # same values
  for rank in 0:paramdim(years(rwltable₁))
    vals₁ = values(rwltable₁, rank)
    vals₂ = values(rwltable₂, rank)
    if !isequal(vals₁, vals₂)
      return false
    end
  end

  true
end


Base.view(rwltable::AbstractRWLTable, inds::AbstractVector{Int}) = SubRWLTable(rwltable, inds)

Base.parent(rwltable::AbstractRWLTable) = rwltable

Base.parentindices(rwltable::AbstractRWLTable) = 1:nrow(rwltable)

# -----------
# IO METHODS
# -----------

function Base.summary(io::IO, rwltable::AbstractRWLTable)
  yr = yrs(rwltable)
  name = nameof(typeof(rwltable))
  print(io, "$(nrow(rwltable))×$(ncol(rwltable)) $name over $yr")
end


function Base.show(io::IO, ::MIME"text/plain", rwltable::AbstractRWLTable)
  fcolor = crayon"bold teal"
  gcolor = crayon"bold (0,128,128)"
  hcolors = [fill(fcolor, ncol(rwltable) - 1); gcolor]
  pretty_table(
    io,
    rwltable;
    backend=Val(:text),
    _common_kwargs(rwltable)...,
    header_crayon=hcolors,
    newline_at_end=false
  )
end

function Base.show(io::IO, ::MIME"text/html", rwltable::AbstractRWLTable)
  pretty_table(io, rwltable; backend=Val(:html), _common_kwargs(rwltable)..., max_num_of_rows=10)
end

function _common_kwargs(rwltable)
  yr = years(rwltable)
  tab = values(rwltable)
  names = propertynames(rwltable)

  # header
  header = string.(names)

  # subheaders
  tuples = map(names) do name

    cols = Tables.columns(tab)
    x = Tables.getcolumn(cols, name)
    T = eltype(x)
    if T <: Missing
      header₁ = "Missing"
      header₂ = "[NoUnits]"
    else
      S = nonmissingtype(T)
      header₁ = string(nameof(scitype(S)))
      header₂ = S <: AbstractQuantity ? "[$(unit(S))]" : "[NoUnits]"
    end
    header₁, header₂
  end
  subheader₁ = first.(tuples)
  subheader₂ = last.(tuples)

  (title=summary(rwltable), header=(header, subheader₁, subheader₂), alignment=:c, vcrop_mode=:bottom)
end
