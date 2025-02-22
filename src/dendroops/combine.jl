function combine(x <: T, y <: T) where {T<:AbstractRWLTable}

  combinator(x, y) = begin
    dim_x2 = size(x, 2)
    dim_y2 = size(y, 2)
    if dim_x2 > 0 && dim_y2 > 0
      dim2 = dim_x2 + dim_y2
      years_x = collect(keys(x))
      years_y = collect(keys(y))
      min_x = parse(Int, first(years_x))
      min_y = parse(Int, first(years_y))
      max_x = parse(Int, last(years_x))
      max_y = parse(Int, last(years_y))
      min_year = min(min_x, min_y)
      years = min_year:max(max_x, max_y)
      new = fill(NaN, length(years), dim2)
      new[(min_x-min_year+1):(max_x-min_year+1), 1:dim_x2] .= x
      new[(min_y-min_year+1):(max_y-min_year+1), (dim_x2+1):dim2] .= y
      new
    elseif dim_y2 == 0
      x
    else
      y
    end
  end

  if isa(x, Vector)
    n = length(x)
    if n > 0 && all(isa.(x, DataFrame))
      new_mat = Matrix(x[1])
      for i in 2:n
        new_mat = combinator(new_mat, Matrix(x[i]))
      end
    elseif isa(x, DataFrame) && isa(y, DataFrame)
      new_mat = combinator(Matrix(x), Matrix(y))
    else
      error("Nothing to combine here. Please supply data.frames formatted according to the data standards in dplR.")
    end
  else
    error("Nothing to combine here. Please supply data.frames formatted according to the data standards in dplR.")
  end

  new_mat = DataFrame(new_mat)
  return new_mat
end
