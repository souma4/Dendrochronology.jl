# -------------------------------------------------------------------
# Licensed under the GPL-3.0 License. See LIENSE in the project root.
# -------------------------------------------------------------------


partitioninds(rng::AbstractRNG, rwltable::AbstractRWLTable, method::PartitionMethod) =
  partitioninds(rng, years(rwltable), method)

sampleinds(rng::AbstractRNG, rwltable::AbstractRWLTable, method::DiscreteSamplingMethod) =
  sampleinds(rng, years(rwltable), method)

sortinds(rwltable::AbstractRWLTable, method::SortingMethod) = sortinds(years(rwltable), method)
