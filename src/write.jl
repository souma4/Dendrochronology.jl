# -------------------------------------------------------------------
# Licensed under the GPL-3.0 License. See LIENSE in the project root.
# -------------------------------------------------------------------
# Defined in read
# abstract type FileFormat end

# struct _dendroCSV <: FileFormat end
# struct Tucson <: FileFormat end
# struct Tridas <: FileFormat end

include("write/Tucson.jl")
include("write/CSV.jl")



"""
  write(file::String, data <: RWLTable)

write Ring-Width-Length table to specified file format.

# Arguments
- `file::String`: The path to the file to be written.
- `data <: RWLTable`: The Ring-Width-Length table to be written.

# Example
```
write("viet001.rwl", viet001_table)
```
"""
function Base.write(file::AbstractString, data::RWLTable; args...)
  ext = splitext(file)[2]
  format = get_format(ext)
  write(format, file, data; args...)
end
