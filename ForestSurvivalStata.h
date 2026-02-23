/*
 * ForestSurvivalStata.h -- Thin subclass exposing protected members
 */
#ifndef FORESTSURVIVALSTATA_H_
#define FORESTSURVIVALSTATA_H_

#include "vendor/ranger/ForestSurvival.h"
#include "StataForestHelpers.h"

namespace ranger {

class ForestSurvivalStata : public ForestSurvival {
public:
  STATA_FOREST_HELPERS
};

} // namespace ranger

#endif /* FORESTSURVIVALSTATA_H_ */
