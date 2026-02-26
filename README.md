# ranger_stata

Random forests for Stata via the [ranger](https://github.com/imbs-hl/ranger) C++ library (Wright & Ziegler, 2017).

Supports **regression**, **classification**, **probability**, and **survival** forests with variable importance, out-of-bag error estimation, forest save/load, case weights, class weights, regularization, and all ranger split rules.

## Installation

Platform-specific packages (recommended — installs only the binary for your OS):

```stata
* macOS:
net install ranger_stata_mac, from("https://raw.githubusercontent.com/dylantmoore/ranger_stata/main") replace

* Linux:
net install ranger_stata_linux, from("https://raw.githubusercontent.com/dylantmoore/ranger_stata/main") replace

* Windows:
net install ranger_stata_win, from("https://raw.githubusercontent.com/dylantmoore/ranger_stata/main") replace

* All platforms:
net install ranger_stata, from("https://raw.githubusercontent.com/dylantmoore/ranger_stata/main") replace
```

Or clone and use directly:

```
git clone https://github.com/dylantmoore/ranger_stata.git
cd ranger_stata
```

## Quick start

```stata
* Regression
sysuse auto, clear
ranger price mpg weight length, gen(pred_price)

* Classification
ranger foreign mpg weight, gen(pred_class) type(class) importance(impurity)

* Probability (class probabilities)
ranger foreign mpg weight length, gen(prob) type(prob)

* Survival
ranger time x1 x2 x3, gen(chf) type(surv) status(event)

* Save and load
ranger price mpg weight, gen(p) saveforest(myforest)
ranger mpg weight, gen(pred_new) using(myforest.forest)
```

## Features

| Feature | Option |
|---------|--------|
| 4 forest types | `type(reg\|class\|prob\|surv)` |
| Variable importance | `importance(impurity\|permutation\|impurity_corrected)` |
| Forest save/load | `saveforest(path)` / `using(path)` |
| Case weights | `caseweights(varname)` |
| Class weights | `classweights("w1 w2 ...")` |
| Always-split variables | `alwayssplit(varlist)` |
| Split-select weights | `splitweights("w1 w2 ...")` |
| Regularization | `regfactor("f1 f2 ...")` + `regusedepth` |
| Holdout | `holdout(varname)` |
| All split rules | `splitrule(variance\|gini\|extratrees\|maxstat\|beta\|hellinger\|logrank\|auc\|poisson)` |
| Terminal nodes | `terminalnodes` |
| Min bucket size | `minbucket(#)` |
| Multithreading | `numthreads(#)` |

## Building from source

Requires a C++14 compiler. Pre-built binaries are included for macOS (Apple Silicon).

```bash
make darwin          # macOS arm64
make linux           # Linux x86_64 (native or cross-compile)
make windows         # Windows x86_64 (requires mingw-w64)
make all-platforms   # All three
```

## Testing

54 comprehensive tests covering all features:

```stata
adopath ++ "."
do tests/test_comprehensive.do
```

## References

Wright, M. N. & Ziegler, A. (2017). ranger: A fast implementation of random forests for high dimensional data in C++ and R. *Journal of Statistical Software* 77(1), 1-17.

Breiman, L. (2001). Random forests. *Machine Learning* 45(1), 5-32.

## License

The ranger C++ core is distributed under the MIT license. See `vendor/ranger/` for details.
