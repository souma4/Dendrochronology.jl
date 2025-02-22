# -------------------------------------------------------------------
# Licensed under the GPL-3.0 License. See LIENSE in the project root.
# -------------------------------------------------------------------


# """
#     dendroref(table, years)

# Dendroreference `table` on `years`

# "" Examples

# ```julia
# julia> dendroref((w=rand(30),l=rand(30)),1980:2010)
# ```
# """
# dendroref(table, years::AbstractVector{Int}) = RWLTable(table, years)



# dendroref(table, names::AbstractVector{<:AbstractString}; kwargs...) = dendroref(table, Symbol.(names); kwargs...)
# dendroref(table, names::NTuple{N,Symbol}; kwargs...) where {N} = dendroref(table, collect(names); kwargs...)
# dendroref(table, names::NTuple{N,<:AbstractString}; kwargs...) where {N} =
#   dendroref(table, collect(Symbol.(names)); kwargs...)

# # ---------
# # HELPERS
# # ---------

# #add unit or convert to chosen unit
# withunit(x::Number, u) = x * u
# withunit(x::Quantity, u) = uconvert(u, x)

# # variants of given names with uppercase, etc.
# variants(names) = [names; uppercase.(names); uppercasefirst.(names)]
