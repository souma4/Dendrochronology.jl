# using Unitful

function readloop(series_index::Vector{Int}, decade::Vector{Int}, x::Matrix{I}) where {I<:Integer}
  if !(eltype(series_index) <: Integer && eltype(decade) <: Integer && eltype(x) <: Integer)
    error("all arguments must be integers or missing values")
  end
  T = eltype(x)

  x_nrow, x_ncol = size(x)
  if x_ncol > 100
    error("too many columns in 'x'")
  end

  if !(length(series_index) == x_nrow && length(decade) == x_nrow)
    error("dimensions of 'x', 'series_index' and 'decade' must match")
  end

  nseries = 0
  min_year = INT_MAX
  max_year = INT_MIN

  for i in 1:x_nrow
    if series_index[i] < 1
      error("'series_index' must be positive")
    end
    nseries = max(nseries, series_index[i])
    this_decade = decade[i]
    j = x_ncol - 1
    x_idx = (i) + j * x_nrow
    while j >= 0 && isNA_INT(x[x_idx])
      j -= 1
      x_idx -= x_nrow
    end
    if j >= 0
      min_year = min(min_year, this_decade)
      max_year = max(max_year, this_decade + j)
    end
  end

  if max_year >= min_year
    if max_year >= 0 && min_year < max_year + NA_INT + 1
      error("Number of years exceeds integer range")
    end
    span = max_year - min_year + 1
  else
    min_year = NA_INT
    span = 0
  end

  rw_nrow = span
  rw_ncol = nseries

  rw_mat = fill(T(NA_INT), rw_nrow, rw_ncol)
  # rw_vec = fill(T(NA_INT), rw_nrow * rw_ncol)
  prec_rproc = fill(T(NA_INT), nseries)

  if span == 0
    @warn "no data found in 'x'"
    return (rw_mat, min_year, prec_rproc)
  end

  last_yr = fill(min_year, rw_ncol)

  for i in 1:x_nrow
    this_decade = decade[i]
    yr_idx = this_decade - min_year
    this_series = series_index[i] - 1
    rw_idx = this_series * rw_nrow + yr_idx
    x_idx = i
    last_valid = last_yr[this_series+1]
    for j in 0:(x_ncol-1)
      this_val = x[x_idx]
      x_idx += x_nrow
      if !isNA_INT(this_val)
        rw_mat[rw_idx+1] = this_val
        last_valid = this_decade + j
      end
      rw_idx += 1
    end
    if last_valid > last_yr[this_series+1]
      last_yr[this_series+1] = last_valid
    end
  end

  for i in 1:rw_ncol

    stop_marker = rw_mat[(i-1)*rw_nrow+(last_yr[i]-min_year)+1]
    if stop_marker == T(999)
      prec_rproc[i] = T(100)
    elseif stop_marker == T(-9999)
      prec_rproc[i] = T(1000)
    else
      prec_rproc[i] = T(1)
    end
  end

  return (rw_mat, min_year, prec_rproc)
end
