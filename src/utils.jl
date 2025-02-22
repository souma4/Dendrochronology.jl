include("utils/readloop.jl")
INT_MAX = typemax(Int)
INT_MIN = typemin(Int)

NA_INT = -2147483648
NA_INTstring = "-2147483648"

isNA_INT(integer::N) where {N<:Integer} = integer == NA_INT
isNA_INT(string::AbstractString) = string == NA_INTstring
# # environment settings
# isCI = "CI" ∈ keys(ENV)
# islinux = Sys.islinux()
# visualtests = !isCI || (isCI && islinux)
# datadir = joinpath(@__DIR__, "../data")

# # float settings
# T = if isCI
#   if ENV["FLOAT_TYPE"] == "Float32"
#     Float32
#   elseif ENV["FLOAT_TYPE"] == "Float64"
#     Float64
#   end
# else
#   Float64
# end
function get_format(ext::String)::FileFormat
  if ext == ".tuc" || ext == ".rwl" || ext == ".cm" || ext == ".dec"
    return Tucson()
  elseif ext == ".csv"
    return _dendroCSV()
    # elseif ext == ".tridas"
    #   return Tridas()
  else
    error("Unsupported file format: $ext")
  end
end

function _fix_names(col_names, name_width, mapping_fname, mapping_append; basic_charset=true)
  fn = mapping_fname
  if !(isa(fn, String) && !isempty(fn))
    fn = ""
  end
  write_map = false
  n_x = length(col_names)
  x_cut = col_names
  if eltype(x_cut) != String
    x_cut = string.(x_cut)
  end
  rename_flag = falses(n_x)
  if basic_charset
    bad_chars = r"[^a-zA-Z0-9]"
    idx_bad = findall(x -> occursin(bad_chars, x), x_cut)
    if !isempty(idx_bad)
      @warn "characters outside a-z, A-Z, 0-9 present: renaming series"
      if !isempty(fn)
        write_map = true
      end
      rename_flag[idx_bad] .= true
      x_cut[idx_bad] .= replace.(x_cut[idx_bad], bad_chars => "")
    end
  end
  if !isnothing(name_width)
    over_limit = findall(x -> length(x) > name_width, x_cut)
    if !isempty(over_limit)
      @warn "some names are too long: renaming series"
      if !isempty(fn)
        write_map = true
      end
      rename_flag[over_limit] .= true
      x_cut[over_limit] .= first.(x_cut[over_limit], name_width)
    end
  end
  unique_cut = unique(x_cut)
  n_unique = length(unique_cut)
  if n_unique == n_x
    y = deepcopy(x_cut)
  else
    @warn "duplicate names present: renaming series"
    if !isempty(fn)
      write_map = true
    end
    y = fill("", n_x)
    alphanumeric = [string(i) for i in vcat(collect('0':'9'), collect('A':'Z'), collect('a':'z'))]
    for i in 1:n_unique
      idx_this = findall(x -> x == unique_cut[i], x_cut)
      if length(idx_this) == 1
        y[idx_this] = x_cut[idx_this]
      end
    end
    if !isnothing(name_width)
      x_cut .= first.(x_cut, name_width - 1)
    end
    x_cut[y.!=""] .= "NA"
    unique_cut = unique(x_cut)
    n_unique = length(unique_cut)
    for i in 1:n_unique
      this_substr = unique_cut[i]
      if this_substr == "NA"
        continue
      end
      idx_this = findall(x -> x == this_substr, x_cut)
      suffix_count = 0
      for j in 1:length(idx_this)
        still_looking = true
        while still_looking
          suffix_count += 1
          proposed = this_substr * alphanumeric[suffix_count]
          if !isempty(name_width) && length(proposed) > name_width
            proposed = ""
          end
          if isempty(proposed)
            @warn "could not remap a name: some series will be missing"
            still_looking = false
            proposed = this_substr * "F"
          elseif !any(y .== proposed)
            still_looking = false
          end
        end
        y[idx_this[j]] = proposed
        rename_flag[idx_this[j]] = true
      end
    end
  end
  if write_map
    open(mapping_append && isfile(fn) ? "a" : "w", fn) do map_file
      for i in findall(rename_flag)
        if col_names[i] != y[i]
          write(map_file, "$(col_names[i])\t$(y[i])\n")
        end
      end
    end
  end
  return y
end

function _csv2rwl(fname, kwargs...)
  nameCheck = values(CSV.File(fname; header=false, limit=1)[1])
  if any(_nonunique(nameCheck))
    warn_fmt = "Duplicated series ID detected: "
    ids_dup = join(nameCheck[findall(_nonunique(nameCheck))], "; ")
    error(warn_fmt * ids_dup)
  else
    dat = CSV.File(fname; header=true, kwargs...)
    rownames = [dat[i][1] for i in 1:size(dat, 1)]
    colnames = keys(dat[1])
    # loop through the rows and add to matrix
    matrix = zeros(Float64, size(dat, 1), length(colnames) - 1)
    for i in 1:size(dat, 1)
      for j in 2:length(colnames)
        l_dat = dat[i][j]
        # if NA set to 0
        if l_dat == "NA"
          matrix[i, j-1] = 0.0
        elseif typeof(l_dat) <: AbstractString
          matrix[i, j-1] = parse(Float64, l_dat)
        elseif typeof(l_dat) <: Integer
          matrix[i, j-1] = Float64(l_dat)
        else
          matrix[i, j-1] = l_dat
        end
      end
    end

    RWLTable(matrix, rownames, colnames[2:end])
  end
end

function _nonunique(x::AbstractVector)
  n = length(x)
  y = falses(n)
  for i in 1:n
    y[i] = sum(any(x .== x[i])) > 1
  end
  return y
end
