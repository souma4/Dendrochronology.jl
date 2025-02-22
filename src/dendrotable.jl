# -------------------------------------------------------------------
# Licensed under the GPL-3.0 License. See LICENSE in the project root.
# -------------------------------------------------------------------
# using Crayons
# using Tables
# using PrettyTables
# using Unitful

"""
    RWLTable

    A custom table type for holding RWL data.
    # Fields:
    # - `years::Vector{Int}`: A vector of years corresponding to the rows of the data matrix.
    # - `data::T`: A matrix or vector holding the RWL data.
    # - `colnames::Vector{Symbol}`: A vector of symbols representing the names of the columns.
    # - `lookup::Dict{Symbol,Int}`: A dictionary mapping column names to their respective indices.
"""
struct RWLTable{T<:AbstractVecOrMat} <: Tables.AbstractColumns
  years::Vector{Int}
  data::T
  colnames::Vector{Symbol}
  lookup::Dict{Symbol,Int}

  function RWLTable(matrix::T, years::Vector{Int}, colnames::Vector{Symbol}) where {T}
    if size(matrix, 1) != length(years)
      error("Number of rows in matrix must match length of years vector")
    end
    if size(matrix, 2) != length(colnames)
      error("Number of columns in matrix must match length of colnames vector")
    end
    new{T}(years, matrix, colnames, Dict(colnames .=> 1:length(colnames)))
  end
end

# ----------------------------
# RWLTable INTERFACE
# ----------------------------
# Implementing the Tables.jl interface
Tables.istable(::Type{<:RWLTable}) = true
# Getters
getyears(rwltable::RWLTable) = getfield(rwltable, :years)
getvalues(rwltable::RWLTable) = getfield(rwltable, :data)
Base.names(rwltable::RWLTable) = getfield(rwltable, :colnames)
lookup(rwltable::RWLTable) = getfield(rwltable, :lookup)

years(rwltable::RWLTable) = getyears(rwltable)
Base.values(rwltable::RWLTable) = getvalues(rwltable)

Tables.schema(rwltable::RWLTable{T}) where {T} = Tables.Schema(names(rwltable), fill(eltype(T), length(names(rwltable))))

Tables.columnaccess(::Type{<:RWLTable}) = true
Tables.columns(rwltable::RWLTable) = rwltable

Tables.getcolumn(rwltable::RWLTable, ::Type{T}, col::Int, name::Symbol) where {T} = name == :Year ? years(rwltable) : getvalues(rwltable)[:, col]
Tables.getcolumn(rwltable::RWLTable, name::Symbol) = name == :Year ? years(rwltable) : getvalues(rwltable)[:, lookup(rwltable)[name]]
Tables.getcolumn(rwltable::RWLTable, i::Int) = i == 1 ? years(rwltable) : getvalues(rwltable)[:, i-1]
Tables.columnnames(rwltable::RWLTable) = [:Year; names(rwltable)]



Tables.rowaccess(::Type{<:RWLTable}) = true
rows(rwltable::RWLTable) = rwltable
Base.eltype(::Type{RWLTable{T}}) where {T} = RWLRow{T}
Base.length(rwltable::RWLTable) = length(years(rwltable))
Base.iterate(rwltable::RWLTable, state=(1, 1)) = state[1] > length(rwltable) ? nothing : ((Tables.getcolumn(rwltable, state[2])[state[1]], (state[1] + 1, state[2])))
# Iterating over columns
Base.eachcol(rwltable::RWLTable) = (Tables.getcolumn(rwltable, name) for name in Tables.columnnames(rwltable))

# Iterating over rows
Base.eachrow(rwltable::RWLTable) = (RWLRow(i, rwltable) for i in 1:Base.length(rwltable))

# Abstract Row
struct RWLRow{T} <: Tables.AbstractRow
  row::Int
  source::RWLTable{T}
end

Tables.getcolumn(rwltable::RWLRow, ::Type, col::Int, name::Symbol) = getfield(getfield(rwltable, :source), :data)[getfield(rwltable, :row), col]
@inline function Tables.getcolumn(rwltable::RWLRow, name::Symbol)
  if name == :Year
    getfield(getfield(rwltable, :source), :years)[getfield(rwltable, :row)]
  else
    getfield(getfield(rwltable, :source), :data)[getfield(rwltable, :row), getfield(getfield(rwltable, :source), :lookup)[name]]
  end
end
Tables.getcolumn(rwltable::RWLRow, i::Int) = getfield(getfield(rwltable, :source), :data)[getfield(rwltable, :row), i]
Tables.columnnames(rwltable::RWLRow) = names(getfield(rwltable, :source))


# Equality
function Base.:(==)(rwltable₁::RWLTable, rwltable₂::RWLTable)
  # Same years
  if years(rwltable₁) != years(rwltable₂)
    return false
  end

  # Same values
  vals₁ = values(rwltable₁)
  vals₂ = values(rwltable₂)
  if !isequal(vals₁, vals₂)
    return false
  end


  true
end

Base.view(rwltable::RWLTable, inds::AbstractVector{Int}) = SubRWLTable(rwltable, inds)

Base.parent(rwltable::RWLTable) = rwltable

Tables.DataAPI.nrow(rwltable::RWLTable) = length(years(rwltable))
Tables.DataAPI.ncol(rwltable::RWLTable) = length(names(rwltable))

Tables.subset(rwltable::RWLTable, inds::AbstractVector{Int}) = SubRWLTable(rwltable, inds)

# IO Methods
function Base.summary(io::IO, rwltable::RWLTable)
  yr = extrema(years(rwltable))
  name = nameof(typeof(rwltable))
  print(io, "$(Tables.DataAPI.ncol((rwltable))) series $name over years: $yr")
end

function Base.show(io::IO, ::MIME"text/plain", rwltable::RWLTable)
  fcolor = crayon"bold light_cyan"
  gcolor = crayon"bold light_magenta"
  hcolors = [gcolor; fill(fcolor, length(names(rwltable)))]
  pretty_table(
    io,
    # hcat(years(rwltable), reduce(hcat, values(rwltable)));
    rwltable;
    backend=Val(:text),
    _common_kwargs(rwltable)...,
    header_crayon=hcolors,
    newline_at_end=false
  )
end

function Base.show(io::IO, ::MIME"text/html", rwltable::RWLTable)
  pretty_table(io, Tables.columns(rwltable); backend=Val(:html), max_num_of_rows=10)
end


function _common_kwargs(rwltable::RWLTable)
  years = getyears(rwltable)
  values = getvalues(rwltable)
  colnames = names(rwltable)

  # header
  header = [:Year, colnames...]
  tuples = map(header) do name
    if name == :Year
      header₁ = name
      header₂ = "[Year]"
    else
      x = Tables.getcolumn(rwltable, name)
      T = eltype(x)
      if T <: Missing
        header₁ = "Missing"
        header₂ = "[NoUnits]"
      else
        S = nonmissingtype(T)
        header₁ = string(name)
        header₂ = S <: Unitful.AbstractQuantity ? "[$(unit(S))]" : "[NoUnits]"
      end
    end
    header₁, header₂
  end
  subheader₁ = first.(tuples)
  subheader₂ = last.(tuples)

  (title=summary(rwltable),
    header=(subheader₁, subheader₂),
    alignment=:c,
    vcrop_mode=:middle,
    # max_num_of_columns=5,
    display_size=(15, 80),
    crop=:both
  )


end
