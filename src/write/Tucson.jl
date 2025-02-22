# -------------------------------------------------------------------
# Licensed under the GPL-3.0 License. See LIENSE in the project root.
# -------------------------------------------------------------------

"""
  write(format::Tucson, fname::String, rwl_table::RWLTable; header=nothing, append=false, prec=0.01,
     mapping_fname="", mapping_append=false, long_names=true)

Write the given `rwl_table` to a file in the Tucson format.

# Arguments
- `format::Tucson`: The format in which to write the file.
- `fname::String`: The name of the file to write.
- `rwl_table::RWLTable`: The table containing the ring width data to write.

# Keyword Arguments
- `header`: Optional header information to include in the file. Default is `nothing`.
- `append::Bool`: Whether to append to the file if it exists. Default is `false`.
- `prec::Float64`: The precision of the data. Default is `0.01`. `0.001` is also supported.
- `mapping_fname::String`: The name of the mapping file. Default is an empty string.
- `mapping_append::Bool`: Whether to append to the mapping file if it exists. Default is `false`.
- `long_names::Bool`: Whether to use long names in the file. Default is `true`.

# Example
# Write the RWLTable to a file in Tucson format
write(Tucson(), "output.tuc", rwl_table; kwargs...)

"""
function Base.write(format::Tucson, fname::String, rwl_table::RWLTable; header=nothing, append=false, prec=0.01,
  mapping_fname="", mapping_append=false, long_names=true)
  line_term = "\r\n"  # CR+LF, ASCII carriage return and line feed

  rwl_df = values(rwl_table)


  if !isa(prec, Number) || length(prec) != 1 || isnan(prec) || !(prec == 0.01 || prec == 0.001)
    error("'prec' must equal 0.01 or 0.001")
  end

  header2 = header
  if append
    if !isfile(fname)
      error("file $fname does not exist, cannot append")
    end
    if !isempty(header2)
      error("bad idea to append with 'header'")
    end
  end

  if !isnothing(header2)
    if !isa(header2, Set) && !isa(header2, Dict)
      error("'header' must be a Set or Dict")
    end

    header_names = ["site_id", "site_name", "spp_code", "state_country", "spp", "elev", "lat", "long", "first_yr", "last_yr", "lead_invs", "comp.date"]
    if isa(header2, Set)
      if !all(ismember(header_names, header2))
        error("'header' must be a Set with the following names: $(join(header_names, ", "))")
      end
    elseif isa(header2, Dict)
      if !all(ismember(header_names, keys(header2)))
        error("'header' must be a Dict with the following names: $(join(header_names, ", "))")
      end
    end

    site_id = string(header2["site_id"])
    site_name = string(header2["site_name"])
    spp_code = string(header2["spp_code"])
    state_country = string(header2["state_country"])
    spp = string(header2["spp"])
    elev = string(header2["elev"])
    lat = string(header2["lat"])
    long = string(header2["long"])
    lead_invs = string(header2["lead_invs"])
    comp_date = string(header2["comp_date"])
    lat_long = length(long) > 5 ? lat * long : "$lat $long"
    yrs = "$(header2["first_yr"]) $(header2["last_yr"])"

    field_name = ["site_id", "site_name", "spp_code", "state_country", "spp", "elev", "lat_long", "yrs", "lead_invs", "comp_date"]
    field_width = [6, 52, 4, 13, 18, 5, 10, 9, 63, 8]

    for (i, name) in enumerate(field_name)
      width = field_width[i]
      var = eval(Meta.parse(name))
      nchar = length(var)
      if nchar > width
        eval(Meta.parse("$name = $(var[1:width])"))
      elseif nchar < width
        eval(Meta.parse("$name = lpad(var, width)"))
      end
    end

    hdr1 = "$site_id   $site_name$spp_code"
    hdr2 = "$site_id   $state_country$spp $elev  $lat_long          $yrs"
    hdr3 = "$site_id   $lead_invs$comp_date"
  end

  nseries = size(rwl_df, 2)
  yrs_all = collect(years(rwl_table))
  col_names = names(rwl_table)

  yrs_order = sortperm(yrs_all)
  yrs_all = yrs_all[yrs_order]
  rwl_df2 = rwl_df[yrs_order, :]

  first_year = yrs_all[begin]
  last_year = yrs_all[end]
  long_years = false

  if first_year < -999
    long_years = true
    if first_year < -9999
      error("years earlier than -9999 (10000 BC) are not supported")
    end
  end

  if last_year > 9999
    long_years = true
    if last_year > 99999
      error("years later than 99999 are not possible")
    end
  end

  name_width = 7

  if long_names
    exploit_short = true
    use_space = false
  else
    exploit_short = false
    use_space = true
  end

  if exploit_short && !long_years
    name_width += 1
  end

  if use_space
    name_width -= 1
    opt_space = " "
  else
    opt_space = ""
  end

  name_width = Int(name_width)
  year_width = Int(12 - name_width - length(opt_space))

  col_names = _fix_names(col_names, name_width, mapping_fname, mapping_append)

  open(fname, append ? "a" : "w") do rwl_out
    if !isnothing(header2)
      write(rwl_out, hdr1 * line_term)
      write(rwl_out, hdr2 * line_term)
      write(rwl_out, hdr3 * line_term)
    end

    if prec == 0.01
      na_str = 9.99
      missing_str = -9.99
      prec_rproc = 100
    else
      na_str = -9.999
      missing_str = 0
      prec_rproc = 1000
    end

    format_year = Printf.Format("%$(year_width)d")
    for l in 1:nseries
      series = rwl_df2[:, l]
      idx = .!ismissing.(series)
      yrs = yrs_all[idx]
      series = series[idx]

      series = vcat(series, na_str)
      yrs = vcat(yrs, maximum(yrs) + 1)

      decades_vec = div.(yrs, 10) .* 10
      decades = minimum(decades_vec):10:maximum(decades_vec)
      n_decades = length(decades)

      rwl_df_name = lpad(col_names[l], name_width)

      for i in 1:n_decades
        dec = decades[i]
        dec_idx = decades_vec .== dec
        dec_yrs = yrs[dec_idx]
        dec_rwl = series[dec_idx]

        neg_match = dec_rwl .< 0
        if prec == 0.001 && i == n_decades
          neg_match[end] = false
        end
        dec_rwl[neg_match] .= missing_str

        if n_decades == 1
          all_years = dec_yrs[1]:dec_yrs[end]
        elseif i == 1
          all_years = dec_yrs[1]:(dec+9)
        elseif i == n_decades
          all_years = dec:(dec_yrs[end])
        else
          all_years = dec:(dec+9)
        end

        if length(all_years) > length(dec_yrs)
          missing_years = setdiff(all_years, dec_yrs)
          dec_yrs = vcat(dec_yrs, missing_years)
          dec_rwl = vcat(dec_rwl, fill(missing_str, length(missing_years)))
          dec_order = sortperm(dec_yrs)
          dec_yrs = dec_yrs[dec_order]
          dec_rwl = dec_rwl[dec_order]
        end

        dec_year1 = Printf.format(format_year, dec_yrs[1])
        dec_rwl = round.(dec_rwl .* prec_rproc)

        if prec == 0.01
          end_match = dec_rwl .== 999
          if i == n_decades
            end_match[end] = false
          end
          dec_rwl[end_match] .= rand([998, 1000], sum(end_match))
        end

        dec_rwl = [@sprintf("%6d", x) for x in dec_rwl]
        zero_match = findall(x -> x == "     0", dec_rwl)
        if !isempty(zero_match)
          last_non_zero = findlast(x -> x != "     0", dec_rwl)
          if !isnothing(last_non_zero)
            dec_rwl = dec_rwl[1:last_non_zero]
          end
          if all(x -> x == "     0", dec_rwl)
            continue
          end
        end

        # create the line to write out
        write_string = rwl_df_name * " " * opt_space * dec_year1 * " " * join(dec_rwl, " ") * line_term

        write(rwl_out, write_string)
      end
    end
  end

  return fname
end
