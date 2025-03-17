# -------------------------------------------------------------------
# Licensed under the GPL-3.0 License. See LICENSE in the project root.
# -------------------------------------------------------------------
module Dendrochronology

using Crayons
using CSV
using Dates
using Printf
using Unitful
using Random
using PrettyTables
using Tables
using TimeSeries
using StatsBase
using IterTools
using DSP: conv
using HypothesisTests: CorrelationTest, pvalue
using LinearAlgebra: dot, cholesky, qr
# Write your package code here.
include("dendrotable.jl")
# include("operations.jl")
include("utils.jl")
include("read.jl")
include("write.jl")

# TimeArray and notable methods
export TimeArray, years, values, names, colnames, timestamp, meta



end
