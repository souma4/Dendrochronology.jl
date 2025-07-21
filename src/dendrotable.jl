# -------------------------------------------------------------------
# Licensed under the GPL-3.0 License. See LICENSE in the project root.
# -------------------------------------------------------------------


@stable Base.names(rwltable::TimeArray) = colnames(rwltable)

"""
    years(rwltable::TimeArray)
function to get all years in the TimeArray
"""
@stable years(rwltable::TimeArray) = year.(timestamp(rwltable))

# Equality
Tables.DataAPI.nrow(rwltable::TimeArray) = length(years(rwltable))
Tables.DataAPI.ncol(rwltable::TimeArray) = length(names(rwltable))

# IO Methods
@stable function dendrostats(rwltable::TimeArray; small_thresh=nothing, big_thresh=nothing)

  # main summary
  statistics = _summary(rwltable)
  num_series = Tables.DataAPI.ncol(rwltable)
  n = sum(statistics[:last] .- statistics[:first])
  μₛ = mean(statistics[:year])
  first = minimum(statistics[:first])
  last = maximum(statistics[:last])
  μₐ = mean(statistics[:ar1])
  stdₐ = std(statistics[:ar1])

  # unconnected spands
  naRowSum = map(row -> sum(row -> row == 0, row), eachrow(values(rwltable)))
  unconnectedFlag = naRowSum .== num_series
  unconnected = any(unconnectedFlag)
  unconnectedYrs = years(rwltable)[findall(unconnectedFlag)]

  # missing rings
  zedsLogical = isnan.(values(rwltable))
  nZeros = count(==(true), zedsLogical)
  zeds = [findall(==(true), zedsLogical[:, i]) for i in 1:size(zedsLogical, 2)]
  zeds = [years(rwltable)[z] for z in zeds if !isempty(z)]
  zeros = isempty(zeds) ? Int[] : zeds

  samps = sum(.!isnan.(values(rwltable)), dims=2)
  pctSeriesZero = sum(zedsLogical, dims=2) ./ samps
  allZeroYears = findall(==(1), pctSeriesZero)

  function consecutiveZerosVec(x)
    run_values, run_lengths = collect(rle(isnan.(x)))

    consecutive_zeros_indices = findall(x -> x[1] && x[2] >= 1, collect(zip(run_values, run_lengths)))
    # remove the leading trues
    if run_values[1]
      popfirst!(consecutive_zeros_indices)
    end
    # remove trailing true
    if run_values[end]
      pop!(consecutive_zeros_indices)
    end

    consecutive_zeros_logical = falses(length(x))
    for i in consecutive_zeros_indices
      consecutive_zeros_logical[(sum(run_lengths[1:(i-1)])+1):(sum(run_lengths[1:i]))] .= true
    end
    consecutive_zeros_logical
  end

  consecutiveZerosLogical = [consecutiveZerosVec(values(rwltable)[:, i]) for i in 1:size(values(rwltable), 2)]


  # get years from indices
  consecutiveZerosLogicalList = [findall(x -> x, consecutiveZerosLogical[i]) for i in 1:length(consecutiveZerosLogical)]
  # get years from names instead of indices
  consecutiveZerosLogicalList = [years(rwltable)[x] for x in consecutiveZerosLogicalList]

  statistics[:consecutiveZeros] = consecutiveZerosLogicalList


  ρ, _ = _corinterseries(rwltable)
  meanInterSeriesCor = mean(ρ[.!isnan.(ρ)])
  sdInterSeriesCor = std(ρ[.!isnan.(ρ)])

  internalNAs = [findall(val -> isnan(val), values(rwltable)[:, i]) for i in 1:size(values(rwltable), 2)]
  internalNAs = [years(rwltable)[na] for na in internalNAs if !isempty(na)]
  internalNAs = isempty(internalNAs) ? Int[] : internalNAs

  smallRings = if isnothing(small_thresh)
    Int[]
  else
    smallRings = [findall(x -> x > 0 && x < small_thresh, values(rwltable)[:, i]) for i in 1:size(values(rwltable), 2)]
    smallRings = [years(rwltable)[sr] for sr in smallRings if !isempty(sr)]
    isempty(smallRings) ? Int[] : smallRings
  end

  bigRings = if isnothing(big_thresh)
    Int[]
  else
    bigRings = [findall(x -> x > big_thresh, values(rwltable)[:, i]) for i in 1:size(values(rwltable), 2)]
    bigRings = [years(rwltable)[br] for br in bigRings if !isempty(br)]
    isempty(bigRings) ? Int[] : bigRings
  end

  println("## Number of dated series: $num_series")
  println("## Number of measurements: $n")
  println("## Avg series length: $μₛ")
  println("## Range: $(last - first + 1)")
  println("## Span: $(first) - $(last)")
  println("## Mean (Std dev) series intercorrelation: $(round(meanInterSeriesCor, digits=3)) ($(round(sdInterSeriesCor, digits=3)))")
  println("## Mean (Std dev) AR1: $(round(μₐ, digits=3)) ($(round(stdₐ, digits=3)))")
  println("## -------------")
  println("## Years where all rings are missing (NA)")
  if isempty(allZeroYears)
    println("##     None")
  else
    println("## Warning: Having years with all zeros is atypical (but not unheard of).")
    println("$(join([idx[1] for idx in allZeroYears] .+ first, "\n"))")
  end
  println("## -------------")
  println("## Years with consecutive absent rings listed by series")
  if isempty(statistics[:consecutiveZeros])
    println("##     None")
  else
    for (i, series) in enumerate(names(rwltable))
      tmp = statistics[:consecutiveZeros][i]
      if isempty(tmp)
        continue
      end
      println("##     Series $series -- $(join(tmp, " "))")
    end
    # percent absent rings
    sumAbsent = sum(length, consecutiveZerosLogicalList)
    pctAbsent = round(sumAbsent / n * 100, digits=2)

    println("## $sumAbsent absent rings ($pctAbsent%)")

  end


  println("## -------------")
  if !isnothing(small_thresh)
    println("## -------------")
    println("## Years with values < $small_thresh listed by series")
    if isempty(smallRings)
      println("##     None")
    else
      for (i, series) in enumerate(names(rwltable))
        tmp = smallRings[i]
        if isempty(tmp)
          continue
        end
        println("##     Series $series -- $(join(tmp, " "))")
      end
    end
  end

  if !isnothing(big_thresh)
    println("## -------------")
    println("## Years with values > $big_thresh listed by series")
    if isempty(bigRings)
      println("##     None")
    else
      for (i, series) in enumerate(names(rwltable))
        tmp = bigRings[i]
        if isempty(tmp)
          continue
        end
        println("##     Series $series -- $(join(tmp, " "))")
      end
    end
  end
end

@stable function Base.first(rwltable::TimeArray, n::Int)
  view(rwltable, 1:n)
end

@stable function Base.last(rwltable::TimeArray, n::Int)
  view(rwltable, (length(rwltable)-n+1):length)
end


### HELPERS ###
# using StatsBase

function _summary(rwltable)
  acf1(x) = autocor(x, [1])[1]
  yr = years(rwltable)
  rwl₂ = values(rwltable)
  yrᵣ = [_yearrange(rwltable, colname) for colname in Tables.columnnames(rwltable)[2:end]]
  first = [r[1] for r in yrᵣ]
  last = [r[2] for r in yrᵣ]
  rangeᵣ = last .- first .+ 1
  μ = round.(mean(!isnan, rwl₂, dims=1), digits=3)
  η = round.([median(rwl₂[.!isnan.(rwl₂[:, i]), i]) for i in 1:size(rwl₂, 2)], digits=3)
  σ = round.([std(rwl₂[.!isnan.(rwl₂[:, i]), i]) for i in 1:size(rwl₂, 2)], digits=3)
  skewₛ = round.([skewness(rwl₂[.!isnan.(rwl₂[:, i]), i]) for i in 1:size(rwl₂, 2)], digits=3)
  kurtosisₛ = round.([kurtosis(rwl₂[.!isnan.(rwl₂[:, i]), i]) for i in 1:size(rwl₂, 2)], digits=3)
  gini = round.([_gini(rwl₂[.!isnan.(rwl₂[:, i]), i]) for i in 1:size(rwl₂, 2)], digits=3)
  ar1 = round.([acf1(rwl₂[.!isnan.(rwl₂[:, i]), i]) for i in 1:size(rwl₂, 2)], digits=3)
  Dict(
    :first => first,
    :last => last,
    :year => rangeᵣ,
    :mean => μ,
    :median => η,
    :std => σ,
    :skewness => skewₛ,
    :kurtosis => kurtosisₛ,
    :gini => gini,
    :ar1 => ar1
  )


end

function _gini(x)
  n = length(x)
  sum = 0
  for i in 1:n
    for j in 1:n
      sum += abs(x[i] - x[j])
    end
  end
  return sum / (2 * n^2 * mean(x))
end

function _yearrange(rwltable, series)
  allyears = years(rwltable)
  data = values(rwltable[:, series]) |> vec
  valid_years = allyears[.!isnan.(data)]
  return extrema(valid_years)
end
