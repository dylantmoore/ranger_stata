* test_basic.do -- Basic regression and classification tests for ranger
* Run from the project root directory

clear all
set more off

adopath ++ "."

* ── Test 1: Regression on auto.dta ─────────────────────────────────
display as text ""
display as text "=== Test 1: Regression on auto.dta ==="
display as text ""

sysuse auto, clear
ranger price mpg weight length, gen(pred_price) seed(42) ntrees(100)

* Save r() results immediately (before any other r-class command)
local t1_N = r(N)
local t1_ntrees = r(n_trees)
local t1_oob = r(oob_error)

assert `t1_N' > 0
assert `t1_ntrees' == 100
assert `t1_oob' > 0

* Check predictions exist
count if !missing(pred_price)
assert r(N) > 50

display as text "Test 1 PASSED: Regression predictions generated"

* ── Test 2: Regression with importance ─────────────────────────────
display as text ""
display as text "=== Test 2: Regression with impurity importance ==="
display as text ""

sysuse auto, clear
ranger price mpg weight length, gen(pred_price2) seed(42) ntrees(200) ///
    importance(impurity)

display as text "Test 2 PASSED: Importance computed"

* ── Test 3: Classification ─────────────────────────────────────────
display as text ""
display as text "=== Test 3: Classification on auto.dta ==="
display as text ""

sysuse auto, clear
ranger foreign mpg weight length, gen(pred_foreign) type(classification) ///
    seed(42) ntrees(100)

* Check predictions are 0 or 1
count if pred_foreign == 0 | pred_foreign == 1
local n_valid = r(N)
count if !missing(pred_foreign)
local n_pred = r(N)
assert `n_valid' == `n_pred'

display as text "Test 3 PASSED: Classification predictions are valid class labels"

* ── Test 4: Synthetic regression data ──────────────────────────────
display as text ""
display as text "=== Test 4: Synthetic data regression ==="
display as text ""

clear
set obs 500
set seed 42
gen x1 = rnormal()
gen x2 = rnormal()
gen x3 = rnormal()
gen y = 3*x1 + x2^2 + rnormal()*0.5

ranger y x1 x2 x3, gen(pred_y) seed(42) ntrees(500) importance(impurity)

local t4_oob = r(oob_error)
assert `t4_oob' < 5.0

display as text "OOB MSE: " as result `t4_oob'
display as text "Test 4 PASSED: Synthetic regression OOB MSE < 5.0"

* ── Test 5: Permutation importance ─────────────────────────────────
display as text ""
display as text "=== Test 5: Permutation importance ==="
display as text ""

clear
set obs 500
set seed 42
gen x1 = rnormal()
gen x2 = rnormal()
gen x3 = rnormal()
gen y = 3*x1 + x2^2 + rnormal()*0.5

ranger y x1 x2 x3, gen(pred_y5) seed(42) ntrees(200) importance(permutation)

display as text "Test 5 PASSED: Permutation importance computed"

* ── Summary ────────────────────────────────────────────────────────
display as text ""
display as text "=================================="
display as text "All basic tests PASSED"
display as text "=================================="
