# generate_reference.R -- Produce reference CSVs for cross-validation
# Run: Rscript generate_reference.R
# Requires: ranger, MASS

library(ranger)

set.seed(42)

# ── Regression test data ──────────────────────────────────────────
n <- 500
x1 <- rnorm(n)
x2 <- rnorm(n)
x3 <- rnorm(n)  # noise variable
y <- 3*x1 + x2^2 + rnorm(n, sd=0.5)

reg_data <- data.frame(y=y, x1=x1, x2=x2, x3=x3)
write.csv(reg_data, "ref_regression_data.csv", row.names=FALSE)

# Fit ranger regression
rf_reg <- ranger(y ~ ., data=reg_data, num.trees=500, seed=42,
                 num.threads=1, importance="impurity")

# OOB predictions
reg_preds <- data.frame(
    oob_pred = rf_reg$predictions
)
write.csv(reg_preds, "ref_regression_preds.csv", row.names=FALSE)

# Importance
reg_imp <- data.frame(
    variable = names(rf_reg$variable.importance),
    importance = as.numeric(rf_reg$variable.importance)
)
write.csv(reg_imp, "ref_regression_importance.csv", row.names=FALSE)

cat("Regression OOB MSE:", rf_reg$prediction.error, "\n")
cat("Regression importance:\n")
print(rf_reg$variable.importance)

# ── Classification test data ──────────────────────────────────────
set.seed(42)
n <- 500
x1 <- rnorm(n)
x2 <- rnorm(n)
x3 <- rnorm(n)
prob <- plogis(2*x1 - x2)
y <- rbinom(n, 1, prob)

cls_data <- data.frame(y=as.factor(y), x1=x1, x2=x2, x3=x3)
write.csv(cls_data, "ref_classification_data.csv", row.names=FALSE)

# Fit ranger classification
rf_cls <- ranger(y ~ ., data=cls_data, num.trees=500, seed=42,
                 num.threads=1, importance="impurity")

# OOB predictions
cls_preds <- data.frame(
    oob_pred = as.numeric(as.character(rf_cls$predictions))
)
write.csv(cls_preds, "ref_classification_preds.csv", row.names=FALSE)

# Importance
cls_imp <- data.frame(
    variable = names(rf_cls$variable.importance),
    importance = as.numeric(rf_cls$variable.importance)
)
write.csv(cls_imp, "ref_classification_importance.csv", row.names=FALSE)

cat("Classification OOB error:", rf_cls$prediction.error, "\n")
cat("Classification importance:\n")
print(rf_cls$variable.importance)
