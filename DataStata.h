/*
 * DataStata.h -- Thin subclass of DataDouble exposing protected members
 * for direct population from Stata's SF_vdata() interface.
 */
#ifndef DATASTATA_H_
#define DATASTATA_H_

#include "vendor/ranger/DataDouble.h"

namespace ranger {

class DataStata : public DataDouble {
public:
  void setDimensions(size_t num_rows, size_t num_cols) {
    this->num_rows = num_rows;
    this->num_cols = num_cols;
    this->num_cols_no_snp = num_cols;
  }

  void setVariableNames(std::vector<std::string>& names) {
    this->variable_names = names;
  }
};

} // namespace ranger

#endif /* DATASTATA_H_ */
