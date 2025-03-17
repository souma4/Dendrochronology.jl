# -------------------------------------------------------------------
# Licensed under the GPL-3.0 License. See LIENSE in the project root.
# -------------------------------------------------------------------
# using CSV
"""
FTYPE = Union{Tucson, CSV}

parent type of all available file types
"""
abstract type FileFormat end

struct _dendroCSV <: FileFormat end
struct Tucson <: FileFormat end
struct Tridas <: FileFormat end
include("read/Tucson.jl")
include("read/CSV.jl")

"""
  read(filename::String)::String

Reads the entire contents of the file specified by `filename` and returns it as a Ring-Width_Length table.

# Arguments
- `filename::String`: The path to the file to be read.

# Examples
```
 read("viet001.rwl")
 ````
"""
function Base.read(file::AbstractString; args...)
  ext = splitext(file)[2]
  format = get_format(ext)
  read(format, file; args...)
end
