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
    if ENV["FLOAT_TYPE"] == "Float32"
      Float32
    elseif ENV["FLOAT_TYPE"] == "Float64"
      Float64
    end
  else
    Float64
  end

  # include("testutils.jl")
end
