
@testsnippet in_dummy begin
  dummy = [1 2 3; 4 5 6; 7 8 9; 10 11 12; 13 14 15; 16 17 18; 19 20 21; 22 23 24; 25 26 27; 28 29 30] * 100
  dummy_years = collect(1990:1999)
  dummy_colnames = [:A, :B, :C]
  in_dummy = TimeArray(Date.(dummy_years), dummy, dummy_colnames)
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
  rm(joinpath(tempdir(), "test.rwl"))
end

@testitem "io_csv" setup = [Setup, in_dummy] begin
  # create
  write(joinpath(tempdir(), "test.csv"), in_dummy)
  @test isfile(joinpath(tempdir(), "test.csv"))
  check = read(joinpath(tempdir(), "test.csv"))
  @test in_dummy == check
  @test years(in_dummy) == years(check)
  @test values(in_dummy) == values(check)
  @test names(in_dummy) == names(check)
  rm(joinpath(tempdir(), "test.csv"))
end
