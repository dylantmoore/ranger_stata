*! ranger.ado -- Random Forests for Stata via ranger C++ library
*! Version 0.2.0
*! Supports regression, classification, probability, and survival forests
*! Wraps Wright & Ziegler (2017) ranger

program define ranger, rclass
    version 14.0

    syntax varlist(min=1 numeric) [if] [in],   ///
        GENerate(string)                        ///
        [                                       ///
            TYPE(string)                        ///
            NTrees(integer 500)                 ///
            SEED(integer 42)                    ///
            MTRY(integer 0)                     ///
            MINNodesize(integer 0)              ///
            MAXDepth(integer 0)                 ///
            SAMPLEfrac(real 0)                  ///
            REPlace                             ///
            NOREPlace                           ///
            IMPortance(string)                  ///
            SPLITrule(string)                   ///
            NUMThreads(integer 0)               ///
            ALPha(real 0.5)                     ///
            MINProp(real 0.1)                   ///
            NUMRandomsplits(integer 1)          ///
            STATUS(varname)                     ///
            CASEWeights(varname)                ///
            CLASSWeights(string)                ///
            HOLDout(varname)                    ///
            ALWAYSSplit(varlist)                ///
            SPLITWeights(string)                ///
            REGfactor(string)                   ///
            REGusedepth                         ///
            MINBucket(integer 0)                ///
            NODEstats                           ///
            TERMINALnodes                       ///
            POISSONtau(real 1)                  ///
            SAVEforest(string)                  ///
            USing(string)                       ///
            NCLasses(integer 0)                 ///
        ]

    /* ---- Parse type ---- */
    local type_code 0
    local type_label "regression"
    if `"`type'"' == "" | `"`type'"' == "regression" | `"`type'"' == "reg" {
        local type_code 0
        local type_label "regression"
    }
    else if `"`type'"' == "classification" | `"`type'"' == "class" {
        local type_code 1
        local type_label "classification"
    }
    else if `"`type'"' == "probability" | `"`type'"' == "prob" {
        local type_code 2
        local type_label "probability"
    }
    else if `"`type'"' == "survival" | `"`type'"' == "surv" {
        local type_code 3
        local type_label "survival"
    }
    else {
        display as error ///
            `"type(`type') not supported; use regression, classification, probability, or survival"'
        exit 198
    }

    /* ---- Detect predict mode ---- */
    local is_predict 0
    local load_path ""
    if `"`using'"' != "" {
        local is_predict 1
        local load_path `"`using'"'
    }

    /* ---- Parse replace/noreplace ---- */
    local do_replace 1
    if "`noreplace'" != "" {
        local do_replace 0
    }
    if "`replace'" != "" {
        local do_replace 1
    }

    /* ---- Parse importance ---- */
    local imp_code 0
    if `"`importance'"' == "" | `"`importance'"' == "none" {
        local imp_code 0
    }
    else if `"`importance'"' == "impurity" {
        local imp_code 1
    }
    else if `"`importance'"' == "permutation" {
        local imp_code 2
    }
    else if `"`importance'"' == "impurity_corrected" {
        local imp_code 5
    }
    else {
        display as error `"importance(`importance') not supported"'
        display as error "  use: none, impurity, permutation, or impurity_corrected"
        exit 198
    }

    /* ---- Parse splitrule ---- */
    local split_code 0
    if `"`splitrule'"' == "" | `"`splitrule'"' == "variance" | `"`splitrule'"' == "gini" {
        local split_code 0
    }
    else if `"`splitrule'"' == "logrank" {
        local split_code 1
    }
    else if `"`splitrule'"' == "auc" {
        local split_code 2
    }
    else if `"`splitrule'"' == "auc_ignore_ties" {
        local split_code 3
    }
    else if `"`splitrule'"' == "maxstat" {
        local split_code 4
    }
    else if `"`splitrule'"' == "extratrees" {
        local split_code 5
    }
    else if `"`splitrule'"' == "beta" {
        local split_code 6
    }
    else if `"`splitrule'"' == "hellinger" {
        local split_code 7
    }
    else if `"`splitrule'"' == "poisson" {
        local split_code 8
    }
    else {
        display as error `"splitrule(`splitrule') not supported"'
        exit 198
    }

    /* ---- Parse prediction_type ---- */
    local pred_type_code 1
    if "`terminalnodes'" != "" {
        local pred_type_code 2
    }

    /* ---- Parse flags ---- */
    local holdout_code 0
    if `"`holdout'"' != "" {
        local holdout_code 1
    }

    local nodestats_code 0
    if "`nodestats'" != "" {
        local nodestats_code 1
    }

    local regusedepth_code 0
    if "`regusedepth'" != "" {
        local regusedepth_code 1
    }

    /* ---- Parse varlist for predict vs train ---- */
    local n_dep_vars 1
    local n_extra_vars 0

    if `is_predict' == 1 {
        /* Predict mode: varlist = predictors only, n_dep_vars = 0 */
        local n_dep_vars 0
        local indepvars "`varlist'"
        local depvar ""
    }
    else {
        /* Training mode */
        if `type_code' == 3 {
            /* Survival: first var = time, status() is required */
            if `"`status'"' == "" {
                display as error "survival forests require the status() option"
                exit 198
            }
            gettoken depvar indepvars : varlist
            local n_dep_vars 2
        }
        else {
            gettoken depvar indepvars : varlist
            local n_dep_vars 1
        }
    }

    local nindep : word count `indepvars'
    if `nindep' < 1 {
        display as error "need at least 1 predictor variable"
        exit 198
    }

    /* ---- Determine output variable count (K) ---- */
    local n_output_vars 1

    if `type_code' == 2 {
        /* Probability forest: K = number of classes */
        if `is_predict' == 1 {
            /* Must specify nclasses() in predict mode */
            if `nclasses' <= 0 {
                display as error ///
                    "probability predict mode requires nclasses() option"
                exit 198
            }
            local n_output_vars `nclasses'
        }
        else {
            /* Training: count distinct values of depvar */
            marksample touse_temp
            quietly levelsof `depvar' if `touse_temp', local(class_levels)
            local n_output_vars : word count `class_levels'
            if `n_output_vars' < 2 {
                display as error ///
                    "probability forest requires at least 2 classes in `depvar'"
                exit 198
            }
        }
    }

    /* ---- Count extra variables (case_weights + holdout) ---- */
    local extra_vars ""
    if `"`caseweights'"' != "" {
        local n_extra_vars = `n_extra_vars' + 1
        local extra_vars "`extra_vars' `caseweights'"
    }
    if `"`holdout'"' != "" {
        local n_extra_vars = `n_extra_vars' + 1
        local extra_vars "`extra_vars' `holdout'"
    }

    /* ---- Mark sample ---- */
    marksample touse
    quietly count if `touse'
    local n_use = r(N)

    if `n_use' < 2 {
        display as error "need at least 2 non-missing observations"
        exit 2000
    }

    /* ---- Create output variable(s) ---- */
    if `n_output_vars' == 1 {
        confirm new variable `generate'
        quietly gen double `generate' = .
        local output_varlist "`generate'"
    }
    else {
        /* Multiple output vars for probability forest */
        local output_varlist ""
        if `is_predict' == 1 {
            /* In predict mode, name them generate_1 ... generate_K */
            forvalues k = 1/`n_output_vars' {
                local vname "`generate'_`k'"
                confirm new variable `vname'
                quietly gen double `vname' = .
                local output_varlist "`output_varlist' `vname'"
            }
        }
        else {
            /* Training: name them generate_classval */
            local k = 1
            foreach lev of local class_levels {
                local lev_clean = subinstr("`lev'", ".", "_", .)
                local lev_clean = subinstr("`lev_clean'", "-", "n", .)
                local vname "`generate'_`lev_clean'"
                capture confirm new variable `vname'
                if _rc {
                    local vname "`generate'_`k'"
                    confirm new variable `vname'
                }
                quietly gen double `vname' = .
                local output_varlist "`output_varlist' `vname'"
                local k = `k' + 1
            }
        }
    }

    /* ---- Build always_split_names string ---- */
    local always_split_str ""
    if `"`alwayssplit'"' != "" {
        /* Map Stata varnames to x1, x2, ... positions */
        foreach asvar of local alwayssplit {
            local pos = 0
            local j = 1
            foreach iv of local indepvars {
                if "`iv'" == "`asvar'" {
                    local pos = `j'
                }
                local j = `j' + 1
            }
            if `pos' > 0 {
                if `"`always_split_str'"' != "" {
                    local always_split_str "`always_split_str' x`pos'"
                }
                else {
                    local always_split_str "x`pos'"
                }
            }
            else {
                display as error "`asvar' not found in predictor list"
                exit 198
            }
        }
    }

    /* ---- Display header ---- */
    display as text ""
    if `is_predict' == 1 {
        display as text "Random Forest (predict: `type_label')"
    }
    else {
        display as text "Random Forest (`type_label')"
    }
    display as text "{hline 50}"
    if "`depvar'" != "" {
        display as text "Dependent variable:  " as result "`depvar'"
    }
    if `type_code' == 3 & "`status'" != "" {
        display as text "Status variable:     " as result "`status'"
    }
    display as text "Predictors:          " as result "`indepvars'"
    display as text "Observations:        " as result `n_use'
    if `is_predict' != 1 {
        display as text "Trees:               " as result `ntrees'
    }
    if `imp_code' > 0 & `is_predict' != 1 {
        display as text "Importance:          " as result "`importance'"
    }
    if `n_output_vars' > 1 {
        display as text "Classes (K):         " as result `n_output_vars'
    }
    display as text "{hline 50}"
    display as text ""

    /* ---- Load plugin (gtools-style platform detection) ---- */
    if ( inlist("`c(os)'", "MacOSX") | strpos("`c(machine_type)'", "Mac") ) local c_os_ macosx
    else local c_os_: di lower("`c(os)'")

    cap program drop ranger_plugin
    program ranger_plugin, plugin using("ranger_plugin_`c_os_'.plugin")

    /* ---- Build variable list for plugin call ---- */
    /* Layout: [depvar [statusvar]] indepvars [caseweights] [holdout] output_vars */
    local plugin_varlist ""

    if `is_predict' == 0 {
        local plugin_varlist "`depvar'"
        if `type_code' == 3 {
            local plugin_varlist "`plugin_varlist' `status'"
        }
    }

    local plugin_varlist "`plugin_varlist' `indepvars'"

    if `"`extra_vars'"' != "" {
        local plugin_varlist "`plugin_varlist' `extra_vars'"
    }

    local plugin_varlist "`plugin_varlist' `output_varlist'"

    /* ---- Save path handling ---- */
    local save_path_str ""
    if `"`saveforest'"' != "" {
        local save_path_str `"`saveforest'"'
    }

    /* ---- Call plugin (30 args) ---- */
    plugin call ranger_plugin `plugin_varlist' ///
        if `touse',                            ///
        "`ntrees'"                             ///
        "`seed'"                               ///
        "`mtry'"                               ///
        "`minnodesize'"                        ///
        "`maxdepth'"                           ///
        "`samplefrac'"                         ///
        "`do_replace'"                         ///
        "`imp_code'"                           ///
        "`split_code'"                         ///
        "`type_code'"                          ///
        "`numthreads'"                         ///
        "`alpha'"                              ///
        "`minprop'"                            ///
        "`numrandomsplits'"                    ///
        "`is_predict'"                         ///
        "`pred_type_code'"                     ///
        "`holdout_code'"                       ///
        "`nodestats_code'"                     ///
        "`regusedepth_code'"                   ///
        "`poissontau'"                         ///
        "`minbucket'"                          ///
        "`n_dep_vars'"                         ///
        "`n_output_vars'"                      ///
        "`n_extra_vars'"                       ///
        `"`save_path_str'"'                    ///
        `"`load_path'"'                        ///
        `"`always_split_str'"'                 ///
        `"`splitweights'"'                     ///
        `"`regfactor'"'                        ///
        `"`classweights'"'

    /* ---- Store r() results ---- */
    return scalar N          = `n_use'
    return scalar n_trees    = `ntrees'
    return scalar seed       = `seed'
    return scalar mtry       = `mtry'
    return local  type         "`type_label'"
    return local  depvar       "`depvar'"
    return local  indepvars    "`indepvars'"
    return local  generate     "`generate'"

    if `is_predict' == 0 {
        /* Retrieve OOB error */
        local oob_error = scalar(__ranger_oob_error)
        return scalar oob_error  = `oob_error'
    }

    if `type_code' == 2 {
        return scalar n_classes = `n_output_vars'
    }

    /* ---- Display variable importance if computed ---- */
    if `imp_code' > 0 & `is_predict' == 0 {
        capture local nimp = scalar(__ranger_nimp)
        if _rc == 0 & `nimp' > 0 {
            local imp_vals "${ranger_importance_vals}"

            display as text ""
            display as text "Variable Importance"
            display as text "{hline 40}"

            tokenize "`imp_vals'"
            local j = 1
            foreach v of local indepvars {
                if "``j''" != "" {
                    local imp_j = real("``j''")
                    display as text %20s "`v'" "  " as result %12.6f `imp_j'
                    return scalar imp_`v' = `imp_j'
                }
                local j = `j' + 1
            }
            display as text "{hline 40}"
        }
    }

    /* ---- Summary stats for predictions ---- */
    if `n_output_vars' == 1 {
        quietly summarize `generate' if `touse'
        local n_pred = r(N)
        local pred_mean = r(mean)
        local pred_sd = r(sd)

        display as text ""
        display as text "Predictions written to: " as result "`generate'"
        display as text "  Non-missing:  " as result `n_pred'
        display as text "  Mean:         " as result %9.4f `pred_mean'
        display as text "  SD:           " as result %9.4f `pred_sd'

        if `is_predict' == 0 {
            if `type_code' == 0 {
                display as text "  OOB MSE:      " as result %9.6f `oob_error'
            }
            else if `type_code' == 3 {
                /* Survival: display C-index */
                display as text "  OOB C-index:  " as result %9.6f `oob_error'
            }
            else {
                display as text "  OOB Error:    " as result %9.6f `oob_error'
            }
        }
    }
    else {
        /* Probability: show summary for each class */
        display as text ""
        display as text "Probability predictions written to:"
        foreach v of local output_varlist {
            quietly summarize `v' if `touse'
            display as text "  `v':  mean=" as result %7.4f r(mean) ///
                as text "  sd=" as result %7.4f r(sd)
        }
        if `is_predict' == 0 {
            display as text "  OOB Brier:    " as result %9.6f `oob_error'
        }
    }

    /* ---- Survival: display timepoint info ---- */
    if `type_code' == 3 & `is_predict' == 0 {
        capture local n_tp = scalar(__ranger_n_timepoints)
        if _rc == 0 & `n_tp' > 0 {
            display as text "  Timepoints:   " as result `n_tp'
            return scalar n_timepoints = `n_tp'
            return local timepoints "${ranger_timepoints}"
        }
    }

    display as text ""
end
