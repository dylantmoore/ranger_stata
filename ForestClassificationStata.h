/*
 * ForestClassificationStata.h -- Thin subclass exposing protected members
 */
#ifndef FORESTCLASSIFICATIONSTATA_H_
#define FORESTCLASSIFICATIONSTATA_H_

#include "vendor/ranger/ForestClassification.h"
#include "StataForestHelpers.h"

namespace ranger {

class ForestClassificationStata : public ForestClassification {
public:
  STATA_FOREST_HELPERS
};

} // namespace ranger

#endif /* FORESTCLASSIFICATIONSTATA_H_ */
