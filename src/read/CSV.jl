# -------------------------------------------------------------------
# Licensed under the GPL-3.0 License. See LIENSE in the project root.
# -------------------------------------------------------------------


"""
  Base.read(format::_dendroCSV, fname::String; kwargs...)

Reads a CSV file and converts it to an TimeArray format.

# Arguments
- `format::dendroCSV`: A custom format type for dendrochronology CSV files.
- `fname::String`: The filename of the CSV file to read.
- `kwargs...`: Additional keyword arguments to pass to the CSV reader.

# Returns
- An `TimeArray` object containing the data from the CSV file.

# Raises
- `ErrorException`: If duplicated series IDs are detected in the CSV file.
"""
function Base.read(format::_dendroCSV, fname::String; kwargs...)
  Dendrochronology._csv2rwl(fname, kwargs...)
end
