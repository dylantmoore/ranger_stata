/*
 * ForestProbabilityStata.h -- Thin subclass exposing protected members
 */
#ifndef FORESTPROBABILITYSTATA_H_
#define FORESTPROBABILITYSTATA_H_

#include "vendor/ranger/ForestProbability.h"
#include "StataForestHelpers.h"

namespace ranger {

class ForestProbabilityStata : public ForestProbability {
public:
  STATA_FOREST_HELPERS
};

} // namespace ranger

#endif /* FORESTPROBABILITYSTATA_H_ */
