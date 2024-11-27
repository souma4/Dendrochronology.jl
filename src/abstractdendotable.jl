# -------------------------------------------------------------------
# Licensed under the GPL-3.0 License. See LIENSE in the project root.
# -------------------------------------------------------------------

"""
    AbstractDendroTable

    Implements the [`Year`](@ref) trait together with tables
    of values for years.
        """
abstract type AbstractDendroTable end 

"""
years(dendrotable)

return underlying years of the `dendrotable`.
"""
function years end

"""
values(dendrotable)
returns the values of the dendrotable
"""
values

# ---------
# FALLBACKS
# ---------

function Base.:(==)(dendrotable₁::AbstractDendroTable, dentable₂::AbstractDendroTable)
    #same years
    if years(dendrotable₁) != years(dendrotable₂)
        return false
    end

    # same values
    for rank in 0:paramdim(years(dendrotable₁))
        vals₁ = values(dendrotable₁, rank)
        vals₂ = values(dendrotable₂, rank)
        if !isequal(vals₁, vals₂)
            return false
        end
    end

    true
end


Base.view(dendrotable::AbstractDendroTable, inds::AbstractVector{Int}) = SubDendroTable(dendrotable, inds)

Base.parent(dendrotable::AbstractDendroTable) = dendrotable

Base.parentindices(dendrotable::AbstractDendroTable) = 1:nrow(dendrotable)

# -----------
# IO METHODS
# -----------

function Base.summary(io::IO, dendrotable::AbstractDendroTable)
  yr = yrs(dendrotable)
  name = nameof(typeof(dendrotable))
  print(io, "$(nrow(dendrotable))×$(ncol(dendrotable)) $name over $yr")
end


function Base.show(io::IO, ::MIME"text/plain", dendrotable::AbstractDendroTable)
  fcolor = crayon"bold teal"
  gcolor = crayon"bold (0,128,128)"
  hcolors = [fill(fcolor, ncol(dendrotable) - 1); gcolor]
  pretty_table(
    io,
    dendrotable;
    backend=Val(:text),
    _common_kwargs(dendrotable)...,
    header_crayon=hcolors,
    newline_at_end=false
  )
end

function Base.show(io::IO, ::MIME"text/html", dendrotable::AbstractDendroTable)
  pretty_table(io, dendrotable; backend=Val(:html), _common_kwargs(dendrotable)..., max_num_of_rows=10)
end

function _common_kwargs(dendrotable)
    yr = years(dendrotable)
    tab = values(dendrotable)
    names = propertynames(dendrotable)
  
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
  
    (title=summary(dendrotable), header=(header, subheader₁, subheader₂), alignment=:c, vcrop_mode=:bottom)
  end