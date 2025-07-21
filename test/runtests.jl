using TestItems
using TestItemRunner

@run_package_tests

@testsnippet Setup begin
  using CSV
  using Dendrochronology
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



  # environment settings
  isCI = "CI" ∈ keys(ENV)
  islinux = Sys.islinux()
  visualtests = !isCI || (isCI && islinux)
  datadir = joinpath(@__DIR__, "data")

  # float settings
  T = if isCI
    Float64
  end

  # include("testutils.jl")
end
