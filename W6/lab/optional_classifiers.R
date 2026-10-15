# Optional models; run W6_classification.R first.
set.seed(7193)
lr <- textmodel_lr(train_dfm, y = train_label)
lr_prediction <- predict(lr, newdata = test_dfm)
lr_check <- PredictionClassif$new(task = hs_task,
  row_ids = hs_split$test, truth = hs_task$truth(hs_split$test),
  response = as.character(lr_prediction))
lr_check$score(measures)

# install.packages(c("mlr3learners", "e1071"))
library(mlr3learners)
svm_data <- rbind(convert(train_dfm, to = "data.frame"),
                  convert(test_dfm, to = "data.frame"))
svm_data$doc_id <- NULL
names(svm_data) <- make.names(names(svm_data), unique = TRUE)
svm_data$label <- factor(c(as.character(parts$train$label),
                           as.character(parts$test$label)))
svm_task <- as_task_classif(svm_data, target = "label",
                            positive = "HateSpeech")
svm_train <- seq_len(nrow(parts$train))
svm_test <- seq.int(nrow(parts$train) + 1L, nrow(svm_data))
svm <- lrn("classif.svm", type = "C-classification",
           kernel = "linear", cost = 1, scale = FALSE)
svm$train(svm_task, row_ids = svm_train)
svm_result <- svm$predict(svm_task, row_ids = svm_test)
svm_result$score(measures)
