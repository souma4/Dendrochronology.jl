using TestItems
using TestItemRunner

@run_package_tests

@testsnippet Setup begin
  using Crayons
  using CSV
  using Dates
  using Printf
  using Unitful
  using Random
  using PrettyTables
  using Tables
  using Dendrochronology

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
