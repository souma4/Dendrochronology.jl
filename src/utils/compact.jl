

using Base: read, open, close

const CONTENT_LENGTH = 80
const LINE_LENGTH = 83
const MPLIER_LENGTH = 5

struct RWLNode
  first_yr::Int
  n::Int
  data::Vector{T} where {T<:Real}
  mplier::T where {T<:Real}
  id::String
  next::Union{Nothing,RWLNode}
end

struct CommentNode
  text::String
  next::Union{Nothing,CommentNode}
end

function fgets_eol(s::Vector{T}, n_noteol::Ref{T}, size::T, stream::IO) where {T<:Integer}
  i = -1
  while i < size - 2
    this_char = read(stream, UInt8)
    i += 1
    if this_char == eof(stream)
      s[i+1] = 0
      if i == 0
        n_noteol[] = 0
        return nothing
      else
        n_noteol[] = i
        return s
      end
    elseif this_char == '\n' || this_char == '\r'
      s[i+1] = this_char
      n_noteol[] = i
      while i < size - 2
        this_char = read(stream, UInt8)
        if this_char == eof(stream)
          s[i+1] = 0
          return s
        elseif this_char != '\n' && this_char != '\r'
          seek(stream, position(stream) - 1)
          s[i+1] = 0
          return s
        else
          i += 1
          s[i+1] = this_char
        end
      end
      return s
    else
      s[i+1] = this_char
    end
  end
  n_noteol[] = i + 1
  s[i+1] = 0
  return s
end

function compact(filename::String)
  field_id::String
  line = Vector{T}(undef, LINE_LENGTH) where {T<:UInt}
  mplier_str = Vector{T}(undef, MPLIER_LENGTH) where {T<:UInt}
  n_content = Ref{T}(0) where {T<:Int}
  n_comments = 0
  early_eof = false

  f = open(filename, "r")
  if isnothing(f)
    error("Could not open file $filename for reading")
  end

  first = RWLNode(0, 0, [], 0.0, "", nothing)
  this = first
  comment_first = CommentNode("", nothing)
  comment_this = comment_first
  n = 0
  first_yr = typemax(Int)
  last_yr = typemin(Int)

  while !isnothing(fgets_eol(line, n_content, LINE_LENGTH, f))
    while isnothing(findfirst(==('~'), line))
      if n_content[] > 0
        if n_comments == typemax(Int)
          error("Number of comments exceeds integer range")
        end
        n_comments += 1
        tmp_comment = String(copy(line[1:n_content[]]))
        comment_this.text = tmp_comment
        comment_this.next = CommentNode("", nothing)
        comment_this = comment_this.next
      end
      if isnothing(fgets_eol(line, n_content, LINE_LENGTH, f))
        early_eof = true
        break
      end
    end
    if early_eof
      break
    end

    if n == typemax(Int)
      error("Number of series exceeds integer range")
    end

    if n_content[] > CONTENT_LENGTH
      close(f)
      error("Series $(n+1): Header line is too long (max length $CONTENT_LENGTH)")
    end

    found1 = findfirst(==('='), line)
    if isnothing(found1)
      close(f)
      error("Series $(n+1): No '=' found when header line was expected")
    end

    read_int = parse(Int, String(copy(line[1:found1-1])))
    field_id = String(line[found1+1])
    if field_id == 'N'
      if read_int <= 0
        close(f)
        error("Series $(n+1): Length of series must be at least one ($read_int seen)")
      end
      this.n = read_int
    elseif field_id == 'I'
      this.first_yr = read_int
    else
      close(f)
      error("Series $(n+1): Unknown field id: $field_id")
    end

    found2 = findfirst(==('='), line[found1+3:end])
    if isnothing(found2)
      close(f)
      error("Series $(n+1): Second '=' missing")
    end

    read_int = parse(Int, String(copy(line[found1+3:found2-1])))
    field_id = String(line[found2+1])
    if field_id == 'I'
      this.first_yr = read_int
    elseif field_id == 'N'
      if read_int <= 0
        close(f)
        error("Series $(n+1): Length of series must be at least one ($read_int seen)")
      end
      this.n = read_int
      T() = typeof(this.n)
    else
      close(f)
      error("Series $(n+1): Unknown or doubled field id: $field_id")
    end

    if this.first_yr < first_yr
      first_yr = this.first_yr
    end
    this_last = this.first_yr + (this.n - 1)
    if this_last > last_yr
      last_yr = this_last
    end

    point = found2 + 2
    while line[point] == ' '
      point += 1
    end

    found_tilde = findfirst(==('~'), line[point+1:end])
    if isnothing(found_tilde) || found_tilde < point + 2
      close(f)
      error("Series $(n+1): '~' not found in expected location")
    end

    id_start = point
    point2 = found_tilde - 1
    while line[point2] == ' '
      point2 -= 1
    end

    this.id = String(copy(line[id_start:point2]))

    point = found_tilde + 1
    exponent = parse(Int, String(copy(line[point:findfirst(==('('), line[point:end])-1])))
    if exponent < 0
      exponent = -exponent
      divide = true
    else
      divide = false
    end

    mplier_str = "1e$exponent"
    if divide
      this.mplier = 1 / parse(Float64, mplier_str)
    else
      this.mplier = parse(Float64, mplier_str)
    end

    point = findfirst(==('('), line[point:end]) + 1
    n_repeats = parse(Int, String(copy(line[point:findfirst(==('F'), line[point:end])-1])))
    field_width = parse(Int, String(copy(line[findfirst(==('F'), line[point:end])+1:findfirst(==('.'), line[point:end])-1])))
    precision = parse(Int, String(copy(line[findfirst(==('.'), line[point:end])+1:findfirst(==(')'), line[point:end])-1])))

    this.data = Vector{T}(undef, this.n)
    n_lines = div(this.n, n_repeats)
    remainder = this.n % n_repeats

    idx = -n_repeats
    for i in 1:n_lines
      if isnothing(fgets_eol(line, n_content, LINE_LENGTH, f))
        close(f)
        error("Series $(n+1): Unexpected end of file ($i data lines read)")
      end
      point = n_repeats * field_width
      idx += n_repeats * 2
      for j in 1:n_repeats
        old_point = point
        point -= field_width
        read_double = parse(Float64, String(copy(line[point:old_point-1])))
        if point != old_point
          close(f)
          error("Series $(n+1) ($(this.id)): Could not read number (data row $(i+1), field $(n_repeats-j)).\nMalformed number or previous line too long.")
        end
        if divide
          this.data[idx] = read_double / this.mplier
        else
          this.data[idx] = read_double * this.mplier
        end
      end
    end

    if remainder > 0
      if isnothing(fgets_eol(line, n_content, LINE_LENGTH, f))
        close(f)
        error("Series $(n+1): Unexpected end of file (remainder data line read)")
      end
      point = remainder * field_width
      idx += remainder * 2
      for j in 1:remainder
        old_point = point
        point -= field_width
        read_double = parse(Float64, String(copy(line[point:old_point-1])))
        if point != old_point
          close(f)
          error("Series $(n+1) ($(this.id)): Could not read number (remainder data row, field $j).\nMalformed number or previous line too long.")
        end
        if divide
          this.data[idx] = read_double / this.mplier
        else
          this.data[idx] = read_double * this.mplier
        end
      end
    end

    this.next = RWLNode(0, 0, [], 0.0, "", nothing)
    this = this.next
    n += 1
  end

  close(f)

  if early_eof
    error("Unexpected end of file")
  end

  result = Vector{Any}(undef, 7)

  result[1] = first_yr
  result[2] = last_yr
  result[3] = Vector{String}(undef, n)
  result[4] = Vector{Int}(undef, n)
  result[5] = Vector{Int}(undef, n)
  result[6] = Vector{AbstractFloat}(undef, n)
  result[7] = Matrix{Union{Missing,AbstractFloat}}(missing, last_yr - first_yr + 1, n)
  project_comments = Vector{String}(undef, n_comments)

  this = first
  for i in 1:n
    this_last = this.first_yr + (this.n - 1)
    result[3][i] = this.id
    result[4][i] = this.first_yr
    result[5][i] = this_last
    result[6][i] = this.mplier

    for j in 1:(this.first_yr-first_yr)
      result[7][j, i] = missing
    end

    for j in 1:this.n
      result[7][this.first_yr-first_yr+j, i] = this.data[j]
    end

    for j in (this_last+1):last_yr
      result[7][j-first_yr+1, i] = missing
    end

    this = this.next
  end

  comment_this = comment_first
  for i in 1:n_comments
    project_comments[i] = comment_this.text
    comment_this = comment_this.next
  end

  result = vcat(result, project_comments)
  return result
end
