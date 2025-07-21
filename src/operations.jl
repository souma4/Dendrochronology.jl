# -------------------------------------------------------------------
# Licensed under the GPL-3.0 License. See LICENSE in the project root.
# -------------------------------------------------------------------
#using StatsBase
#using HypothesisTests

include("operations/helpers.jl")
include("operations/autoregression.jl")

function _corinterseries(x::TimeArray;
  n=nothing, prewhiten=true, biweight=true,
  method="pearson")

  # symbol = _cor(method)
  symbol = "pearson"
  nseries = size(x, 2)
  tmp = _normaldate(values(x), n; prewhiten=prewhiten, biweight=biweight, leave_one_out=true)
  series = tmp["series"]
  master = tmp["master"]
  rescor = Vector{Float64}(undef, nseries)
  pval = Vector{Float64}(undef, nseries)

  for i in 1:nseries
    valid_indices = .!(isnan.(series[:, i]) .| isnan.(master[:, i]))
    if sum(valid_indices) < 3
      rescor[i] = NaN
      pval[i] = NaN
      continue
    end
    ρ = CorrelationTest(series[valid_indices, i], master[valid_indices, i])
    rescor[i] = ρ.r
    pval[i] = pvalue(ρ, tail=:right)
  end

  rescor, pval
end
