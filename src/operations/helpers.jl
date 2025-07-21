# -------------------------------------------------------------------
# Licensed under the GPL-3.0 License. See LICENSE in the project root.
# -------------------------------------------------------------------
function _normaldate(rwl, n; prewhiten=true, biweight=true, leave_one_out=false)
  loo = leave_one_out
  rwl[rwl.==0] .= NaN

  master_df, series_out = _masterseries(rwl, n; loo=loo)

  if loo
    nseries = size(rwl, 2)
    if prewhiten
      goodCol = sum(.!isnan.(master_df), dims=1) .≥ 3
      goodCol = vec(goodCol)
      series_out = hcat(_ar.(eachcol(master_df[:, goodCol]))...)
    else
      goodCol = trues(nseries)
      series_out = copy(master_df)
    end
    master = copy(series_out)
    if !biweight
      for i in 1:nseries
        goodCol2 = copy(goodCol)
        goodCol2[i] = false
        master[:, i] = mean(!isnan, series_out[:, goodCol2], dims=2)
      end
    else
      for i in 1:nseries
        goodCol2 = copy(goodCol)
        goodCol2[i] = false
        master[:, i] = _tbrm(series_out[:, goodCol2], 9, dims=2)
      end
    end
  else
    if prewhiten
      master_df = master_df[:, vec(sum(.!isnan.(master_df), dims=1) .> 3)]
      master_df = hcat(_ar(eachcol(master_df))...)
      series_out = hcat(_ar(eachcol(series_out))...)
    end
    master = biweight ? _tbrm(master_df, 9, dims=1) : mean(!isnan, master_df, dims=1)
  end
  Dict("master" => master, "series" => series_out)
end

# ----------------
# normalization functions
# ----------------
function _masterseries(rwl, n::Nothing; loo=false)
  μᵢ = inv.(StatsBase.mean(!isnan, rwl, dims=1))
  μ = inv(StatsBase.mean(!isnan, rwl))
  master_df = rwl .* μᵢ
  series_out = loo ? nothing : rwl * μ
  master_df, series_out
end
function _masterseries(rwl, n::Integer; loo=false)
  hᵢ = inv.(hcat([_hanning(col, n) for col in eachcol(rwl)]...))
  h = inv.(hcat([_hanning(col, n) for col in eachcol(hᵢ)]...))
  master_df = rwl .* hᵢ
  series_out = loo ? nothing : rwl .* h
  master_df, series_out
end
function _hanning(rwl, n=7)
  j = collect(0:(n-1))
  h = @. 1 - cos(2π * j / (n - 1))
  h = h ./ sum(h[.!isnan.(h)])

  @rput rwl
  @rput h
  t = R"as.vector(filter($rwl, $h))"
  @rget t
end

function _tbrm(x::AbstractVector, c)
  x₂ = copy(x)
  valid = x₂[.!isnan.(x₂)]
  if isempty(valid)
    return NaN
  end

  m = StatsBase.median(valid)
  mad = StatsBase.median(abs.(valid .- m))
  div = mad * c + eps(eltype(x))

  weights, weightsₜ = _compute_weights(x₂, m, div)
  _compute_trimmed_mean(weights, weightsₜ)
end

function _tbrm(x::AbstractMatrix, c; dims=1)
  if dims > length(size(x))
    error("Dimension exceeds matrix dimensions.")
  end
  mapslices(x -> _tbrm(x, c), x; dims=dims)
end

function _compute_weights(x₂, m, div)
  n = length(x₂)
  weights = Vector{eltype(x₂)}(undef, n)
  fill!(weights, NaN)
  weightsₜ = Vector{eltype(x₂)}(undef, n)
  fill!(weightsₜ, NaN)
  count = 1

  for i in 1:n
    this = (x₂[i] - m) / div
    if this >= -1 && this <= 1
      this = 1 - this * this
      this *= this
      weights[count] = this
      weightsₜ[count] = this * x₂[i]
      count += 1
    end
  end

  weights, weightsₜ, count
end

function _compute_trimmed_mean(weights, weightsₜ)
  count = sum(!isnan, weights)
  if count == 1
    weightsₜ[1] / weights[1]
  elseif count > 0
    sum(weightsₜ[1:count]) / sum(weights[1:count])
  else
    NaN
  end
end



# function _cor(method::String)
#   if method == "pearson"
#     :pearson
#   elseif method == "spearman"
#     :spearman
#   elseif method == "kendall"
#     :kendall
#   else
#     error("Method not recognized. Please use 'pearson', 'spearman', or 'kendall'.")
#   end
# end
