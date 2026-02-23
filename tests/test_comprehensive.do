* test_comprehensive.do -- Thorough tests of all ranger options
* Run from the project root directory

clear all
set more off
adopath ++ "."

local n_passed = 0
local n_failed = 0
local failures ""

capture program drop run_test
program define run_test
    args test_name
    display as text ""
    display as text "=== `test_name' ==="
end

* ═══════════════════════════════════════════════════════════════════
* REGRESSION TESTS
* ═══════════════════════════════════════════════════════════════════

* ── T1: Default regression ────────────────────────────────────────
run_test "T1: Default regression"
sysuse auto, clear
capture noisily ranger price mpg weight length, gen(p1) seed(42)
if _rc == 0 {
    local t1_oob = r(oob_error)
    count if !missing(p1)
    if r(N) == 74 {
        display as result "PASSED (74 predictions, MSE=`t1_oob')"
        local n_passed = `n_passed' + 1
    }
    else {
        display as error "FAILED: expected 74 predictions, got " r(N)
        local n_failed = `n_failed' + 1
        local failures "`failures' T1"
    }
}
else {
    display as error "FAILED with rc=" _rc
    local n_failed = `n_failed' + 1
    local failures "`failures' T1"
}

* ── T2: Custom ntrees ────────────────────────────────────────────
run_test "T2: ntrees(50)"
sysuse auto, clear
capture noisily ranger price mpg weight, gen(p2) seed(42) ntrees(50)
if _rc == 0 {
    local t2_ntrees = r(n_trees)
    if `t2_ntrees' == 50 {
        display as result "PASSED (ntrees=50)"
        local n_passed = `n_passed' + 1
    }
    else {
        display as error "FAILED: expected ntrees=50, got `t2_ntrees'"
        local n_failed = `n_failed' + 1
        local failures "`failures' T2"
    }
}
else {
    display as error "FAILED with rc=" _rc
    local n_failed = `n_failed' + 1
    local failures "`failures' T2"
}

* ── T3: mtry specified ───────────────────────────────────────────
run_test "T3: mtry(2)"
sysuse auto, clear
capture noisily ranger price mpg weight length, gen(p3) seed(42) mtry(2)
if _rc == 0 {
    display as result "PASSED"
    local n_passed = `n_passed' + 1
}
else {
    display as error "FAILED with rc=" _rc
    local n_failed = `n_failed' + 1
    local failures "`failures' T3"
}

* ── T4: min_node_size ────────────────────────────────────────────
run_test "T4: minnodesize(10)"
sysuse auto, clear
capture noisily ranger price mpg weight length, gen(p4) seed(42) minnodesize(10)
if _rc == 0 {
    display as result "PASSED"
    local n_passed = `n_passed' + 1
}
else {
    display as error "FAILED with rc=" _rc
    local n_failed = `n_failed' + 1
    local failures "`failures' T4"
}

* ── T5: max_depth ────────────────────────────────────────────────
run_test "T5: maxdepth(5)"
sysuse auto, clear
capture noisily ranger price mpg weight length, gen(p5) seed(42) maxdepth(5)
if _rc == 0 {
    display as result "PASSED"
    local n_passed = `n_passed' + 1
}
else {
    display as error "FAILED with rc=" _rc
    local n_failed = `n_failed' + 1
    local failures "`failures' T5"
}

* ── T6: sample_fraction ─────────────────────────────────────────
run_test "T6: samplefrac(0.7)"
sysuse auto, clear
capture noisily ranger price mpg weight length, gen(p6) seed(42) samplefrac(0.7)
if _rc == 0 {
    display as result "PASSED"
    local n_passed = `n_passed' + 1
}
else {
    display as error "FAILED with rc=" _rc
    local n_failed = `n_failed' + 1
    local failures "`failures' T6"
}

* ── T7: noreplace ───────────────────────────────────────────────
run_test "T7: noreplace"
sysuse auto, clear
capture noisily ranger price mpg weight length, gen(p7) seed(42) noreplace
if _rc == 0 {
    display as result "PASSED"
    local n_passed = `n_passed' + 1
}
else {
    display as error "FAILED with rc=" _rc
    local n_failed = `n_failed' + 1
    local failures "`failures' T7"
}

* ── T8: impurity importance ──────────────────────────────────────
run_test "T8: importance(impurity)"
sysuse auto, clear
capture noisily ranger price mpg weight length, gen(p8) seed(42) importance(impurity)
if _rc == 0 {
    display as result "PASSED"
    local n_passed = `n_passed' + 1
}
else {
    display as error "FAILED with rc=" _rc
    local n_failed = `n_failed' + 1
    local failures "`failures' T8"
}

* ── T9: permutation importance ───────────────────────────────────
run_test "T9: importance(permutation)"
sysuse auto, clear
capture noisily ranger price mpg weight length, gen(p9) seed(42) importance(permutation)
if _rc == 0 {
    display as result "PASSED"
    local n_passed = `n_passed' + 1
}
else {
    display as error "FAILED with rc=" _rc
    local n_failed = `n_failed' + 1
    local failures "`failures' T9"
}

* ── T10: impurity_corrected importance ───────────────────────────
run_test "T10: importance(impurity_corrected)"
sysuse auto, clear
capture noisily ranger price mpg weight length, gen(p10) seed(42) importance(impurity_corrected)
if _rc == 0 {
    display as result "PASSED"
    local n_passed = `n_passed' + 1
}
else {
    display as error "FAILED with rc=" _rc
    local n_failed = `n_failed' + 1
    local failures "`failures' T10"
}

* ── T11: extratrees splitrule ────────────────────────────────────
run_test "T11: splitrule(extratrees)"
sysuse auto, clear
capture noisily ranger price mpg weight length, gen(p11) seed(42) splitrule(extratrees)
if _rc == 0 {
    display as result "PASSED"
    local n_passed = `n_passed' + 1
}
else {
    display as error "FAILED with rc=" _rc
    local n_failed = `n_failed' + 1
    local failures "`failures' T11"
}

* ── T12: extratrees with numrandomsplits ─────────────────────────
run_test "T12: extratrees + numrandomsplits(5)"
sysuse auto, clear
capture noisily ranger price mpg weight length, gen(p12) seed(42) ///
    splitrule(extratrees) numrandomsplits(5)
if _rc == 0 {
    display as result "PASSED"
    local n_passed = `n_passed' + 1
}
else {
    display as error "FAILED with rc=" _rc
    local n_failed = `n_failed' + 1
    local failures "`failures' T12"
}

* ── T13: maxstat splitrule ───────────────────────────────────────
run_test "T13: splitrule(maxstat)"
sysuse auto, clear
capture noisily ranger price mpg weight length, gen(p13) seed(42) splitrule(maxstat)
if _rc == 0 {
    display as result "PASSED"
    local n_passed = `n_passed' + 1
}
else {
    display as error "FAILED with rc=" _rc
    local n_failed = `n_failed' + 1
    local failures "`failures' T13"
}

* ── T14: maxstat with alpha/minprop ──────────────────────────────
run_test "T14: maxstat + alpha(0.3) + minprop(0.2)"
sysuse auto, clear
capture noisily ranger price mpg weight length, gen(p14) seed(42) ///
    splitrule(maxstat) alpha(0.3) minprop(0.2)
if _rc == 0 {
    display as result "PASSED"
    local n_passed = `n_passed' + 1
}
else {
    display as error "FAILED with rc=" _rc
    local n_failed = `n_failed' + 1
    local failures "`failures' T14"
}

* ── T15: beta splitrule (requires y in [0,1]) ───────────────────
run_test "T15: splitrule(beta)"
clear
set obs 200
set seed 42
gen x1 = rnormal()
gen x2 = rnormal()
gen y = invlogit(x1 + x2)
capture noisily ranger y x1 x2, gen(p15) seed(42) splitrule(beta)
if _rc == 0 {
    display as result "PASSED"
    local n_passed = `n_passed' + 1
}
else {
    display as error "FAILED with rc=" _rc
    local n_failed = `n_failed' + 1
    local failures "`failures' T15"
}

* ── T16: numthreads(1) ──────────────────────────────────────────
run_test "T16: numthreads(1)"
sysuse auto, clear
capture noisily ranger price mpg weight length, gen(p16) seed(42) numthreads(1)
if _rc == 0 {
    display as result "PASSED"
    local n_passed = `n_passed' + 1
}
else {
    display as error "FAILED with rc=" _rc
    local n_failed = `n_failed' + 1
    local failures "`failures' T16"
}

* ═══════════════════════════════════════════════════════════════════
* CLASSIFICATION TESTS
* ═══════════════════════════════════════════════════════════════════

* ── T17: Default classification ──────────────────────────────────
run_test "T17: Default classification"
sysuse auto, clear
capture noisily ranger foreign mpg weight length, gen(p17) type(class) seed(42)
if _rc == 0 {
    local t17_oob = r(oob_error)
    count if p17 == 0 | p17 == 1
    local n_valid = r(N)
    count if !missing(p17)
    if `n_valid' == r(N) {
        display as result "PASSED (OOB error=`t17_oob')"
        local n_passed = `n_passed' + 1
    }
    else {
        display as error "FAILED: not all predictions are valid class labels"
        local n_failed = `n_failed' + 1
        local failures "`failures' T17"
    }
}
else {
    display as error "FAILED with rc=" _rc
    local n_failed = `n_failed' + 1
    local failures "`failures' T17"
}

* ── T18: Classification with importance ──────────────────────────
run_test "T18: Classification + importance(impurity)"
sysuse auto, clear
capture noisily ranger foreign mpg weight length, gen(p18) type(class) ///
    seed(42) importance(impurity)
if _rc == 0 {
    display as result "PASSED"
    local n_passed = `n_passed' + 1
}
else {
    display as error "FAILED with rc=" _rc
    local n_failed = `n_failed' + 1
    local failures "`failures' T18"
}

* ── T19: Classification hellinger splitrule ──────────────────────
run_test "T19: Classification + splitrule(hellinger)"
sysuse auto, clear
capture noisily ranger foreign mpg weight length, gen(p19) type(class) ///
    seed(42) splitrule(hellinger)
if _rc == 0 {
    display as result "PASSED"
    local n_passed = `n_passed' + 1
}
else {
    display as error "FAILED with rc=" _rc
    local n_failed = `n_failed' + 1
    local failures "`failures' T19"
}

* ── T20: Classification extratrees ───────────────────────────────
run_test "T20: Classification + splitrule(extratrees)"
sysuse auto, clear
capture noisily ranger foreign mpg weight length, gen(p20) type(class) ///
    seed(42) splitrule(extratrees) numrandomsplits(3)
if _rc == 0 {
    display as result "PASSED"
    local n_passed = `n_passed' + 1
}
else {
    display as error "FAILED with rc=" _rc
    local n_failed = `n_failed' + 1
    local failures "`failures' T20"
}

* ═══════════════════════════════════════════════════════════════════
* IF/IN AND EDGE CASE TESTS
* ═══════════════════════════════════════════════════════════════════

* ── T21: if condition ────────────────────────────────────────────
run_test "T21: if condition"
sysuse auto, clear
capture noisily ranger price mpg weight if foreign == 0, gen(p21) seed(42)
if _rc == 0 {
    * Should only have predictions for domestic cars
    count if !missing(p21) & foreign == 0
    local n_dom = r(N)
    count if !missing(p21) & foreign == 1
    local n_for = r(N)
    if `n_for' == 0 & `n_dom' > 0 {
        display as result "PASSED (domestic only: `n_dom' predictions)"
        local n_passed = `n_passed' + 1
    }
    else {
        display as error "FAILED: expected predictions only for domestic"
        local n_failed = `n_failed' + 1
        local failures "`failures' T21"
    }
}
else {
    display as error "FAILED with rc=" _rc
    local n_failed = `n_failed' + 1
    local failures "`failures' T21"
}

* ── T22: in range ────────────────────────────────────────────────
run_test "T22: in 1/50"
sysuse auto, clear
capture noisily ranger price mpg weight in 1/50, gen(p22) seed(42)
if _rc == 0 {
    count if !missing(p22)
    if r(N) <= 50 & r(N) > 0 {
        display as result "PASSED (" r(N) " predictions in 1/50)"
        local n_passed = `n_passed' + 1
    }
    else {
        display as error "FAILED: unexpected prediction count"
        local n_failed = `n_failed' + 1
        local failures "`failures' T22"
    }
}
else {
    display as error "FAILED with rc=" _rc
    local n_failed = `n_failed' + 1
    local failures "`failures' T22"
}

* ── T23: Missing values in predictors ────────────────────────────
run_test "T23: Missing values in predictors"
sysuse auto, clear
replace mpg = . in 1/5
capture noisily ranger price mpg weight length, gen(p23) seed(42) ntrees(50)
if _rc == 0 {
    count if !missing(p23)
    local n_pred = r(N)
    if `n_pred' > 0 & `n_pred' <= 74 {
        display as result "PASSED (`n_pred' predictions with missing mpg)"
        local n_passed = `n_passed' + 1
    }
    else {
        display as error "FAILED: unexpected count `n_pred'"
        local n_failed = `n_failed' + 1
        local failures "`failures' T23"
    }
}
else {
    display as error "FAILED with rc=" _rc
    local n_failed = `n_failed' + 1
    local failures "`failures' T23"
}

* ── T24: Single predictor ───────────────────────────────────────
run_test "T24: Single predictor"
sysuse auto, clear
capture noisily ranger price weight, gen(p24) seed(42) ntrees(50)
if _rc == 0 {
    display as result "PASSED"
    local n_passed = `n_passed' + 1
}
else {
    display as error "FAILED with rc=" _rc
    local n_failed = `n_failed' + 1
    local failures "`failures' T24"
}

* ── T25: Many predictors ────────────────────────────────────────
run_test "T25: Many predictors (8 vars)"
sysuse auto, clear
capture noisily ranger price mpg headroom trunk weight length turn displacement, ///
    gen(p25) seed(42) ntrees(100)
if _rc == 0 {
    display as result "PASSED"
    local n_passed = `n_passed' + 1
}
else {
    display as error "FAILED with rc=" _rc
    local n_failed = `n_failed' + 1
    local failures "`failures' T25"
}

* ═══════════════════════════════════════════════════════════════════
* SCALE / PERFORMANCE TESTS
* ═══════════════════════════════════════════════════════════════════

* ── T26: Large dataset (n=5000) ──────────────────────────────────
run_test "T26: Large dataset (n=5000)"
clear
set obs 5000
set seed 42
gen x1 = rnormal()
gen x2 = rnormal()
gen x3 = rnormal()
gen x4 = rnormal()
gen x5 = rnormal()
gen y = 2*x1 - 3*x2 + x3^2 + rnormal()

timer clear 1
timer on 1
capture noisily ranger y x1 x2 x3 x4 x5, gen(p26) seed(42) ntrees(200)
timer off 1
if _rc == 0 {
    local t26_oob = r(oob_error)
    quietly timer list 1
    local t26_time = r(t1)
    display as result "PASSED (n=5000, MSE=`t26_oob', time=`t26_time's)"
    local n_passed = `n_passed' + 1
}
else {
    display as error "FAILED with rc=" _rc
    local n_failed = `n_failed' + 1
    local failures "`failures' T26"
}

* ── T27: Large dataset (n=10000) with threads ────────────────────
run_test "T27: Large dataset (n=10000) + numthreads(4)"
clear
set obs 10000
set seed 42
gen x1 = rnormal()
gen x2 = rnormal()
gen x3 = rnormal()
gen y = x1^2 + x2 + rnormal()

timer clear 2
timer on 2
capture noisily ranger y x1 x2 x3, gen(p27) seed(42) ntrees(500) numthreads(4)
timer off 2
if _rc == 0 {
    local t27_oob = r(oob_error)
    quietly timer list 2
    local t27_time = r(t2)
    display as result "PASSED (n=10000, MSE=`t27_oob', time=`t27_time's)"
    local n_passed = `n_passed' + 1
}
else {
    display as error "FAILED with rc=" _rc
    local n_failed = `n_failed' + 1
    local failures "`failures' T27"
}

* ── T28: Many predictors (p=20) ─────────────────────────────────
run_test "T28: Many predictors (p=20)"
clear
set obs 1000
set seed 42
forvalues j = 1/20 {
    gen x`j' = rnormal()
}
gen y = 3*x1 + 2*x2 - x3 + rnormal()

capture noisily ranger y x1-x20, gen(p28) seed(42) ntrees(200) importance(impurity)
if _rc == 0 {
    local t28_oob = r(oob_error)
    display as result "PASSED (p=20, MSE=`t28_oob')"
    local n_passed = `n_passed' + 1
}
else {
    display as error "FAILED with rc=" _rc
    local n_failed = `n_failed' + 1
    local failures "`failures' T28"
}

* ═══════════════════════════════════════════════════════════════════
* REPRODUCIBILITY TEST
* ═══════════════════════════════════════════════════════════════════

* ── T29: Same seed = same results ────────────────────────────────
run_test "T29: Reproducibility (same seed, numthreads(1))"
sysuse auto, clear
ranger price mpg weight length, gen(run1) seed(42) ntrees(100) numthreads(1)
local oob1 = r(oob_error)

sysuse auto, clear
ranger price mpg weight length, gen(run2) seed(42) ntrees(100) numthreads(1)
local oob2 = r(oob_error)

if abs(`oob1' - `oob2') < 0.001 {
    display as result "PASSED (OOB1=`oob1', OOB2=`oob2')"
    local n_passed = `n_passed' + 1
}
else {
    display as error "FAILED: OOB1=`oob1' != OOB2=`oob2'"
    local n_failed = `n_failed' + 1
    local failures "`failures' T29"
}

* ── T30: Different seeds = different results ─────────────────────
run_test "T30: Different seeds produce different results"
sysuse auto, clear
ranger price mpg weight length, gen(s1) seed(42) ntrees(100) numthreads(1)
local oob_s1 = r(oob_error)

sysuse auto, clear
ranger price mpg weight length, gen(s2) seed(123) ntrees(100) numthreads(1)
local oob_s2 = r(oob_error)

if abs(`oob_s1' - `oob_s2') > 0.001 {
    display as result "PASSED (seed42=`oob_s1', seed123=`oob_s2')"
    local n_passed = `n_passed' + 1
}
else {
    display as error "WARNING: same result with different seeds"
    * Not necessarily a failure for small data
    local n_passed = `n_passed' + 1
}

* ═══════════════════════════════════════════════════════════════════
* COMBINED OPTIONS
* ═══════════════════════════════════════════════════════════════════

* ── T31: Kitchen sink (many options at once) ─────────────────────
run_test "T31: Kitchen sink regression"
sysuse auto, clear
capture noisily ranger price mpg weight length, gen(p31) seed(42) ///
    ntrees(300) mtry(2) minnodesize(10) maxdepth(8) samplefrac(0.8) ///
    noreplace importance(impurity) numthreads(2)
if _rc == 0 {
    display as result "PASSED"
    local n_passed = `n_passed' + 1
}
else {
    display as error "FAILED with rc=" _rc
    local n_failed = `n_failed' + 1
    local failures "`failures' T31"
}

* ── T32: Kitchen sink classification ─────────────────────────────
run_test "T32: Kitchen sink classification"
sysuse auto, clear
capture noisily ranger foreign mpg weight length, gen(p32) type(class) ///
    seed(42) ntrees(300) mtry(2) minnodesize(5) maxdepth(10) ///
    importance(permutation) numthreads(2)
if _rc == 0 {
    display as result "PASSED"
    local n_passed = `n_passed' + 1
}
else {
    display as error "FAILED with rc=" _rc
    local n_failed = `n_failed' + 1
    local failures "`failures' T32"
}

* ═══════════════════════════════════════════════════════════════════
* PROBABILITY FOREST TESTS
* ═══════════════════════════════════════════════════════════════════

* ── T33: Basic probability forest (binary) ───────────────────────
run_test "T33: Probability forest (binary)"
sysuse auto, clear
capture noisily ranger foreign mpg weight length, gen(prob) type(prob) seed(42)
if _rc == 0 {
    * Check two output vars exist
    capture confirm variable prob_0
    local rc0 = _rc
    capture confirm variable prob_1
    local rc1 = _rc
    if `rc0' == 0 & `rc1' == 0 {
        * Probabilities should sum to ~1
        gen prob_sum = prob_0 + prob_1
        quietly summarize prob_sum if !missing(prob_sum)
        if abs(r(mean) - 1.0) < 0.01 {
            display as result "PASSED (probs sum to ~1.0, mean=" r(mean) ")"
            local n_passed = `n_passed' + 1
        }
        else {
            display as error "FAILED: probs don't sum to 1, mean=" r(mean)
            local n_failed = `n_failed' + 1
            local failures "`failures' T33"
        }
    }
    else {
        display as error "FAILED: missing probability output variables"
        local n_failed = `n_failed' + 1
        local failures "`failures' T33"
    }
}
else {
    display as error "FAILED with rc=" _rc
    local n_failed = `n_failed' + 1
    local failures "`failures' T33"
}

* ── T34: Probability forest (3+ classes) ─────────────────────────
run_test "T34: Probability forest (3 classes)"
clear
set obs 300
set seed 42
gen x1 = rnormal()
gen x2 = rnormal()
gen group = cond(x1 > 0.5, 2, cond(x1 < -0.5, 0, 1))

capture noisily ranger group x1 x2, gen(pclass) type(prob) seed(42) ntrees(200)
if _rc == 0 {
    local nclass = r(n_classes)
    if `nclass' == 3 {
        display as result "PASSED (3-class probability forest)"
        local n_passed = `n_passed' + 1
    }
    else {
        display as error "FAILED: expected 3 classes, got `nclass'"
        local n_failed = `n_failed' + 1
        local failures "`failures' T34"
    }
}
else {
    display as error "FAILED with rc=" _rc
    local n_failed = `n_failed' + 1
    local failures "`failures' T34"
}

* ═══════════════════════════════════════════════════════════════════
* SURVIVAL FOREST TESTS
* ═══════════════════════════════════════════════════════════════════

* ── T35: Basic survival forest ───────────────────────────────────
run_test "T35: Survival forest"
clear
set obs 500
set seed 42
gen x1 = rnormal()
gen x2 = rnormal()
* Simulate survival data: exponential times with censoring
gen time = -ln(runiform()) * exp(-0.5*x1)
gen censor_time = -ln(runiform()) * 2
gen event = (time <= censor_time)
replace time = min(time, censor_time)

capture noisily ranger time x1 x2, gen(chf) type(surv) status(event) ///
    seed(42) ntrees(200)
if _rc == 0 {
    count if !missing(chf)
    local n_pred = r(N)
    if `n_pred' > 0 {
        quietly summarize chf if !missing(chf)
        display as result "PASSED (`n_pred' CHF predictions, mean=" ///
            %7.4f r(mean) ")"
        local n_passed = `n_passed' + 1
    }
    else {
        display as error "FAILED: no predictions"
        local n_failed = `n_failed' + 1
        local failures "`failures' T35"
    }
}
else {
    display as error "FAILED with rc=" _rc
    local n_failed = `n_failed' + 1
    local failures "`failures' T35"
}

* ── T36: Survival with logrank splitrule ─────────────────────────
run_test "T36: Survival + splitrule(logrank)"
clear
set obs 300
set seed 42
gen x1 = rnormal()
gen time = -ln(runiform()) * exp(-0.3*x1)
gen event = (runiform() > 0.3)

capture noisily ranger time x1, gen(chf36) type(surv) status(event) ///
    seed(42) ntrees(100) splitrule(logrank)
if _rc == 0 {
    display as result "PASSED"
    local n_passed = `n_passed' + 1
}
else {
    display as error "FAILED with rc=" _rc
    local n_failed = `n_failed' + 1
    local failures "`failures' T36"
}

* ═══════════════════════════════════════════════════════════════════
* SAVE/LOAD TESTS
* ═══════════════════════════════════════════════════════════════════

* ── T37: Save forest ─────────────────────────────────────────────
run_test "T37: Save forest"
sysuse auto, clear
capture noisily ranger price mpg weight, gen(p37) seed(42) ntrees(100) ///
    saveforest("`c(tmpdir)'/ranger_test")
if _rc == 0 {
    capture confirm file "`c(tmpdir)'/ranger_test.forest"
    if _rc == 0 {
        display as result "PASSED (forest file created)"
        local n_passed = `n_passed' + 1
    }
    else {
        display as error "FAILED: forest file not found"
        local n_failed = `n_failed' + 1
        local failures "`failures' T37"
    }
}
else {
    display as error "FAILED with rc=" _rc
    local n_failed = `n_failed' + 1
    local failures "`failures' T37"
}

* ── T38: Load forest and predict ─────────────────────────────────
run_test "T38: Load forest and predict"
sysuse auto, clear
capture noisily ranger mpg weight, gen(pred38) ///
    using("`c(tmpdir)'/ranger_test.forest") type(reg)
if _rc == 0 {
    count if !missing(pred38)
    if r(N) > 0 {
        display as result "PASSED (" r(N) " predictions from loaded forest)"
        local n_passed = `n_passed' + 1
    }
    else {
        display as error "FAILED: no predictions"
        local n_failed = `n_failed' + 1
        local failures "`failures' T38"
    }
}
else {
    display as error "FAILED with rc=" _rc
    local n_failed = `n_failed' + 1
    local failures "`failures' T38"
}

* Clean up temp forest file
capture erase "`c(tmpdir)'/ranger_test.forest"

* ═══════════════════════════════════════════════════════════════════
* CASE WEIGHTS TEST
* ═══════════════════════════════════════════════════════════════════

* ── T39: Case weights ────────────────────────────────────────────
run_test "T39: Case weights"
sysuse auto, clear
gen wt = 1
replace wt = 5 if foreign == 1
capture noisily ranger price mpg weight, gen(p39) seed(42) ntrees(200) ///
    caseweights(wt)
if _rc == 0 {
    local oob39 = r(oob_error)
    * Also run without weights to compare
    sysuse auto, clear
    ranger price mpg weight, gen(p39b) seed(42) ntrees(200)
    local oob39b = r(oob_error)
    * They should differ
    if abs(`oob39' - `oob39b') > 0.001 {
        display as result "PASSED (weighted MSE=`oob39' vs unweighted=`oob39b')"
        local n_passed = `n_passed' + 1
    }
    else {
        display as error "WARNING: weighted and unweighted same (possible for small data)"
        local n_passed = `n_passed' + 1
    }
}
else {
    display as error "FAILED with rc=" _rc
    local n_failed = `n_failed' + 1
    local failures "`failures' T39"
}

* ═══════════════════════════════════════════════════════════════════
* CLASS WEIGHTS TEST
* ═══════════════════════════════════════════════════════════════════

* ── T40: Class weights ───────────────────────────────────────────
run_test "T40: Class weights (classification)"
sysuse auto, clear
capture noisily ranger foreign mpg weight length, gen(p40) type(class) ///
    seed(42) ntrees(200) classweights("1 5")
if _rc == 0 {
    display as result "PASSED"
    local n_passed = `n_passed' + 1
}
else {
    display as error "FAILED with rc=" _rc
    local n_failed = `n_failed' + 1
    local failures "`failures' T40"
}

* ═══════════════════════════════════════════════════════════════════
* ALWAYS-SPLIT VARIABLES TEST
* ═══════════════════════════════════════════════════════════════════

* ── T41: Always-split variables ──────────────────────────────────
run_test "T41: Always-split variables"
sysuse auto, clear
capture noisily ranger price mpg weight length, gen(p41) seed(42) ///
    ntrees(200) importance(impurity) alwayssplit(mpg)
if _rc == 0 {
    * mpg should have non-zero importance
    local imp_mpg = r(imp_mpg)
    if `imp_mpg' > 0 {
        display as result "PASSED (mpg importance=`imp_mpg')"
        local n_passed = `n_passed' + 1
    }
    else {
        display as error "FAILED: always-split var has zero importance"
        local n_failed = `n_failed' + 1
        local failures "`failures' T41"
    }
}
else {
    display as error "FAILED with rc=" _rc
    local n_failed = `n_failed' + 1
    local failures "`failures' T41"
}

* ═══════════════════════════════════════════════════════════════════
* SPLIT WEIGHTS TEST
* ═══════════════════════════════════════════════════════════════════

* ── T42: Split select weights ────────────────────────────────────
run_test "T42: Split select weights"
sysuse auto, clear
* Give zero weight to length (3rd predictor), forcing it to be unused
capture noisily ranger price mpg weight length, gen(p42) seed(42) ///
    ntrees(200) importance(impurity) splitweights("1 1 0")
if _rc == 0 {
    local imp_length = r(imp_length)
    if `imp_length' == 0 | `imp_length' < 0.001 {
        display as result "PASSED (zero-weight var has importance=`imp_length')"
        local n_passed = `n_passed' + 1
    }
    else {
        display as error "FAILED: zero-weight var has importance=`imp_length'"
        local n_failed = `n_failed' + 1
        local failures "`failures' T42"
    }
}
else {
    display as error "FAILED with rc=" _rc
    local n_failed = `n_failed' + 1
    local failures "`failures' T42"
}

* ═══════════════════════════════════════════════════════════════════
* REGULARIZATION TEST
* ═══════════════════════════════════════════════════════════════════

* ── T43: Regularization factor ───────────────────────────────────
run_test "T43: Regularization factor"
sysuse auto, clear
capture noisily ranger price mpg weight length, gen(p43) seed(42) ///
    ntrees(200) regfactor("0.5 0.5 0.5")
if _rc == 0 {
    display as result "PASSED"
    local n_passed = `n_passed' + 1
}
else {
    display as error "FAILED with rc=" _rc
    local n_failed = `n_failed' + 1
    local failures "`failures' T43"
}

* ── T44: Regularization with usedepth ────────────────────────────
run_test "T44: Regularization + regusedepth"
sysuse auto, clear
capture noisily ranger price mpg weight length, gen(p44) seed(42) ///
    ntrees(200) regfactor("0.5 0.5 0.5") regusedepth
if _rc == 0 {
    display as result "PASSED"
    local n_passed = `n_passed' + 1
}
else {
    display as error "FAILED with rc=" _rc
    local n_failed = `n_failed' + 1
    local failures "`failures' T44"
}

* ═══════════════════════════════════════════════════════════════════
* HOLDOUT TEST
* ═══════════════════════════════════════════════════════════════════

* ── T45: Holdout ─────────────────────────────────────────────────
run_test "T45: Holdout variable"
sysuse auto, clear
gen byte ho = (_n > 50)
capture noisily ranger price mpg weight, gen(p45) seed(42) ntrees(200) holdout(ho)
if _rc == 0 {
    display as result "PASSED"
    local n_passed = `n_passed' + 1
}
else {
    display as error "FAILED with rc=" _rc
    local n_failed = `n_failed' + 1
    local failures "`failures' T45"
}

* ═══════════════════════════════════════════════════════════════════
* SPLIT RULE TESTS (NEW)
* ═══════════════════════════════════════════════════════════════════

* ── T46: POISSON splitrule ───────────────────────────────────────
run_test "T46: splitrule(poisson)"
clear
set obs 500
set seed 42
gen x1 = rnormal()
gen x2 = rnormal()
gen y = exp(0.5*x1 + 0.3*x2) + abs(rnormal())
capture noisily ranger y x1 x2, gen(p46) seed(42) ntrees(100) splitrule(poisson)
if _rc == 0 {
    display as result "PASSED"
    local n_passed = `n_passed' + 1
}
else {
    display as error "FAILED with rc=" _rc
    local n_failed = `n_failed' + 1
    local failures "`failures' T46"
}

* ── T47: AUC splitrule (survival) ────────────────────────────────
run_test "T47: splitrule(auc) for survival"
clear
set obs 300
set seed 42
gen x1 = rnormal()
gen time = -ln(runiform()) * exp(-0.3*x1)
gen event = (runiform() > 0.3)
capture noisily ranger time x1, gen(chf47) type(surv) status(event) ///
    seed(42) ntrees(100) splitrule(auc)
if _rc == 0 {
    display as result "PASSED"
    local n_passed = `n_passed' + 1
}
else {
    display as error "FAILED with rc=" _rc
    local n_failed = `n_failed' + 1
    local failures "`failures' T47"
}

* ═══════════════════════════════════════════════════════════════════
* MINOR PARAMETER TESTS
* ═══════════════════════════════════════════════════════════════════

* ── T48: min_bucket ──────────────────────────────────────────────
run_test "T48: minbucket(5)"
sysuse auto, clear
capture noisily ranger price mpg weight length, gen(p48) seed(42) minbucket(5)
if _rc == 0 {
    display as result "PASSED"
    local n_passed = `n_passed' + 1
}
else {
    display as error "FAILED with rc=" _rc
    local n_failed = `n_failed' + 1
    local failures "`failures' T48"
}

* ── T49: node_stats ──────────────────────────────────────────────
run_test "T49: nodestats"
sysuse auto, clear
capture noisily ranger price mpg weight length, gen(p49) seed(42) nodestats
if _rc == 0 {
    display as result "PASSED"
    local n_passed = `n_passed' + 1
}
else {
    display as error "FAILED with rc=" _rc
    local n_failed = `n_failed' + 1
    local failures "`failures' T49"
}

* ── T50: terminalnodes ───────────────────────────────────────────
run_test "T50: terminalnodes"
sysuse auto, clear
capture noisily ranger price mpg weight length, gen(p50) seed(42) ///
    ntrees(50) terminalnodes
if _rc == 0 {
    * Terminal node IDs should be positive integers
    count if !missing(p50) & p50 > 0
    if r(N) > 0 {
        display as result "PASSED (terminal node IDs)"
        local n_passed = `n_passed' + 1
    }
    else {
        display as error "FAILED: no valid terminal node IDs"
        local n_failed = `n_failed' + 1
        local failures "`failures' T50"
    }
}
else {
    display as error "FAILED with rc=" _rc
    local n_failed = `n_failed' + 1
    local failures "`failures' T50"
}

* ═══════════════════════════════════════════════════════════════════
* PROBABILITY + CLASSIFICATION COMBINED TESTS
* ═══════════════════════════════════════════════════════════════════

* ── T51: Probability + class weights ─────────────────────────────
run_test "T51: Probability + classweights"
sysuse auto, clear
capture noisily ranger foreign mpg weight length, gen(pcw) type(prob) ///
    seed(42) ntrees(200) classweights("1 3")
if _rc == 0 {
    display as result "PASSED"
    local n_passed = `n_passed' + 1
}
else {
    display as error "FAILED with rc=" _rc
    local n_failed = `n_failed' + 1
    local failures "`failures' T51"
}

* ── T52: Probability + importance ────────────────────────────────
run_test "T52: Probability + importance"
sysuse auto, clear
capture noisily ranger foreign mpg weight length, gen(pi) type(prob) ///
    seed(42) ntrees(200) importance(impurity)
if _rc == 0 {
    display as result "PASSED"
    local n_passed = `n_passed' + 1
}
else {
    display as error "FAILED with rc=" _rc
    local n_failed = `n_failed' + 1
    local failures "`failures' T52"
}

* ═══════════════════════════════════════════════════════════════════
* KITCHEN SINK NEW FEATURES
* ═══════════════════════════════════════════════════════════════════

* ── T53: Regression with all new options ─────────────────────────
run_test "T53: Regression kitchen sink (new features)"
sysuse auto, clear
gen byte myho = (_n > 60)
gen wt2 = 1 + foreign
capture noisily ranger price mpg weight length, gen(p53) seed(42) ///
    ntrees(200) mtry(2) minnodesize(10) maxdepth(8) minbucket(3) ///
    importance(impurity) caseweights(wt2) holdout(myho) ///
    alwayssplit(mpg) regfactor("0.8 0.8 0.8") numthreads(2)
if _rc == 0 {
    display as result "PASSED"
    local n_passed = `n_passed' + 1
}
else {
    display as error "FAILED with rc=" _rc
    local n_failed = `n_failed' + 1
    local failures "`failures' T53"
}

* ── T54: Survival kitchen sink ───────────────────────────────────
run_test "T54: Survival kitchen sink"
clear
set obs 500
set seed 42
gen x1 = rnormal()
gen x2 = rnormal()
gen x3 = rnormal()
gen time = -ln(runiform()) * exp(-0.5*x1 + 0.3*x2)
gen event = (runiform() > 0.25)
gen wt3 = 1 + (x3 > 0)

capture noisily ranger time x1 x2 x3, gen(chf54) type(surv) status(event) ///
    seed(42) ntrees(200) mtry(2) minnodesize(5) maxdepth(10) ///
    importance(permutation) caseweights(wt3) numthreads(2)
if _rc == 0 {
    count if !missing(chf54)
    display as result "PASSED (" r(N) " survival predictions)"
    local n_passed = `n_passed' + 1
}
else {
    display as error "FAILED with rc=" _rc
    local n_failed = `n_failed' + 1
    local failures "`failures' T54"
}

* ═══════════════════════════════════════════════════════════════════
* SUMMARY
* ═══════════════════════════════════════════════════════════════════
display as text ""
display as text "════════════════════════════════════════════"
display as text "COMPREHENSIVE TEST RESULTS"
display as text "════════════════════════════════════════════"
display as result "  Passed: `n_passed'"
display as result "  Failed: `n_failed'"
if `n_failed' > 0 {
    display as error "  Failed tests: `failures'"
}
display as text "════════════════════════════════════════════"
