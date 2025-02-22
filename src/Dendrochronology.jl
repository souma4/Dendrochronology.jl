module Dendrochronology

using Crayons
using CSV
using Dates
using Printf
using Unitful
using Random
using PrettyTables
using Tables
# Write your package code here.
include("abstractdendotable.jl")
include("dendrotable.jl")
include("dendroref.jl")
include("subdendrotable.jl")
include("utils.jl")
include("read.jl")
include("write.jl")

# RWLTable and notable methods
export RWLTable, ncol, nrow, years, values, names, colnames




end
