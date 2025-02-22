# -------------------------------------------------------------------
# Licensed under the GPL-3.0 License. See LIENSE in the project root.
# -------------------------------------------------------------------

# write RWLTable using CSV write
function Base.write(format::_dendroCSV, fname::String, rwl_table::RWLTable)
  # write the RWLTable to a CSV file
  # create a simple 3x3 table with
  year_col = years(rwl_table)
  column_names = [:Year, names(rwl_table)...]
  vals = values(rwl_table)
  table = hcat(year_col, eachcol(vals)...)
  CSV.write(fname, Tables.table(table, header=column_names))

end
