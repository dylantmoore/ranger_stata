{smcl}
{* *! version 0.2.0}{...}
{viewerjumpto "Syntax" "ranger##syntax"}{...}
{viewerjumpto "Description" "ranger##description"}{...}
{viewerjumpto "Options" "ranger##options"}{...}
{viewerjumpto "Examples" "ranger##examples"}{...}
{viewerjumpto "Stored results" "ranger##results"}{...}

{title:Title}

{phang}
{bf:ranger} {hline 2} Random forests via the ranger C++ library


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:ranger}
{depvar}
{indepvars}
{ifin}{cmd:,}
{opt gen:erate(newvar)}
[{it:options}]

{synoptset 32 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt gen:erate(newvar)}}name of variable for predictions{p_end}

{syntab:Model}
{synopt:{opt type(string)}}forest type: {bf:regression} (default), {bf:classification}, {bf:probability}, or {bf:survival}{p_end}
{synopt:{opt nt:rees(#)}}number of trees; default is {bf:500}{p_end}
{synopt:{opt mtry(#)}}variables to try per split; default is {bf:sqrt(p)}{p_end}
{synopt:{opt minn:odesize(#)}}minimum node size; default depends on type{p_end}
{synopt:{opt maxd:epth(#)}}maximum tree depth; default is {bf:0} (unlimited){p_end}
{synopt:{opt seed(#)}}random number seed; default is {bf:42}{p_end}
{synopt:{opt minb:ucket(#)}}minimum terminal node size; default is {bf:0} (use ranger default){p_end}

{syntab:Sampling}
{synopt:{opt samplefrac(#)}}fraction of observations to sample per tree{p_end}
{synopt:{opt replace}}sample with replacement (default){p_end}
{synopt:{opt noreplace}}sample without replacement{p_end}

{syntab:Importance}
{synopt:{opt imp:ortance(string)}}{bf:none} (default), {bf:impurity}, {bf:permutation}, or {bf:impurity_corrected}{p_end}

{syntab:Split rules}
{synopt:{opt split:rule(string)}}{bf:variance}/{bf:gini} (default), {bf:extratrees}, {bf:maxstat}, {bf:beta}, {bf:hellinger}, {bf:logrank}, {bf:auc}, {bf:auc_ignore_ties}, {bf:poisson}{p_end}
{synopt:{opt alpha(#)}}significance threshold for maxstat; default is {bf:0.5}{p_end}
{synopt:{opt minprop(#)}}quantile threshold for maxstat; default is {bf:0.1}{p_end}
{synopt:{opt numr:andomsplits(#)}}random splits for extratrees; default is {bf:1}{p_end}
{synopt:{opt poissontau(#)}}tau parameter for POISSON splitrule; default is {bf:1.0}{p_end}

{syntab:Survival}
{synopt:{opt status(varname)}}event indicator variable (required for survival){p_end}

{syntab:Weights}
{synopt:{opt casew:eights(varname)}}observation-level case weights{p_end}
{synopt:{opt classw:eights(string)}}space-separated class weights for classification/probability{p_end}

{syntab:Variable selection}
{synopt:{opt alwayssplit(varlist)}}variables always considered for splitting{p_end}
{synopt:{opt splitw:eights(string)}}space-separated per-predictor split selection weights{p_end}

{syntab:Regularization}
{synopt:{opt regfactor(string)}}space-separated regularization factors per predictor{p_end}
{synopt:{opt regusedepth}}use tree depth in regularization{p_end}

{syntab:Advanced}
{synopt:{opt holdout(varname)}}holdout indicator (0/1); holdout obs excluded from OOB error{p_end}
{synopt:{opt nodestats}}collect node statistics{p_end}
{synopt:{opt terminalnodes}}output terminal node IDs instead of predictions{p_end}

{syntab:Save/Load}
{synopt:{opt savef:orest(string)}}save trained forest to file (path prefix){p_end}
{synopt:{opt using(string)}}load forest from file for prediction{p_end}
{synopt:{opt ncl:asses(#)}}number of classes for probability prediction mode{p_end}

{syntab:Performance}
{synopt:{opt numt:hreads(#)}}number of threads; default is {bf:0} (auto){p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:ranger} fits random forests using the ranger C++ library
(Wright & Ziegler, 2017). Four forest types are supported:

{phang}{bf:regression} {hline 2} continuous outcome, OOB predictions are means, error is MSE.{p_end}
{phang}{bf:classification} {hline 2} categorical outcome, predictions are majority-vote class labels, error is misclassification rate.{p_end}
{phang}{bf:probability} {hline 2} categorical outcome, predictions are class probabilities (one variable per class), error is Brier score.{p_end}
{phang}{bf:survival} {hline 2} time-to-event outcome with censoring, predictions are mean cumulative hazard, error is 1 - C-index.{p_end}


{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opt type(string)} specifies the forest type. Abbreviations {bf:reg}, {bf:class},
{bf:prob}, {bf:surv} are accepted.

{phang}
{opt minnodesize(#)} minimum node size. Defaults: 5 (regression), 1 (classification),
10 (probability), 3 (survival).

{dlgtab:Survival}

{phang}
{opt status(varname)} specifies the event/censoring indicator for survival forests.
Required when {bf:type(survival)} is specified. The dependent variable is the
event time and this variable is the event indicator (1 = event, 0 = censored).

{dlgtab:Weights}

{phang}
{opt caseweights(varname)} observation-level case weights. Larger weights increase the
probability of an observation being sampled. Useful for survey or frequency weights.

{phang}
{opt classweights(string)} space-separated class weights for classification and
probability forests. Order must match the sorted unique values of the dependent variable.
Useful for handling class imbalance.

{dlgtab:Variable selection}

{phang}
{opt alwayssplit(varlist)} specifies predictor variables that should always be
considered as candidate split variables. Must be a subset of the predictors.

{phang}
{opt splitweights(string)} space-separated split selection weights (one per predictor).
Values between 0 and 1. A weight of 0 means the variable is never selected;
1 means it is always eligible. Deterministic (weight=1) variables are always used.

{dlgtab:Regularization}

{phang}
{opt regfactor(string)} space-separated regularization factors (one per predictor).
Values between 0 and 1. Penalizes splits on variables that have been used
frequently higher up in the tree.

{dlgtab:Save/Load}

{phang}
{opt saveforest(string)} saves the trained forest to a file. The argument is a
path prefix; the file will be saved as {it:prefix}.forest. The forest can later
be loaded for prediction with {opt using()}.

{phang}
{opt using(string)} loads a previously saved forest for prediction on new data.
In prediction mode, {it:varlist} contains only predictor variables (no dependent
variable). For probability forests, {opt nclasses()} must also be specified.

{phang}
{opt nclasses(#)} number of classes in the saved probability forest. Required
when using {opt using()} with probability forests, since the number of output
variables must be known before loading.


{marker examples}{...}
{title:Examples}

{phang}{cmd:. sysuse auto}{p_end}

{pstd}Basic regression forest:{p_end}
{phang}{cmd:. ranger price mpg weight length, gen(pred_price)}{p_end}

{pstd}Classification with importance:{p_end}
{phang}{cmd:. ranger foreign mpg weight, gen(pred_foreign) type(class) importance(impurity)}{p_end}

{pstd}Probability forest (class probabilities):{p_end}
{phang}{cmd:. ranger foreign mpg weight length, gen(prob) type(prob)}{p_end}

{pstd}Survival forest:{p_end}
{phang}{cmd:. ranger time x1 x2 x3, gen(chf) type(surv) status(event)}{p_end}

{pstd}Save and load:{p_end}
{phang}{cmd:. ranger price mpg weight, gen(p) saveforest(myforest)}{p_end}
{phang}{cmd:. ranger mpg weight, gen(pred_new) using(myforest.forest)}{p_end}

{pstd}Case weights:{p_end}
{phang}{cmd:. ranger price mpg weight, gen(p) caseweights(freq)}{p_end}

{pstd}Custom parameters:{p_end}
{phang}{cmd:. ranger price mpg weight, gen(pred) ntrees(1000) mtry(2) seed(123)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:ranger} stores the following in {cmd:r()}:

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of observations used{p_end}
{synopt:{cmd:r(n_trees)}}number of trees{p_end}
{synopt:{cmd:r(seed)}}random number seed{p_end}
{synopt:{cmd:r(mtry)}}mtry value used{p_end}
{synopt:{cmd:r(oob_error)}}OOB prediction error (MSE, misclassification, Brier, or 1-Cindex){p_end}
{synopt:{cmd:r(n_classes)}}number of classes (probability forests only){p_end}
{synopt:{cmd:r(n_timepoints)}}number of unique timepoints (survival forests only){p_end}
{synopt:{cmd:r(imp_}{it:varname}{cmd:)}}variable importance for each predictor (if requested){p_end}

{p2col 5 24 28 2: Macros}{p_end}
{synopt:{cmd:r(type)}}forest type{p_end}
{synopt:{cmd:r(depvar)}}dependent variable name{p_end}
{synopt:{cmd:r(indepvars)}}independent variable names{p_end}
{synopt:{cmd:r(generate)}}name of prediction variable{p_end}
{synopt:{cmd:r(timepoints)}}unique timepoints (survival forests only){p_end}


{title:References}

{pstd}
Wright, M. N. & Ziegler, A. (2017). ranger: A fast implementation of random
forests for high dimensional data in C++ and R. Journal of Statistical
Software 77(1), 1-17.

{pstd}
Breiman, L. (2001). Random forests. Machine Learning 45(1), 5-32.


{title:Author}

{pstd}
Built with the stata-c-plugins skill for Claude Code.
