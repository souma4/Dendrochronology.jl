using Printf

struct Compact <: FTYPE
  fname::String
  Compact(fname::String) = new(fname)
end
Base.show(io::IO, t::Compact) = print(io, "Compact(", t.fname, ")")

function read(fname::Compact)
  <:IO
  res = compact(expanduser(fname))
  min_year = res[1]
  max_year = res[2]
  series_ids = res[3]
  series_min = res[4]
  series_max = res[5]
  series_mplier = res[6]
  rw_mat = res[7]
  project_comments = res[8]
  rownames!(rw_mat, min_year:max_year)
  nseries = size(rw_mat, 2)

  println(nseries == 1 ? "There is $nseries series" : "There are $nseries series")
  series_min_char = string.(series_min)
  series_max_char = string.(series_max)
  seq_series_char = string.(1:nseries)
  for i in 1:nseries
    @printf("%5s\t%8s\t%5s\t%5s\t%s\n", seq_series_char[i], series_ids[i], series_min_char[i], series_max_char[i], series_mplier[i])
  end
  if !isempty(project_comments)
    println("Comments:")
    println(join(project_comments, "\n"))
  end

  rw_df = DataFrame(rw_mat)
  names!(rw_df, series_ids)
  return rw_df
end
