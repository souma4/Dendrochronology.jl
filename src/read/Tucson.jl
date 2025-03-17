# -------------------------------------------------------------------
# Licensed under the GPL-3.0 License. See LIENSE in the project root.
# -------------------------------------------------------------------

"""
  read(fname::Tucson; header::Union{Nothing,Bool}=nothing, long::Bool=false, edge_zeros::Bool=true, verbose::Bool=true)

Reads a file in the Tucson format.

# Arguments
- `ftype::Tucson`: The file type to be read.
- `fname::String`: The file name or path to the Tucson file to be read.
- `header::Union{Nothing,Bool}`: If `true`, reads the header information from the file. If `false`, skips the header. If `nothing`, the function decides based on the file content. Default is `nothing`.
- `long::Bool`: If `true`, reads the data in long format. Default is `false`.
- `edge_zeros::Bool`: If `true`, includes zeros at the edges of the data. Default is `true`.
- `verbose::Bool`: If `true`, prints additional information during the reading process. Default is `true`.

# Returns
- The data read from the Tucson file, formatted according to the specified options.

# Example
read(Tucson("path/to/file.rwl"); kwargs...)
"""
function Base.read(ftype::Tucson, fname::String; header::Union{Nothing,Bool}=nothing, long::Bool=false,
  edge_zeros::Bool=true, verbose::Bool=true)
  function input_ok(series, decade_yr, x)
    if length(series) == 0
      return false
    end

    n_per_row = [sum(.!isNA_INT.(i)) for i in eachrow(x)]
    full_per_row = 10 .- mod.(decade_yr, 10)
    idx_bad = findall(n_per_row .> full_per_row .+ 1)
    n_bad = length(idx_bad)
    if n_bad > 0
      warn_fmt = n_bad == 1 ? "%d row has too many values (ID, decade %s)" : "%d rows have too many values (IDs, decades %s)"
      if n_bad > 5
        idx_bad = sample(idx_bad, 5)
        ids_decades = join([string(series[idx], ", ", decade_yr[idx]) for idx in idx_bad], "; ") * "..."
      else
        ids_decades = join([string(series[idx], "-", decade_yr[idx]) for idx in idx_bad], ", ")
      end
      @warn sprintf(warn_fmt, n_bad, ids_decades)
      return false
    end

    series_ids = unique(series)
    nseries = length(series_ids)
    series_index = [findfirst(isequal(s), series_ids) for s in series]
    last_row_of_series = falses(length(series))
    for i in 1:nseries
      idx_these = findall(isequal(i), series_index)
      last_row_of_series[idx_these[argmax(decade_yr[idx_these])]] = 1
    end

    flag_bad2 = n_per_row .< full_per_row
    if !all(last_row_of_series) && all(flag_bad2[.!last_row_of_series])
      @warn "all rows (last rows excluded) have too few values"
      return false
    end

    min_year = minimum(decade_yr)
    max_year = ((maximum(decade_yr) + 10) ÷ 10) * 10
    if max_year > year(Dates.now()) + 100
      @warn "file format problems (or data from the future)"
      return false
    end

    span = max_year - min_year + 1
    val_count = zeros(Int, span, nseries)
    for i in 1:length(series)
      this_col = series_index[i]
      these_rows = (decade_yr[i]-min_year+1):(n_per_row[i])
      val_count[these_rows, this_col] .+= 1
    end

    extra_vals = findall(val_count .> 1)
    n_extra = size(extra_vals, 1)
    if n_extra > 0
      warn_fmt = "Duplicated series ID detected: %s"
      ids_dup = join(unique(series_ids[[vals[2] for vals in extra_vals]]), "; ")
      @warn string(warn_fmt, ids_dup)
      return false
    else
      return true
    end
  end

  good_lines = filter(x -> !isempty(x), readlines(fname))
  good_lines = filter(x -> !startswith(x, "#"), good_lines)
  # parse out the whitespace and convert to vector of strings
  good_lines = [split(strip(x)) for x in good_lines]

  if isnothing(header)
    hdr1 = good_lines[1]
    if length(hdr1) == 0
      error("file is empty")
    end
    if length(hdr1) < 12
      error("first line in rwl file ends before col 12")
    end

    is_head = false
    yrcheck = tryparse(Int, hdr1[2])
    if isnothing(yrcheck) || yrcheck < -1e4 || yrcheck > 1e4 || yrcheck != round(yrcheck)
      is_head = true
    end
    if !is_head
      datacheck = hdr1[3:end]
      idx_good = findall(!isempty, datacheck)
      n_good = length(idx_good)
      if n_good == 0
        is_head = true
      else
        datacheck = datacheck[1:idx_good[end]]
        if any(occursin(r"[a-zA-Z]", d) for d in datacheck)
          is_head = true
        else
          datacheck = tryparse.(Int, datacheck)
          if any(d -> d === nothing || d != round(d), datacheck)
            is_head = true
          end
        end
      end
    end
    if is_head
      n_parts = length(hdr1)
      if n_parts >= 3 && n_parts <= 13
        hdr1_split = hdr1_split[2:end]
        if !any(occursin(r"[a-zA-Z]", part) for part in hdr1_split)
          yrdatacheck = tryparse.(Int, hdr1_split)
          if !(any(d -> d === nothing || d != round(d), yrdatacheck))
            is_head = false
          end
        end
      end
    end
    if is_head
      if verbose
        println("There appears to be a header in the rwl file")
      end
    else
      if verbose
        println("There does not appear to be a header in the rwl file")
      end
    end
  elseif !(header in [nothing, true, false])
    error("'header' must be NULL, TRUE or FALSE")
  else
    is_head = header
  end

  skip_lines = is_head ? 3 : 0
  data1 = good_lines[1:skip_lines+1]
  if length(data1) < skip_lines + 1
    error("file has no data")
  end

  if !occursin("\t", data1[1][end])
    dat = try
      CSV.File(fname, header=false, ignorerepeated=true, delim=' ', types=String, silencewarnings=true)
    catch e
      if verbose
        println("Error reading fixed width columns: ", e)
      end
      # Handle the error by converting types manually
      tfcon = open(fname, "r")
      tmp = CSV.File(tfcon, header=false, ignorerepeated=true, delim=' ', types=String, silencewarnings=true)
      # tmp = read_fwf(tfcon, fields, skip_lines; colClasses="character")
      close(tfcon)
      for idx in 2:12
        asnum = parse.(Float64, tmp[:, idx])
        if any(x -> x != round(x), asnum)
          error("non-integral numbers found")
        end
        tmp[:, idx] = round.(Int, asnum)
      end
      tmp
    end
    dat = filter(row -> !ismissing(row[2]), dat)
    series = [row[1] for row in dat]
    decade_yr = [parse(Int, row[2]) for row in dat]
    x = [ismissing.(row[j]) ? NA_INT : parse(Int, row[j]) for row in dat, j in 3:12]
    if edge_zeros
      x[isNA_INT.(x).&&(x.<0 .& x.!=-9999)] .= NA_INT
    else
      x[isNA_INT.(x).&&(x.<=0 .& x.!=-9999)] .= NA_INT
    end
    fixed_ok = input_ok(series, decade_yr, x)
  else
    @warn "tabs used, assuming non-standard, tab-delimited file"
    fixed_ok = false
  end

  if !fixed_ok
    @warn "fixed width failed, trying to reread with variable width columns"
    dat = try
      CSV.read(fname, header=false, delim=' ', ignorerepeated=true, types=String, skipto=skip_lines + 1, silencewarnings=true)
    catch
      CSV.read(fname, header=false, delim=' ', ignorerepeated=true, types=String, skipto=skip_lines + 1, silencewarnings=true)
    end
    dat = filter(row -> !ismissing(row[2]), dat)
    series = [row[1] for row in dat]
    decade_yr = [parse(Int, row[2]) for row in dat]
    x = [ismissing(row[j]) ? NA_INT : parse(Int, row[j]) for row in dat, j in 3:12]
    if edge_zeros
      x[isNA_INT.(x).&&(x.<0 .& x.!=-9999)] .= NA_INT
    else
      x[isNA_INT.(x).&&(x.<=0 .& x.!=-9999)] .= NA_INT
    end
    if !input_ok(series, decade_yr, x)
      error("failed to read rwl file")
    end
  end

  series_ids = unique(series)
  nseries = length(series_ids)
  series_index = [findfirst(isequal(s), series_ids) for s in series]
  extra_col = length(dat[1]) >= 13 ? [parse(Int, row[13]) for row in dat] : zeros(Int, size(dat, 1))

  int_mat, min_year, prec_rproc = readloop(series_index, decade_yr, x)


  rw_mat = fill(NaN, size(int_mat))
  span = size(rw_mat, 1)
  if span == 0
    rw_df = TimeArray(rw_mat, collect(1:span) .+ min_year .- 1, Symbol.(series_ids))
    return rw_df
  end
  max_year = min_year + (span - 1)

  prec_unknown = falses(nseries)
  for i in 1:nseries
    if !(prec_rproc[i] in [100, 1000])
      these_rows = findall(isequal(i), series_index)
      these_decades = decade_yr[these_rows]
      has_stop = findlast(extra_col[these_rows] .== 999 .|| extra_col[these_rows] .== -9999)
      if !isnothing(has_stop) && argmax(these_decades) == has_stop
        @warn "bad location of stop marker in series $(series_ids[i])"
        prec_rproc[i] = extra_col[these_rows[has_stop]] == 999 ? 100 : 1000
      end
    end
    this_prec_rproc = prec_rproc[i]
    if this_prec_rproc == 100
      int_mat[int_mat[:, i].==999, i] .= NA_INT
    elseif this_prec_rproc == 1000
      int_mat[int_mat[:, i].==-9999, i] .= NA_INT
    else
      prec_unknown[i] = true
    end
    t_col = int_mat[:, i]
    # convert to NaN if the value is NA_INT
    rw_mat[:, i] .= ifelse.(t_col .== NA_INT, NaN, t_col) ./ this_prec_rproc
  end

  if all(prec_unknown)
    error("precision unknown in all series")
  end

  if any(prec_unknown)
    upper_ids = uppercase.(series_ids)
    new_united = true
    series_united = 1:size(rw_mat, 2)
    while new_united
      new_united = false
      for this_series in findall(prec_unknown)
        these_rows = findall(isequal(this_series), series_index)
        last_row = these_rows[end]
        next_series = series_united[series_index[last_row+1]]
        if last_row == length(series) || upper_ids[this_series] != upper_ids[next_series]
          new_united = false
          break
        end
        last_decade = decade_yr[last_row]
        next_decade = decade_yr[last_row+1]
        if !prec_unknown[next_series] && next_decade > last_decade && next_decade <= last_decade + 10
          val_count = zeros(Int, span)
          this_col = rw_mat[:, this_series]
          next_col = rw_mat[:, next_series]
          flag_this = .!isnothing(this_col) .& .!isnan.(this_col)
          val_count[flag_this] .= 1
          flag_next = .!isnothing(next_col) .& .!isnan.(next_col)
          val_count[flag_next] .+= 1
          if any(val_count .> 1)
            new_united = false
            break
          end
          this_prec_rproc = prec_rproc[next_series]
          if this_prec_rproc == 100
            this_col[this_col.==999] .= NA_INT
          elseif this_prec_rproc == 1000
            this_col[this_col.==-9999] .= NA_INT
          end
          this_col ./= this_prec_rproc
          rw_mat[flag_this, next_series] .= this_col[flag_this]
          series_united[this_series] = next_series
          new_united = true
          prec_unknown[this_series] = false
          @warn "combining series $(series_ids[this_series]) and $(series_ids[next_series])"
        end
      end
    end
    prec_unknown = findall(prec_unknown)
    n_unknown = length(prec_unknown)
    if n_unknown > 0
      error("precision unknown in series $(join(series_ids[prec_unknown], ", "))")
    else
      to_keep = findall(isequal.(series_united, 1:size(rw_mat, 2)))
      rw_mat = rw_mat[:, to_keep]
      nseries = length(to_keep)
      series_ids = series_ids[to_keep]
      prec_rproc = prec_rproc[to_keep]
    end
  end

  the_range = hcat([findfirst(x -> !isnan(x), rw_mat[:, i]) for i in 1:size(rw_mat, 2)], [findlast(x -> !isnan(x), rw_mat[:, i]) for i in 1:size(rw_mat, 2)])
  series_min = the_range[:, 1]
  series_max = the_range[:, 2]
  good_series = .!isnan.(series_min)
  if !any(good_series)
    error("file has no good data")
  end

  incl_rows = (minimum(series_min[good_series])):(maximum(series_max[good_series]))
  rw_mat = rw_mat[incl_rows, :]

  Years = collect(incl_rows .+ min_year .- 1)
  TimeArray(Date.(Years), rw_mat, Symbol.(series_ids))
end
