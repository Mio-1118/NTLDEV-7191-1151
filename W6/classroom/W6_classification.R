# W6: exact slide checkpoints, including lettered and numbered substeps; run in one R session.
# Data: Wang, Day & Wu (2022) and Park (2021).
# Generated from week6-presenter.qmd; edit slide source first.
# Uses package/base R functions directly. No workflow.R is required.

# C01: Setup
# install.packages(c("quanteda", "quanteda.textmodels",
#                    "mlr3", "mlr3learners", "e1071", "stringi"))
library(quanteda); library(quanteda.textmodels)
library(mlr3)
quanteda_options(threads = 1)
data_dirs <- c("Data", "W6/lab/Data",
               "W6/classroom/Data", "../Data")
data_dir <- data_dirs[dir.exists(data_dirs)][1]
file.exists(file.path(data_dir, "hate_speech_practice.csv"))
measures <- msrs(c("classif.acc", "classif.precision",
                   "classif.recall", "classif.fbeta"))


# C02: Load the Wang, Day & Wu (2022) data
hate <- read.csv(file.path(data_dir,
  "hate_speech_practice.csv"), stringsAsFactors = FALSE)
hate$label <- factor(hate$label,
  levels = c("NonHateSpeech", "HateSpeech"))
table(hate$label)
nrow(hate)


# C03: Reserve test comments with mlr3
hs_task <- as_task_classif(hate["label"],
  target = "label", positive = "HateSpeech")
hs_task$col_roles$stratum <- "label"
set.seed(7192)
hs_split <- partition(hs_task, ratio = .8)
parts <- list(train = hate[hs_split$train, ],
              test = hate[hs_split$test, ])
table(parts$train$label)
table(parts$test$label)


# C04a_1: Normalize and tokenize Chinese comments
hs_text <- stringi::stri_trans_nfkc(hate$text)
names(hs_text) <- hate$doc_id
hs_tokens <- tokens(hs_text, what = "character",
  remove_punct = TRUE, remove_symbols = TRUE,
  remove_numbers = TRUE)
class(hs_tokens)


# C04a_2: Select Han characters and count features
hs_tokens <- tokens_select(hs_tokens,
  pattern = "^\\p{Han}$", valuetype = "regex")
hs_dfm <- dfm(hs_tokens)
dim(hs_dfm)


# C04b_1: Trim training features
train_dfm <- dfm_trim(hs_dfm[hs_split$train, ],
  min_docfreq = .01, docfreq_type = "prop")
train_label <- parts$train$label
dim(train_dfm)


# C04b_2: Match test features to training columns
test_dfm <- dfm_match(hs_dfm[hs_split$test, ],
  features = featnames(train_dfm))
dim(test_dfm)
identical(featnames(train_dfm), featnames(test_dfm))


# C05: Fit Naive Bayes
nb <- textmodel_nb(train_dfm, y = train_label,
  distribution = "multinomial", smooth = 1,
  prior = "docfreq")
class(nb)
nb$distribution


# C06: Predict and evaluate with mlr3
nb_prediction <- predict(nb, newdata = test_dfm)
nb_check <- PredictionClassif$new(task = hs_task,
  row_ids = hs_split$test,
  truth = hs_task$truth(hs_split$test),
  response = as.character(nb_prediction))
nb_check$confusion
nb_scores <- nb_check$score(measures)
round(nb_scores, 3)


# C07: Inspect one held-out comment
i <- match("hs_26234", parts$test$doc_id)
cat(parts$test$text[i], "\n")
predict(nb, newdata = test_dfm[i, ])
round(predict(nb, newdata = test_dfm[i, ],
              type = "probability"), 3)
parts$test$label[i]


# C08a: Match human-reference texts to the vocabulary
benchmark <- read.csv(file.path(data_dir,
  "hate_speech_reference.csv"), stringsAsFactors = FALSE)
benchmark$label <- factor(benchmark$label,
  levels = c("NonHateSpeech", "HateSpeech"))
ref_text <- stringi::stri_trans_nfkc(benchmark$text)
names(ref_text) <- benchmark$doc_id
ref_tokens <- tokens(ref_text, what = "character",
  remove_punct = TRUE, remove_symbols = TRUE,
  remove_numbers = TRUE)
ref_dfm <- dfm_match(dfm(ref_tokens),
  features = featnames(train_dfm))
dim(ref_dfm); sum(ntoken(ref_dfm) == 0)


# C08b: Evaluate the separate human references
ref_task <- as_task_classif(benchmark["label"],
  target = "label", positive = "HateSpeech")
benchmark$prediction <- predict(nb, newdata = ref_dfm)
ref_check <- PredictionClassif$new(task = ref_task,
  row_ids = ref_task$row_ids,
  response = as.character(benchmark$prediction))
benchmark_scores <- ref_check$score(measures)
nrow(benchmark); round(benchmark_scores, 3)


# G01a: Load the Park (2021) data
grandstanding <- read.csv(file.path(data_dir,
  "grandstanding_practice.csv"), stringsAsFactors = FALSE)
grandstanding$label <- factor(grandstanding$label,
  levels = c("NonGrandstanding", "Grandstanding"))
table(grandstanding$label)


# G01b: Reserve test excerpts with mlr3
gs_task <- as_task_classif(grandstanding["label"],
  target = "label", positive = "Grandstanding")
gs_task$col_roles$stratum <- "label"
set.seed(7192)
gs_split <- partition(gs_task, ratio = .8)
gs_parts <- list(train = grandstanding[gs_split$train, ],
                 test = grandstanding[gs_split$test, ])
table(gs_parts$train$label)
table(gs_parts$test$label)


# G02a_1: Build an English corpus and tokens
gs_corpus <- corpus(grandstanding,
  text_field = "text", docid_field = "doc_id")
gs_tokens <- tokens(gs_corpus, remove_punct = TRUE,
  remove_symbols = TRUE, remove_numbers = TRUE,
  remove_url = TRUE)
ndoc(gs_corpus)


# G02a_2: Normalize English tokens and build a DFM
gs_tokens <- tokens_tolower(gs_tokens)
gs_tokens <- tokens_remove(gs_tokens,
  pattern = stopwords("en"))
gs_dfm <- dfm(gs_tokens)
dim(gs_dfm)


# G02a_3: Select training words and match test columns
gs_train_dfm <- dfm_trim(gs_dfm[gs_split$train, ],
  min_docfreq = .01, docfreq_type = "prop")
gs_test_dfm <- dfm_match(gs_dfm[gs_split$test, ],
  features = featnames(gs_train_dfm))
dim(gs_train_dfm); dim(gs_test_dfm)


# G02b_1: Convert text counts to feature tables
gs_train_data <- convert(gs_train_dfm, to = "data.frame")
gs_test_data <- convert(gs_test_dfm, to = "data.frame")
gs_train_data$doc_id <- NULL; gs_test_data$doc_id <- NULL
dim(gs_train_data); dim(gs_test_data)


# G02b_2: Name feature columns and add labels
names(gs_train_data) <- make.names(featnames(gs_train_dfm),
  unique = TRUE)
names(gs_test_data) <- names(gs_train_data)
gs_train_data$label <- gs_parts$train$label
gs_test_data$label <- factor(gs_parts$test$label,
  levels = c("Grandstanding", "NonGrandstanding"))
dim(gs_train_data); dim(gs_test_data)


# G02c_1: Define the grandstanding task
gs_model_task <- as_task_classif(gs_train_data,
  target = "label", positive = "Grandstanding")
gs_model_task$target_names
length(gs_model_task$feature_names)


# G02c_2: Configure the linear SVM learner
library(mlr3learners)
gs_learner <- lrn("classif.svm", type = "C-classification",
  kernel = "linear", cost = 1, scale = FALSE,
  predict_type = "prob")
gs_learner$id
gs_learner$predict_type


# G02c_3: Train the learner and predict held-out texts
set.seed(7193)
gs_learner$train(gs_model_task)
gs_result <- gs_learner$predict_newdata(gs_test_data)
gs_prediction <- gs_result$response
length(gs_prediction)
colnames(gs_result$prob)


# G02d: Evaluate the mlr3 predictions
gs_result$confusion
gs_scores <- gs_result$score(measures)
round(gs_scores, 3)


# G03: Inspect one grandstanding prediction
j <- match("gs_01045", gs_parts$test$doc_id)
cat(gs_parts$test$text[j], "\n")
gs_result$response[j]
round(gs_result$prob[j, ], 3)
gs_result$truth[j]
