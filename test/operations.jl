# @testsnippet lhtable begin
#   lh = [row[1] for row in CSV.File("data/lh.txt")]
#   lht = hcat(lh, log.(lh), reverse(lh))
# end

# @testitem "" setup = [setup, lhtable] begin
#   # AR in the 1d case
#   fitᵢ = Dendrochronology._fit(lht[:, 1])
#   @inferred Dendrochronology._fit(lht[:, 1])

#   AR₁ = Dendrochronology._ar(lht[:, 1])
#   @inferred Dendrochronology._ar(lht[:, 1])


#   ARcol₁ = Dendrochronology._fit(lht; dim=1)

#   Φ, residuals = _solveAR(lh, 2)
#   @test Φ ≈ [0.0, 0.0, 0.0]
#   @test residuals ≈ [0.0, 0.0, 0.0]
# end
