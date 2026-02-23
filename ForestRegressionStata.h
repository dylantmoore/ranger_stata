/*
 * ForestRegressionStata.h -- Thin subclass exposing protected members
 */
#ifndef FORESTREGRESSIONSTATA_H_
#define FORESTREGRESSIONSTATA_H_

#include "vendor/ranger/ForestRegression.h"
#include "StataForestHelpers.h"

namespace ranger {

class ForestRegressionStata : public ForestRegression {
public:
  STATA_FOREST_HELPERS
};

} // namespace ranger

#endif /* FORESTREGRESSIONSTATA_H_ */
