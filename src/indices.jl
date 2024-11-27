# -------------------------------------------------------------------
# Licensed under the GPL-3.0 License. See LIENSE in the project root.
# -------------------------------------------------------------------


partitioninds(rng::AbstractRNG, dendrotable::AbstractDendroTable, method::PartitionMethod) =
  partitioninds(rng, years(dendrotable), method)

sampleinds(rng::AbstractRNG, dendrotable::AbstractDendroTable, method::DiscreteSamplingMethod) =
  sampleinds(rng, years(dendrotable), method)

sortinds(dendrotable::AbstractDendroTable, method::SortingMethod) = sortinds(years(dendrotable), method)