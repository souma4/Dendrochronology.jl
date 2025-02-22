@testsnippet rwltable begin
  dummy_matrix = [1 2 3; 4 5 6; 7 8 9] * 100
  dummy_years = collect(1990:1992)
  dummy_colnames = [:A, :B, :C]
  rwltable = RWLTable(dummy_matrix, dummy_years, dummy_colnames)
end

@testitem "RWLTable" setup=[Setup, rwltable]begin
  @test years(rwltable) == dummy_years
  @test values(rwltable) == dummy_matrix
  @test names(rwltable) == dummy_colnames
  @test Dendrochronology.lookup(rwltable) == Dict(:A => 1, :B => 2, :C => 3)
  @test Tables.istable(RWLTable) == true
  @test Tables.schema(rwltable) == Tables.Schema(dummy_colnames, fill(Int, 3))
  @test Tables.columnaccess(RWLTable) == true
  @test Tables.columns(rwltable) == rwltable
  @test Tables.getcolumn(rwltable, :A) == [100, 400, 700]
  @test Tables.getcolumn(rwltable, 1) == [1990, 1991, 1992]
  @test Tables.columnnames(rwltable) == [:Year, :A, :B, :C]
  @test Tables.rowaccess(RWLTable) == true
  @test length(rwltable) == 3
  @test rwltable == rwltable
  @test iterate(rwltable) == (1990, (2, 1))
  @test [col for col in eachcol(rwltable)] == [[1990, 1991, 1992], [100, 400, 700], [200, 500, 800], [300, 600, 900]]
  @test [row for row in eachrow(rwltable)] == [Dendrochronology.RWLRow(1, rwltable), Dendrochronology.RWLRow(2, rwltable), Dendrochronology.RWLRow(3, rwltable)]

end

@testitem "RWLRow" setup=[Setup, rwltable] begin
  @test Tables.getcolumn(Dendrochronology.RWLRow(1, rwltable), :A) == 100
  @test Tables.getcolumn(Dendrochronology.RWLRow(1, rwltable), 1) == 100
  @test Tables.columnnames(Dendrochronology.RWLRow(1, rwltable)) == [:A, :B, :C]
  @test Dendrochronology.RWLRow(1, rwltable) == Dendrochronology.RWLRow(1, rwltable)
  @test Tables.getcolumn(Dendrochronology.RWLRow(1, rwltable), :Year) == 1990
end
