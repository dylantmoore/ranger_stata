/*
 * ranger_plugin.cpp -- Stata plugin wrapping the ranger C++ random forest library
 *
 * Supports regression, classification, probability, and survival forests
 * with variable importance, OOB error, save/load, case weights, class weights,
 * regularization, holdout, always-split variables, split-select weights,
 * and all split rules.
 *
 * Compile: See Makefile
 */

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cmath>
#include <vector>
#include <string>
#include <memory>
#include <sstream>
#include <fstream>

/* Stata plugin interface -- must be included with C linkage */
extern "C" {
#include "stplugin.h"
}

/* ranger C++ library headers */
#include "vendor/ranger/globals.h"
#include "vendor/ranger/Forest.h"
#include "vendor/ranger/ForestRegression.h"
#include "vendor/ranger/ForestClassification.h"
#include "vendor/ranger/ForestProbability.h"
#include "vendor/ranger/ForestSurvival.h"
#include "vendor/ranger/Data.h"
#include "vendor/ranger/DataDouble.h"

/* Thin adapter headers for Stata integration */
#include "DataStata.h"
#include "ForestRegressionStata.h"
#include "ForestClassificationStata.h"
#include "ForestProbabilityStata.h"
#include "ForestSurvivalStata.h"

/* Helper: parse space-separated doubles from a string */
static std::vector<double> parse_doubles(const char* s) {
    std::vector<double> v;
    if (!s || s[0] == '\0') return v;
    std::istringstream iss(s);
    double d;
    while (iss >> d) v.push_back(d);
    return v;
}

/* Helper: parse space-separated strings */
static std::vector<std::string> parse_strings(const char* s) {
    std::vector<std::string> v;
    if (!s || s[0] == '\0') return v;
    std::istringstream iss(s);
    std::string tok;
    while (iss >> tok) v.push_back(tok);
    return v;
}

/* ================================================================
 * stata_call -- Main Entry Point
 * ================================================================
 *
 * argv[] layout (30 args, passed from ranger.ado):
 *   [0]  n_trees           (int, default 500)
 *   [1]  seed              (int, 0 = random)
 *   [2]  mtry              (int, 0 = auto)
 *   [3]  min_node_size     (int, 0 = ranger default)
 *   [4]  max_depth         (int, 0 = unlimited)
 *   [5]  sample_fraction   (double, 0 = auto)
 *   [6]  replace           (int, 1 = with replacement)
 *   [7]  importance_mode   (int, 0=none, 1=impurity, 2=permutation, etc.)
 *   [8]  splitrule         (int, 0=default)
 *   [9]  forest_type       (int, 0=reg, 1=class, 2=prob, 3=surv)
 *   [10] num_threads       (int, 0 = auto)
 *   [11] alpha             (double, 0.5)
 *   [12] minprop           (double, 0.1)
 *   [13] num_random_splits (int, 1)
 *   [14] prediction_mode   (int, 0=train, 1=predict)
 *   [15] prediction_type   (int, 1=RESPONSE, 2=TERMINALNODES)
 *   [16] holdout_mode      (int, 0=off)
 *   [17] node_stats        (int, 0=off)
 *   [18] reg_usedepth      (int, 0=off)
 *   [19] poisson_tau       (double, 1.0)
 *   [20] min_bucket        (int, 0=default)
 *   [21] n_dep_vars        (int, 1; 0=predict, 2=survival)
 *   [22] n_output_vars     (int, 1; K for probability)
 *   [23] n_extra_vars      (int, 0; count of case_weights + holdout vars)
 *   [24] save_path         (string, "" = don't save)
 *   [25] load_path         (string, "" = don't load)
 *   [26] always_split_names (string, space-sep var names)
 *   [27] split_select_weights (string, space-sep doubles)
 *   [28] reg_factor        (string, space-sep doubles)
 *   [29] class_weights     (string, space-sep doubles)
 */
extern "C" STDLL stata_call(int argc, char *argv[])
{
    char msg[512];

    try {

    /* ----------------------------------------------------------
     * Step 0: Validate and parse arguments
     * ---------------------------------------------------------- */
    if (argc < 30) {
        snprintf(msg, sizeof(msg),
                 "ranger error: expected 30 arguments, got %d\n", argc);
        SF_error(msg);
        return 198;
    }

    int n_trees           = atoi(argv[0]);
    int seed              = atoi(argv[1]);
    int mtry              = atoi(argv[2]);
    int min_node_size     = atoi(argv[3]);
    int max_depth         = atoi(argv[4]);
    double sample_frac    = atof(argv[5]);
    int replace           = atoi(argv[6]);
    int importance_mode   = atoi(argv[7]);
    int splitrule_int     = atoi(argv[8]);
    int forest_type       = atoi(argv[9]);
    int num_threads       = atoi(argv[10]);
    double alpha          = atof(argv[11]);
    double minprop        = atof(argv[12]);
    int num_random_splits = atoi(argv[13]);
    int predict_mode      = atoi(argv[14]);
    int prediction_type   = atoi(argv[15]);
    int holdout_mode      = atoi(argv[16]);
    int node_stats        = atoi(argv[17]);
    int reg_usedepth      = atoi(argv[18]);
    double poisson_tau    = atof(argv[19]);
    int min_bucket_val    = atoi(argv[20]);
    int n_dep_vars        = atoi(argv[21]);
    int n_output_vars     = atoi(argv[22]);
    int n_extra_vars      = atoi(argv[23]);
    std::string save_path(argv[24]);
    std::string load_path(argv[25]);
    std::vector<std::string> always_split_names = parse_strings(argv[26]);
    std::vector<double> split_wt_vec = parse_doubles(argv[27]);
    std::vector<double> reg_factor = parse_doubles(argv[28]);
    std::vector<double> class_wt_vec = parse_doubles(argv[29]);

    /* Defaults */
    if (n_trees <= 0)           n_trees = 500;
    if (seed < 0)               seed = 0;
    if (min_node_size < 0)      min_node_size = 0;
    if (max_depth < 0)          max_depth = 0;
    if (num_random_splits <= 0) num_random_splits = 1;
    if (poisson_tau <= 0.0)     poisson_tau = 1.0;
    if (min_bucket_val < 0)     min_bucket_val = 0;
    if (prediction_type < 1 || prediction_type > 2) prediction_type = 1;

    bool is_predict_mode = (predict_mode != 0);
    bool sample_with_replacement = (replace != 0);
    if (sample_frac <= 0.0 || sample_frac > 1.0) {
        sample_frac = sample_with_replacement ? 1.0 : 0.632;
    }

    /* Importance mode */
    ranger::ImportanceMode imp_mode;
    switch (importance_mode) {
        case 1:  imp_mode = ranger::IMP_GINI; break;
        case 2:  imp_mode = ranger::IMP_PERM_BREIMAN; break;
        case 3:  imp_mode = ranger::IMP_PERM_RAW; break;
        case 5:  imp_mode = ranger::IMP_GINI_CORRECTED; break;
        case 6:  imp_mode = ranger::IMP_PERM_CASEWISE; break;
        default: imp_mode = ranger::IMP_NONE; break;
    }

    /* Split rule */
    ranger::SplitRule split_rule;
    switch (splitrule_int) {
        case 2:  split_rule = ranger::AUC; break;
        case 3:  split_rule = ranger::AUC_IGNORE_TIES; break;
        case 4:  split_rule = ranger::MAXSTAT; break;
        case 5:  split_rule = ranger::EXTRATREES; break;
        case 6:  split_rule = ranger::BETA; break;
        case 7:  split_rule = ranger::HELLINGER; break;
        case 8:  split_rule = ranger::POISSON; break;
        default: split_rule = ranger::LOGRANK; break;
    }

    /* Prediction type */
    ranger::PredictionType pred_type =
        (prediction_type == 2) ? ranger::TERMINALNODES : ranger::RESPONSE;

    /* Type label for display */
    const char* type_labels[] = {"regression", "classification", "probability", "survival"};
    const char* type_label = (forest_type >= 0 && forest_type <= 3) ?
        type_labels[forest_type] : "unknown";

    /* ----------------------------------------------------------
     * Step 1: Read dimensions and compute variable positions
     * ---------------------------------------------------------- */
    int nvar = SF_nvars();

    /* Variable positions:
     * Training:   depvar [statusvar] x1...xP [caseweightvar] [holdoutvar] out1 [out2...outK]
     * Prediction: x1...xP out1 [out2...outK]
     */
    int p = nvar - n_dep_vars - n_output_vars - n_extra_vars;
    if (p < 1) {
        SF_error("ranger error: need at least 1 predictor variable.\n");
        return 198;
    }

    int indep_start = n_dep_vars + 1;   /* 1-indexed Stata var position */
    int indep_end   = n_dep_vars + p;
    int extra_start = indep_end + 1;     /* case_weights first, then holdout */
    int output_start = nvar - n_output_vars + 1;

    /* Count usable observations */
    ST_int obs1 = SF_in1();
    ST_int obs2 = SF_in2();
    int n = 0;
    for (ST_int i = obs1; i <= obs2; i++) {
        if (SF_ifobs(i)) n++;
    }

    if (n < 2) {
        SF_error("ranger error: need at least 2 non-missing observations.\n");
        return 2000;
    }

    snprintf(msg, sizeof(msg),
             "Ranger (%s%s): n=%d, p=%d, trees=%d, mtry=%d, threads=%d\n",
             type_label, is_predict_mode ? ", predict" : "",
             n, p, n_trees, mtry, num_threads);
    SF_display(msg);

    /* ----------------------------------------------------------
     * Step 2: Create Data object and populate from Stata
     * ---------------------------------------------------------- */
    auto data_ptr = std::unique_ptr<ranger::Data>(new ranger::DataStata());
    auto* data = static_cast<ranger::DataStata*>(data_ptr.get());

    /* For predict mode, we still need a dummy depvar column for ranger's expectations */
    int data_cols = p;  /* independent variables only in data */
    int n_dep_in_data = is_predict_mode ? 0 : n_dep_vars;

    data->setDimensions((size_t)n, (size_t)data_cols);
    data->reserveMemory(n_dep_in_data > 0 ? n_dep_in_data : 1);

    /* Variable names for independent variables */
    std::vector<std::string> var_names(p);
    for (int j = 0; j < p; j++) {
        var_names[j] = "x" + std::to_string(j + 1);
    }
    data->setVariableNames(var_names);

    /* Read data from Stata into ranger's column-major storage */
    std::vector<int> obs_map(n);
    int idx = 0;

    /* Vectors for case weights and holdout */
    std::vector<double> case_weights;
    if (n_extra_vars > 0) case_weights.resize(n, 1.0);

    for (ST_int i = obs1; i <= obs2; i++) {
        if (!SF_ifobs(i)) continue;

        /* Read dependent variable(s) if training */
        bool skip = false;
        if (!is_predict_mode && n_dep_vars >= 1) {
            double yval;
            ST_retcode rc = SF_vdata(1, i, &yval);
            if (rc || SF_is_missing(yval)) continue;
            data->set_y(0, idx, yval, skip);
            if (skip) continue;

            /* For survival: second depvar is status */
            if (n_dep_vars >= 2) {
                double sval;
                rc = SF_vdata(2, i, &sval);
                if (rc || SF_is_missing(sval)) continue;
                data->set_y(1, idx, sval, skip);
                if (skip) continue;
            }
        }

        obs_map[idx] = (int)i;

        /* Read independent variables */
        for (int j = 0; j < p; j++) {
            double xval;
            ST_retcode rc = SF_vdata(indep_start + j, i, &xval);
            if (rc || SF_is_missing(xval)) {
                xval = 0.0;
            }
            bool err = false;
            data->set_x((size_t)j, (size_t)idx, xval, err);
        }

        /* Read extra variables: case_weights, holdout */
        if (n_extra_vars >= 1) {
            double cwval;
            ST_retcode rc = SF_vdata(extra_start, i, &cwval);
            if (rc || SF_is_missing(cwval)) cwval = 1.0;
            case_weights[idx] = cwval;
        }
        /* holdout variable is read but ranger handles it via the holdout flag */

        idx++;
    }
    n = idx;
    if (n < 2) {
        SF_error("ranger error: fewer than 2 complete observations.\n");
        return 2000;
    }

    /* Trim case_weights to actual size */
    if (!case_weights.empty()) case_weights.resize(n);

    /* ----------------------------------------------------------
     * Step 3: Create Forest, init, and run
     * ---------------------------------------------------------- */

    /* Dependent variable names */
    std::vector<std::string> dep_names;
    if (forest_type == 3) {  /* survival: time + status */
        dep_names = {"y", "status"};
    } else {
        dep_names = {"y"};
    }

    /* Create the appropriate forest subclass */
    ranger::ForestRegressionStata* f_reg = nullptr;
    ranger::ForestClassificationStata* f_class = nullptr;
    ranger::ForestProbabilityStata* f_prob = nullptr;
    ranger::ForestSurvivalStata* f_surv = nullptr;
    std::unique_ptr<ranger::Forest> forest;

    switch (forest_type) {
        case 0: {
            auto f = std::unique_ptr<ranger::ForestRegressionStata>(
                new ranger::ForestRegressionStata());
            f->setDependentVariableNames(dep_names);
            f_reg = f.get();
            forest = std::move(f);
            break;
        }
        case 1: {
            auto f = std::unique_ptr<ranger::ForestClassificationStata>(
                new ranger::ForestClassificationStata());
            f->setDependentVariableNames(dep_names);
            f_class = f.get();
            forest = std::move(f);
            break;
        }
        case 2: {
            auto f = std::unique_ptr<ranger::ForestProbabilityStata>(
                new ranger::ForestProbabilityStata());
            f->setDependentVariableNames(dep_names);
            f_prob = f.get();
            forest = std::move(f);
            break;
        }
        case 3: {
            auto f = std::unique_ptr<ranger::ForestSurvivalStata>(
                new ranger::ForestSurvivalStata());
            f->setDependentVariableNames(dep_names);
            f_surv = f.get();
            forest = std::move(f);
            break;
        }
        default: {
            SF_error("ranger error: unsupported forest_type.\n");
            return 198;
        }
    }

    /* Prepare parameters */
    std::vector<ranger::uint> min_node_size_vec = {(ranger::uint)min_node_size};
    std::vector<ranger::uint> min_bucket_vec = {(ranger::uint)min_bucket_val};
    std::vector<double> sample_fraction_vec = {sample_frac};
    std::vector<std::string> unordered_var_names;

    /* Split select weights: wrap in vector<vector<double>> for initR */
    std::vector<std::vector<double>> split_select_weights;
    if (!split_wt_vec.empty()) {
        split_select_weights.push_back(split_wt_vec);
    }

    /* Manual inbag (not used) */
    std::vector<std::vector<size_t>> manual_inbag;

    /* Case weights: only pass if non-empty AND we have extra vars */
    std::vector<double> cw_for_init;
    if (n_extra_vars > 0 && !case_weights.empty()) {
        cw_for_init = case_weights;
    }

    SF_display("  Initializing forest...\n");

    forest->initR(
        std::move(data_ptr),
        (ranger::uint)mtry,
        (ranger::uint)n_trees,
        nullptr,                         /* verbose_out */
        (ranger::uint)seed,
        (ranger::uint)num_threads,
        is_predict_mode ? ranger::IMP_NONE : imp_mode,
        min_node_size_vec,
        min_bucket_vec,
        split_select_weights,
        always_split_names,
        is_predict_mode,                 /* prediction_mode */
        sample_with_replacement,
        unordered_var_names,
        false,                           /* memory_saving_splitting */
        split_rule,
        cw_for_init,
        manual_inbag,
        false,                           /* predict_all */
        false,                           /* keep_inbag */
        sample_fraction_vec,
        alpha,
        minprop,
        poisson_tau,
        (holdout_mode != 0),             /* holdout */
        pred_type,
        (ranger::uint)num_random_splits,
        false,                           /* order_snps */
        (ranger::uint)max_depth,
        reg_factor,
        (reg_usedepth != 0),
        (node_stats != 0)
    );

    /* Post-init: set output_prefix for save */
    if (!save_path.empty()) {
        switch (forest_type) {
            case 0: f_reg->setOutputPrefix(save_path); break;
            case 1: f_class->setOutputPrefix(save_path); break;
            case 2: f_prob->setOutputPrefix(save_path); break;
            case 3: f_surv->setOutputPrefix(save_path); break;
        }
    }

    /* Post-init: set class weights for classification/probability */
    if (!class_wt_vec.empty()) {
        if (f_class) f_class->setClassWeights(class_wt_vec);
        if (f_prob) f_prob->setClassWeights(class_wt_vec);
    }

    /* Post-init: load forest from file for predict mode */
    if (is_predict_mode && !load_path.empty()) {
        SF_display("  Loading forest from file...\n");
        switch (forest_type) {
            case 0: f_reg->callLoadFromFile(load_path); break;
            case 1: f_class->callLoadFromFile(load_path); break;
            case 2: f_prob->callLoadFromFile(load_path); break;
            case 3: f_surv->callLoadFromFile(load_path); break;
        }
    }

    /* Run */
    if (is_predict_mode) {
        SF_display("  Predicting...\n");
        forest->run(false, false);
    } else {
        SF_display("  Growing trees...\n");
        forest->run(false, true);
    }
    SF_display("  Forest complete.\n");

    /* Save forest if requested */
    if (!save_path.empty() && !is_predict_mode) {
        SF_display("  Saving forest...\n");
        forest->saveToFile();
        snprintf(msg, sizeof(msg), "  Forest saved to: %s.forest\n", save_path.c_str());
        SF_display(msg);
    }

    /* ----------------------------------------------------------
     * Step 4: Extract predictions and write back to Stata
     * ---------------------------------------------------------- */
    const auto& predictions = forest->getPredictions();
    int n_pred = 0;

    switch (forest_type) {
        case 0:  /* Regression: preds[0][0][i] */
        case 1:  /* Classification: preds[0][0][i] */
        {
            for (int i = 0; i < n; i++) {
                double pred = predictions[0][0][i];
                if (!std::isnan(pred)) {
                    ST_retcode rc = SF_vstore(output_start, obs_map[i], pred);
                    if (rc == 0) n_pred++;
                }
            }
            break;
        }
        case 2:  /* Probability: preds[0][i][j] for j=0..K-1 */
        {
            int K = n_output_vars;
            for (int i = 0; i < n; i++) {
                if (predictions[0][i].empty()) continue;
                for (int j = 0; j < K && j < (int)predictions[0][i].size(); j++) {
                    double pred = predictions[0][i][j];
                    if (!std::isnan(pred)) {
                        SF_vstore(output_start + j, obs_map[i], pred);
                    }
                }
                n_pred++;
            }
            break;
        }
        case 3:  /* Survival: preds[0][i][j] = CHF at timepoint j */
        {
            /* Write mean CHF to first output var */
            for (int i = 0; i < n; i++) {
                if (predictions[0][i].empty()) continue;
                double mean_chf = 0.0;
                for (size_t t = 0; t < predictions[0][i].size(); t++) {
                    mean_chf += predictions[0][i][t];
                }
                mean_chf /= (double)predictions[0][i].size();
                if (!std::isnan(mean_chf)) {
                    SF_vstore(output_start, obs_map[i], mean_chf);
                    n_pred++;
                }
            }

            /* Store unique timepoints as macro */
            if (f_surv) {
                const auto& tp = f_surv->getUniqueTimepoints();
                if (!tp.empty()) {
                    std::ostringstream tpss;
                    tpss.precision(12);
                    for (size_t t = 0; t < tp.size(); t++) {
                        if (t > 0) tpss << " ";
                        tpss << tp[t];
                    }
                    std::string tp_str = tpss.str();
                    char mname[] = "ranger_timepoints";
                    char* tp_cstr = const_cast<char*>(tp_str.c_str());
                    SF_macro_save(mname, tp_cstr);

                    char ntname[] = "__ranger_n_timepoints";
                    SF_scal_save(ntname, (double)tp.size());
                }
            }
            break;
        }
    }

    snprintf(msg, sizeof(msg), "  Wrote %d predictions.\n", n_pred);
    SF_display(msg);

    /* ----------------------------------------------------------
     * Step 5: Store class values for probability/classification
     * ---------------------------------------------------------- */
    if (forest_type == 2 && f_prob) {
        const auto& cv = f_prob->getClassValues();
        if (!cv.empty()) {
            std::ostringstream cvss;
            cvss.precision(12);
            for (size_t j = 0; j < cv.size(); j++) {
                if (j > 0) cvss << " ";
                cvss << cv[j];
            }
            std::string cv_str = cvss.str();
            char mname[] = "ranger_class_values";
            char* cv_cstr = const_cast<char*>(cv_str.c_str());
            SF_macro_save(mname, cv_cstr);
        }
    }

    /* ----------------------------------------------------------
     * Step 6: Store OOB error as Stata scalar
     * ---------------------------------------------------------- */
    if (!is_predict_mode) {
        double oob_error = forest->getOverallPredictionError();
        {
            char sname[] = "__ranger_oob_error";
            SF_scal_save(sname, oob_error);
        }

        const char* error_labels[] = {"MSE", "misclassification", "Brier score", "C-index"};
        const char* err_label = (forest_type >= 0 && forest_type <= 3) ?
            error_labels[forest_type] : "error";
        snprintf(msg, sizeof(msg), "  OOB prediction error (%s): %.6f\n",
                 err_label, oob_error);
        SF_display(msg);
    }

    /* ----------------------------------------------------------
     * Step 7: Store variable importance
     * ---------------------------------------------------------- */
    if (!is_predict_mode) {
        const auto& importance = forest->getVariableImportance();
        if (!importance.empty()) {
            std::ostringstream oss;
            oss.precision(12);
            for (size_t j = 0; j < importance.size(); j++) {
                if (j > 0) oss << " ";
                oss << importance[j];
            }
            std::string imp_str = oss.str();

            char mname[] = "ranger_importance_vals";
            char* imp_cstr = const_cast<char*>(imp_str.c_str());
            SF_macro_save(mname, imp_cstr);

            char nname[] = "__ranger_nimp";
            SF_scal_save(nname, (double)importance.size());
        }
    }

    /* Store forest_type as scalar for .ado to read back */
    {
        char ftname[] = "__ranger_forest_type";
        SF_scal_save(ftname, (double)forest_type);
    }

    return 0;

    } catch (const std::exception& e) {
        snprintf(msg, sizeof(msg), "ranger error: %s\n", e.what());
        SF_error(msg);
        return 909;
    } catch (...) {
        SF_error("ranger error: unknown exception\n");
        return 909;
    }
}
