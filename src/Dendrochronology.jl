# -------------------------------------------------------------------
# Licensed under the GPL-3.0 License. See LICENSE in the project root.
# -------------------------------------------------------------------
module Dendrochronology

using CSV
using DispatchDoctor
using DSP: conv
using Dates
using HypothesisTests: CorrelationTest, pvalue
using LinearAlgebra: dot, cholesky, qr
using MultivariateStats
using Printf
using RCall
using Random
using Tables
using StatsBase
using StatsModels
using TimeSeries
using Unitful

@stable default_mode = "disable" begin
  include("utils.jl")
  include("operations.jl")
  include("dendrotable.jl")
  include("read.jl")
  include("write.jl")
end

# TimeArray and notable methods
export TimeArray, years, values, names, colnames, timestamp, meta,
  dendrostats




end
