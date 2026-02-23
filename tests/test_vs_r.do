* test_vs_r.do -- Cross-validate Stata ranger against R ranger
* Requires: reference CSVs from generate_reference.R
* Run from the tests/ directory

clear all
set more off

adopath ++ ".."

* ── Regression cross-validation ────────────────────────────────────
display as text ""
display as text "=== Regression: Stata vs R ==="
display as text ""

* Load R reference data
import delimited "ref_regression_data.csv", clear
describe

* Run Stata ranger with same parameters
ranger y x1 x2 x3, gen(stata_pred) seed(42) ntrees(500) ///
    importance(impurity) numthreads(1)

* Load R predictions
preserve
import delimited "ref_regression_preds.csv", clear
rename oob_pred r_pred
tempfile rpreds
save `rpreds'
restore

* Merge R predictions
gen _n_obs = _n
merge 1:1 _n_obs using `rpreds', nogenerate
drop _n_obs

* Compute correlation
correlate stata_pred r_pred
local reg_corr = r(rho)

display as text ""
display as text "Regression Stata-vs-R correlation: " as result %6.4f `reg_corr'

if `reg_corr' > 0.90 {
    display as text "PASSED (correlation > 0.90)"
}
else {
    display as error "FAILED (correlation = `reg_corr', expected > 0.90)"
}

* ── Classification cross-validation ────────────────────────────────
display as text ""
display as text "=== Classification: Stata vs R ==="
display as text ""

* Load R reference data
import delimited "ref_classification_data.csv", clear
* y is factor in R, destring it
destring y, replace force

* Run Stata ranger with same parameters
ranger y x1 x2 x3, gen(stata_pred) type(classification) seed(42) ///
    ntrees(500) importance(impurity) numthreads(1)

* Load R predictions
preserve
import delimited "ref_classification_preds.csv", clear
rename oob_pred r_pred
tempfile rpreds
save `rpreds'
restore

* Merge R predictions
gen _n_obs = _n
merge 1:1 _n_obs using `rpreds', nogenerate
drop _n_obs

* Compute agreement rate
gen agree = (stata_pred == r_pred) if !missing(stata_pred) & !missing(r_pred)
summarize agree
local agreement = r(mean)

display as text ""
display as text "Classification agreement rate: " as result %6.4f `agreement'

if `agreement' > 0.85 {
    display as text "PASSED (agreement > 0.85)"
}
else {
    display as error "FAILED (agreement = `agreement', expected > 0.85)"
}

* ── Summary ────────────────────────────────────────────────────────
display as text ""
display as text "=================================="
display as text "Cross-validation complete"
display as text "  Regression correlation:      " as result %6.4f `reg_corr'
display as text "  Classification agreement:    " as result %6.4f `agreement'
display as text "=================================="
