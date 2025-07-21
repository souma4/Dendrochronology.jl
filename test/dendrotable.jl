@testsnippet rwltable begin
  dummy_matrix = Float64.([1 2 3; 4 5 6; 7 8 9] * 100)
  dummy_years = collect(1990:1992)
  dummy_colnames = [:A, :B, :C]
  rwltable = TimeArray(Date.(dummy_years), dummy_matrix, dummy_colnames)
end

@testitem "TimeArray" setup=[Setup, rwltable]begin
  @test years(rwltable) == dummy_years
  @test values(rwltable) == dummy_matrix
  @test names(rwltable) == dummy_colnames
  @test Tables.DataAPI.nrow(rwltable) == 3
  @test Tables.DataAPI.ncol(rwltable) == 3
  @test length(rwltable) == 3
  @test rwltable == rwltable
  @test first(rwltable) == rwltable[1]
  @test last(rwltable) == rwltable[3]
  @test dendrostats(rwltable) == nothing

  @inferred years(rwltable)
  @inferred values(rwltable)
  @inferred names(rwltable)
  @inferred Tables.DataAPI.nrow(rwltable)
  @inferred Tables.DataAPI.ncol(rwltable)
  @inferred length(rwltable)
  @inferred first(rwltable)
  @inferred last(rwltable)

end
