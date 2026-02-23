/*
 * StataForestHelpers.h -- Shared macro for all Forest adapter subclasses
 *
 * Exposes protected members needed by the Stata plugin:
 *   - dependent_variable_names (for init)
 *   - output_prefix (for save)
 *   - loadFromFile / loadDependentVariableNamesFromFile (for predict)
 */
#ifndef STATAFORESTHELPERS_H_
#define STATAFORESTHELPERS_H_

#define STATA_FOREST_HELPERS \
  void setDependentVariableNames(std::vector<std::string>& names) { \
    this->dependent_variable_names = names; \
  } \
  void setOutputPrefix(const std::string& p) { \
    this->output_prefix = p; \
  } \
  void callLoadFromFile(const std::string& f) { \
    this->loadFromFile(f); \
  } \
  void callLoadDepVarNames(const std::string& f) { \
    this->loadDependentVariableNamesFromFile(f); \
  }

#endif /* STATAFORESTHELPERS_H_ */
