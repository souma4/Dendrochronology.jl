
@testsnippet in_dummy begin
  dummy = [1 2 3; 4 5 6; 7 8 9; 10 11 12; 13 14 15; 16 17 18; 19 20 21; 22 23 24; 25 26 27; 28 29 30] * 100
  dummy_years = collect(1990:1999)
  dummy_colnames = [:A, :B, :C]
  in_dummy = RWLTable(dummy, dummy_years, dummy_colnames)
end

@testitem "io_rwl" setup = [Setup, in_dummy] begin
  # create
  write(joinpath(tempdir(), "test.rwl"), in_dummy, prec=0.01)
  @test isfile(joinpath(tempdir(), "test.rwl"))
  check = read(joinpath(tempdir(), "test.rwl"), long=true)
  @test in_dummy == check
  @test years(in_dummy) == years(check)
  @test values(in_dummy) == values(check)
  @test names(in_dummy) == names(check)
  @test Tables.istable(RWLTable) == true
  @test Tables.schema(check) == Tables.Schema(dummy_colnames, fill(Float64, 3))
  @test Tables.columnaccess(RWLTable) == true
  @test Tables.columns(check) == check
  @test Tables.getcolumn(check, :A) == [1.0, 4.0, 7.0, 10.0, 13.0, 16.0, 19.0, 22.0, 25.0, 28.0] * 100.0
  rm(joinpath(tempdir(), "test.rwl"))
end
