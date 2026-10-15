#' ---
#' title: "W6 Take-home Lab: Document Classification"
#' subtitle: "Text as Data | National Taiwan University"
#' format:
#'   html:
#'     embed-resources: true
#'     toc: true
#'     toc-depth: 2
#'     code-copy: true
#' execute:
#'   warning: false
#'   message: false
#' ---
#' 
#' ## Before starting
#' 
#' [**Work in pairs (two students).**]{style="color: #e2021a;"}
#' 
#' **Ungraded take-home practice; no submission.** Fit Naive Bayes and a linear SVM. Compare their predictions with the reference labels and read the texts behind classification errors. Allow **60–90 minutes** for sections 1–5, with extra time if you are new to R. The model extensions are optional.
#' 
#' Extract the lab ZIP, then open **`Lab_Session_W6.R`** in RStudio and read this handout alongside it. Set the working directory to the folder containing that R file and keep its `Data/` folder beside it. Run section 1 once, then continue in order in the same R session. You do not need to render the source QMD.
#' 
#' Try the exercises before opening [the worked answers](answers/Lab_Session_W6_Answers.html). Each code block is followed by its printed output and a discussion question. Bring questions to [instructor](https://calendly.com/ycliao/text-as-data-instructor) or [TA](https://calendly.com/ycliao/text-as-data-ta) office hours.
#' 
#' The required packages are `quanteda`, `quanteda.textmodels`, `mlr3`, `mlr3learners`, `e1071` and `stringi`. Complete the [package check in section 1](#package-check-install-and-load) before C01. The setup reads the CSVs directly.
#' 
#' ## Reading the R code
#' 
#' Work from top to bottom in the same R session. In RStudio, select a line or block and use `Ctrl+Enter` (Windows) or `Cmd+Enter` (Mac). Read the printed output before moving to the next step.
#' 
#' | Syntax | Meaning | Example |
#' |---|---|---|
#' | `<-` | Save a result under a name | `hs_dfm <- dfm(hs_tokens)` |
#' | `$` with a data frame | Select a column | `hate$label` |
#' | `$` with an mlr3 object | Access a field or call a method | `gs_result$response`, `gs_result$score(measures)` |
#' | `[rows, columns]` | Select rows or columns | `hs_dfm[hs_split$train, ]` |
#' | `c(...)` | Combine values | `c("NonHateSpeech", "HateSpeech")` |
#' | `==`, `!=` | Equal to, different from | `nb_prediction != parts$test$label` |
#' | `which(...)` | Find row positions where a condition is TRUE | `which(nb_prediction != parts$test$label)` |
#' | `table(...)` | Count categories | `table(hate$label)` |
#' 
#' The `C` and `G` checkpoint names match the W6 slides. Lettered and numbered substeps belong to the same workflow and should run in order. The code uses existing package functions directly.
#' 
#' ### Functions used in the lab
#' 
#' | Step | Existing functions | Package |
#' |---|---|---|
#' | Read a CSV | `read.csv()`, `factor()` | base R |
#' | Reserve test data | `as_task_classif()`, `partition()` | mlr3 |
#' | Count text features | `corpus()`, `tokens()`, `dfm()` | quanteda |
#' | Keep training vocabulary | `dfm_trim()`, `dfm_match()` | quanteda |
#' | Fit hate-speech NB | `textmodel_nb()`, `predict()` | quanteda.textmodels |
#' | Fit grandstanding SVM | `lrn()`, `$train()`, `$predict_newdata()` | mlr3 + mlr3learners |
#' | Check predictions | `PredictionClassif$new()`, `$score()`, `msrs()` | mlr3 |
#' 
#' `lmtest` supplies tests for regression models. Classification accuracy, precision, recall and F1 in this exercise come from mlr3.
#' 
#' ## Datasets and labels
#' 
#' | Exercise | Data | Classifier | Main interface |
#' |---|---|---|---|
#' | Hate speech | Wang, Day & Wu (2022) | Multinomial Naive Bayes | quanteda.textmodels |
#' | Grandstanding | Park (2021) | Linear SVM | mlr3 + mlr3learners |
#' 
#' Both exercises use quanteda to count text features and mlr3 to reserve test rows and calculate evaluation measures. The results below are classroom reanalyses, separate from the papers’ reported models.
#' 
#' ### Source columns and lab columns
#' 
#' | Data | Original field | Practice CSV field |
#' |---|---|---|
#' | Wang, Day & Wu (2022) | `text` | `text` |
#' | Wang, Day & Wu (2022) | `hate_speech` (0/1) | `label` (NonHateSpeech/HateSpeech) |
#' | Park (2021) | `speech` | `text` |
#' | Park (2021) | `rescaled_gs` (0/1) | `label` (NonGrandstanding/Grandstanding) |
#' 
#' `doc_id` identifies rows and `key` checks text overlap. Neither is a predictor. The labels retain the source data’s binary categories. No new cutoff is applied.
#' 
#' ## 1. Set up R
#' 
#' **5–10 minutes.** Check the packages, then locate `Data/`. The SVM check should print `"classif.svm"`; the C01 data check should print `TRUE`. Keep this R session open for both cases.
#' 
#' ### Package check: install and load
#' 
#' **Install once.** Run this command before the first exercise if the packages are not installed.
#' 
#' ```r
#' install.packages(c("quanteda", "quanteda.textmodels",
#'   "mlr3", "mlr3learners", "e1071", "stringi"),
#'   repos = "https://cloud.r-project.org")
#' ```
#' 
#' **Load in each new R session.** Run the check below before C01.
#' 
## -----------------------------------------------------------------------------
# Package loading check
library(quanteda); library(quanteda.textmodels)
library(mlr3); library(mlr3learners)
library(e1071); library(stringi)
lrn("classif.svm")$id

#' 
#' **Ready:** all six packages load without errors, and the last line returns `"classif.svm"`. Continue to C01.
#' 
#' ### C01. Setup
#' 
#' **Practice:** Identify which package supplies each function. Keep one R session open.
#' 
## -----------------------------------------------------------------------------
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

#' 
#' **Discuss after running:** What does FALSE indicate about the data path?
#' 
#' 
#' ## 2. Hate speech: Naive Bayes with quanteda.textmodels
#' 
#' **25–30 minutes.** Use the data from **Wang, Day & Wu (2022)**. Reserve test comments, count Chinese characters, select a vocabulary using only training rows, and fit Naive Bayes. After checking the held-out comments, apply the same fitted model to the separate human-reference sample.
#' 
#' ### C02. Load the Wang, Day & Wu (2022) data
#' 
#' **Practice:** Which hate-speech label is more common?
#' 
## -----------------------------------------------------------------------------
# C02: Load the Wang, Day & Wu (2022) data
hate <- read.csv(file.path(data_dir,
  "hate_speech_practice.csv"), stringsAsFactors = FALSE)
hate$label <- factor(hate$label,
  levels = c("NonHateSpeech", "HateSpeech"))
table(hate$label)
nrow(hate)

#' 
#' **Discuss after running:** Which class is more common? What would always predicting that class achieve?
#' 
#' 
#' ### C03. Reserve test comments with mlr3
#' 
#' **Practice:** Which rows must stay outside vocabulary selection and model fitting?
#' 
## -----------------------------------------------------------------------------
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

#' 
#' **Discuss after running:** Why reserve test rows before selecting the vocabulary?
#' 
#' 
#' ### C04a_1. Hate speech: tokenize Chinese characters
#' 
#' | Function / object | What it does here |
#' |---|---|
#' | `stri_trans_nfkc()` | stringi: normalize Unicode forms in a working text copy. |
#' | `quanteda::tokens()` | Turn each comment into character tokens. |
#' 
## -----------------------------------------------------------------------------
# C04a_1: Normalize and tokenize Chinese comments
hs_text <- stringi::stri_trans_nfkc(hate$text)
names(hs_text) <- hate$doc_id
hs_tokens <- tokens(hs_text, what = "character",
  remove_punct = TRUE, remove_symbols = TRUE,
  remove_numbers = TRUE)
class(hs_tokens)

#' 
#' **Discuss after running:** Why does what = "character" produce characters rather than Chinese words?
#' 
#' 
#' ### C04a_2. Hate speech: turn tokens into a DFM
#' 
#' | Function / object | What it does here |
#' |---|---|
#' | `tokens_select()` | Retain tokens matching the Han-character pattern. |
#' | `dfm()` | Count features in a sparse document-feature matrix. |
#' 
## -----------------------------------------------------------------------------
# C04a_2: Select Han characters and count features
hs_tokens <- tokens_select(hs_tokens,
  pattern = "^\\p{Han}$", valuetype = "regex")
hs_dfm <- dfm(hs_tokens)
dim(hs_dfm)

#' 
#' **Discuss after running:** What do the 4,000 rows and 2,916 columns represent?
#' 
#' 
#' ### C04b_1. Hate speech: select the training vocabulary
#' 
#' | Function / object | What it does here |
#' |---|---|
#' | `dfm_trim()` | Keep features occurring in at least 1% of training documents. |
#' | `train_label` | Keep one label per training row, in the same order. |
#' 
## -----------------------------------------------------------------------------
# C04b_1: Trim training features
train_dfm <- dfm_trim(hs_dfm[hs_split$train, ],
  min_docfreq = .01, docfreq_type = "prop")
train_label <- parts$train$label
dim(train_dfm)

#' 
#' **Discuss after running:** Does min_docfreq count documents or total token occurrences?
#' 
#' 
#' ### C04b_2. Hate speech: match the test columns
#' 
#' | Function / object | What it does here |
#' |---|---|
#' | `featnames()` | Read the training feature names in column order. |
#' | `dfm_match()` | Match that order, drop extra features and fill missing ones with zero. |
#' 
## -----------------------------------------------------------------------------
# C04b_2: Match test features to training columns
test_dfm <- dfm_match(hs_dfm[hs_split$test, ],
  features = featnames(train_dfm))
dim(test_dfm)
identical(featnames(train_dfm), featnames(test_dfm))

#' 
#' **Discuss after running:** Why must the 800 test rows use the same 603 columns in the same order?
#' 
#' 
#' ### C05. Fit Naive Bayes
#' 
#' **Practice:** Which object holds the fitted NB model?
#' 
## -----------------------------------------------------------------------------
# C05: Fit Naive Bayes
nb <- textmodel_nb(train_dfm, y = train_label,
  distribution = "multinomial", smooth = 1,
  prior = "docfreq")
class(nb)
nb$distribution

#' 
#' **Discuss after running:** Which argument supplies the training labels?
#' 
#' 
#' ### C06. Predict and evaluate with mlr3
#' 
#' **Practice:** Locate one false positive and one false negative in the confusion matrix.
#' 
## -----------------------------------------------------------------------------
# C06: Predict and evaluate with mlr3
nb_prediction <- predict(nb, newdata = test_dfm)
nb_check <- PredictionClassif$new(task = hs_task,
  row_ids = hs_split$test,
  truth = hs_task$truth(hs_split$test),
  response = as.character(nb_prediction))
nb_check$confusion
nb_scores <- nb_check$score(measures)
round(nb_scores, 3)

#' 
#' **Discuss after running:** Rows are predictions. Which cells are false positives and false negatives?
#' 
#' 
#' 
#' 
#' `PredictionClassif` stores the reference labels and predictions. `$score(measures)` computes the metrics defined in C01. The task’s `positive` class determines precision, recall and F1.
#' 
#' ### C07. Inspect one held-out comment
#' 
#' **Practice:** Compare the predicted category with the provided label.
#' 
## -----------------------------------------------------------------------------
# C07: Inspect one held-out comment
i <- match("hs_26234", parts$test$doc_id)
cat(parts$test$text[i], "\n")
predict(nb, newdata = test_dfm[i, ])
round(predict(nb, newdata = test_dfm[i, ],
              type = "probability"), 3)
parts$test$label[i]

#' 
#' **Discuss after running:** Which words express group-based degradation or exclusion?
#' 
#' 
#' ### C08a. Match human-reference texts to the vocabulary
#' 
#' Read the merged **`hate_speech_reference.csv`** directly. Its `source` column records the original BERT/Lexicon filename (or both), while `label` contains the final **是否仇恨 (Hate speech: Yes/No)** category. The original model-prediction columns are excluded. This step evaluates the existing NB model and does not train a BERT model.
#' 
#' **Practice:** Why apply the training vocabulary to the human-reference comments?
#' 
## -----------------------------------------------------------------------------
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

#' 
#' **Discuss after running:** Do the 17 zero-feature rows mean empty comments or no retained characters?
#' 
#' 
#' ### C08b. Evaluate the separate human references
#' 
#' **Practice:** What changes on the separate human-reference sample?
#' 
## -----------------------------------------------------------------------------
# C08b: Evaluate the separate human references
ref_task <- as_task_classif(benchmark["label"],
  target = "label", positive = "HateSpeech")
benchmark$prediction <- predict(nb, newdata = ref_dfm)
ref_check <- PredictionClassif$new(task = ref_task,
  row_ids = ref_task$row_ids,
  response = as.character(benchmark$prediction))
benchmark_scores <- ref_check$score(measures)
nrow(benchmark); round(benchmark_scores, 3)

#' 
#' **Discuss after running:** Recall is .880, but precision is .165. What errors does that imply?
#' 
#' 
#' 
#' 
#' `PredictionClassif` stores the reference labels and predictions. `$score(measures)` computes the metrics defined in C01. The task’s `positive` class determines precision, recall and F1.
#' 
#' ## 3. Grandstanding: linear SVM with mlr3
#' 
#' **20–30 minutes.** Use **Park (2021)** data. Repeat the workflow with English word features and an mlr3 learner. The target is the dataset’s existing binary `rescaled_gs` category. The SVM probability and the original research score describe different quantities.
#' 
#' ### G01a. Load the Park (2021) data
#' 
#' **Practice:** Which original field supplies the grandstanding target?
#' 
## -----------------------------------------------------------------------------
# G01a: Load the Park (2021) data
grandstanding <- read.csv(file.path(data_dir,
  "grandstanding_practice.csv"), stringsAsFactors = FALSE)
grandstanding$label <- factor(grandstanding$label,
  levels = c("NonGrandstanding", "Grandstanding"))
table(grandstanding$label)

#' 
#' **Discuss after running:** Which class is more common in the Park (2021) data?
#' 
#' 
#' ### G01b. Reserve test excerpts with mlr3
#' 
#' **Practice:** Which category is the positive class?
#' 
## -----------------------------------------------------------------------------
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

#' 
#' **Discuss after running:** How does stratification preserve both categories in the test set?
#' 
#' 
#' ### G02a_1. Grandstanding: build a corpus and tokens
#' 
#' | Function / object | What it does here |
#' |---|---|
#' | `corpus()` | Read text and document IDs from the data table. |
#' | `tokens()` | Split the selected text into words and remove the requested token types. |
#' 
## -----------------------------------------------------------------------------
# G02a_1: Build an English corpus and tokens
gs_corpus <- corpus(grandstanding,
  text_field = "text", docid_field = "doc_id")
gs_tokens <- tokens(gs_corpus, remove_punct = TRUE,
  remove_symbols = TRUE, remove_numbers = TRUE,
  remove_url = TRUE)
ndoc(gs_corpus)

#' 
#' **Discuss after running:** Which column supplies text, and which column supplies document IDs?
#' 
#' 
#' ### G02a_2. Grandstanding: normalize and count words
#' 
#' | Function / object | What it does here |
#' |---|---|
#' | `tokens_tolower()` | Combine upper- and lowercase versions of words. |
#' | `tokens_remove()` | Remove the English stopword list from the tokens. |
#' | `dfm()` | Count the remaining words for each document. |
#' 
## -----------------------------------------------------------------------------
# G02a_2: Normalize English tokens and build a DFM
gs_tokens <- tokens_tolower(gs_tokens)
gs_tokens <- tokens_remove(gs_tokens,
  pattern = stopwords("en"))
gs_dfm <- dfm(gs_tokens)
dim(gs_dfm)

#' 
#' **Discuss after running:** How do these word features differ from the Chinese character features?
#' 
#' 
#' ### G02a_3. Grandstanding: trim and align the vocabulary
#' 
#' | Function / object | What it does here |
#' |---|---|
#' | `dfm_trim()` | Choose words using training document frequencies. |
#' | `dfm_match()` | Give test documents the same feature columns. |
#' 
## -----------------------------------------------------------------------------
# G02a_3: Select training words and match test columns
gs_train_dfm <- dfm_trim(gs_dfm[gs_split$train, ],
  min_docfreq = .01, docfreq_type = "prop")
gs_test_dfm <- dfm_match(gs_dfm[gs_split$test, ],
  features = featnames(gs_train_dfm))
dim(gs_train_dfm); dim(gs_test_dfm)

#' 
#' **Discuss after running:** Why do both matrices have 629 columns even though they contain different texts?
#' 
#' 
#' ### G02b_1. Grandstanding: convert the DFM for mlr3
#' 
#' | Function / object | What it does here |
#' |---|---|
#' | `quanteda::convert()` | Turn the small sparse DFM into a dense data frame. |
#' | `doc_id <- NULL` | Remove the identifier, leaving 629 numeric feature columns. |
#' 
## -----------------------------------------------------------------------------
# G02b_1: Convert text counts to feature tables
gs_train_data <- convert(gs_train_dfm, to = "data.frame")
gs_test_data <- convert(gs_test_dfm, to = "data.frame")
gs_train_data$doc_id <- NULL; gs_test_data$doc_id <- NULL
dim(gs_train_data); dim(gs_test_data)

#' 
#' **Discuss after running:** Why should a document ID stay outside the predictor columns?
#' 
#' 
#' ### G02b_2. Grandstanding: add the target column
#' 
#' | Function / object | What it does here |
#' |---|---|
#' | `make.names()` | Create valid, unique feature names. |
#' | `label` | Add the target after the 629 feature columns. |
#' 
## -----------------------------------------------------------------------------
# G02b_2: Name feature columns and add labels
names(gs_train_data) <- make.names(featnames(gs_train_dfm),
  unique = TRUE)
names(gs_test_data) <- names(gs_train_data)
gs_train_data$label <- gs_parts$train$label
gs_test_data$label <- factor(gs_parts$test$label,
  levels = c("Grandstanding", "NonGrandstanding"))
dim(gs_train_data); dim(gs_test_data)

#' 
#' **Discuss after running:** Why are there now 630 columns, but only 629 predictors?
#' 
#' 
#' ### G02c_1. mlr3: define the classification task
#' 
#' | Function / object | What it does here |
#' |---|---|
#' | `as_task_classif()` | Describe the training data, target column and positive class. |
#' | `TaskClassif` | Stores data and roles. Creating the task does not train a model. |
#' 
## -----------------------------------------------------------------------------
# G02c_1: Define the grandstanding task
gs_model_task <- as_task_classif(gs_train_data,
  target = "label", positive = "Grandstanding")
gs_model_task$target_names
length(gs_model_task$feature_names)

#' 
#' **Discuss after running:** Which column is the target, and why is it excluded from feature_names?
#' 
#' 
#' ### G02c_2. mlr3: choose an SVM learner
#' 
#' | Function / object | What it does here |
#' |---|---|
#' | `lrn()` | Create an unfitted learner and set its options. |
#' | `predict_type = "prob"` | Request class probabilities as well as predicted categories. |
#' 
## -----------------------------------------------------------------------------
# G02c_2: Configure the linear SVM learner
library(mlr3learners)
gs_learner <- lrn("classif.svm", type = "C-classification",
  kernel = "linear", cost = 1, scale = FALSE,
  predict_type = "prob")
gs_learner$id
gs_learner$predict_type

#' 
#' **Discuss after running:** Has lrn() already learned from any training rows?
#' 
#' 
#' ### G02c_3. mlr3: train and predict
#' 
#' | Function / object | What it does here |
#' |---|---|
#' | `$train(task)` | Fit the learner using the training task. |
#' | `$predict_newdata()` | Return predictions for the held-out feature table. |
#' | `$response` / `$prob` | Read category labels / the matrix of class probabilities. |
#' 
## -----------------------------------------------------------------------------
# G02c_3: Train the learner and predict held-out texts
set.seed(7193)
gs_learner$train(gs_model_task)
gs_result <- gs_learner$predict_newdata(gs_test_data)
gs_prediction <- gs_result$response
length(gs_prediction)
colnames(gs_result$prob)

#' 
#' **Discuss after running:** Which object stores the fitted learner, and which stores the 700 test predictions?
#' 
#' 
#' ### G02d. Evaluate the mlr3 predictions
#' 
## -----------------------------------------------------------------------------
# G02d: Evaluate the mlr3 predictions
gs_result$confusion
gs_scores <- gs_result$score(measures)
round(gs_scores, 3)

#' 
#' **Discuss after running:** Locate the 74 false positives and 155 false negatives.
#' 
#' 
#' `PredictionClassif` stores the reference labels and predictions. `$score(measures)` computes the metrics defined in C01. The task’s `positive` class determines precision, recall and F1.
#' 
#' ### G03. Inspect one grandstanding prediction
#' 
#' **Practice:** Does this prediction agree with the provided rescaled_gs category?
#' 
## -----------------------------------------------------------------------------
# G03: Inspect one grandstanding prediction
j <- match("gs_01045", gs_parts$test$doc_id)
cat(gs_parts$test$text[j], "\n")
gs_result$response[j]
round(gs_result$prob[j, ], 3)
gs_result$truth[j]

#' 
#' **Discuss after running:** Which words suggest self-promotion? Read the full statement next.
#' 
#' 
#' ## 4. Read and compare prediction errors
#' 
#' **10–15 minutes.** Read one full text from each case. Use the confusion matrix to identify the type of error, then explain the category boundary in your own words.
#' 
#' ### Follow the slide demonstration
#' 
#' `which()` finds the held-out rows where prediction and reference differ. Select the first error, compare the categories and probability, then print the complete statement. This block is identical to the **Read performance with the text** slide.
#' 
## -----------------------------------------------------------------------------
# Read one grandstanding prediction error
error_rows <- which(gs_result$response != gs_result$truth)
k <- error_rows[1]
data.frame(
  doc_id = gs_parts$test$doc_id[k],
  reference = gs_result$truth[k],
  prediction = gs_result$response[k],
  prob = round(gs_result$prob[k, "Grandstanding"], 3),
  row.names = NULL)
cat(gs_parts$test$text[k], "\n")

#' 
#' **Discuss:** Is this a false positive or a false negative? Which metric does it lower? Does describing the needs of a district count as self-promotion?
#' 
#' ### Repeat with the hate-speech model
#' 
## -----------------------------------------------------------------------------
hate_errors <- which(nb_prediction != parts$test$label)
cat(parts$test$text[hate_errors[1]], "\n")

#' 
#' Read both full texts and explain the category boundary. Identify any cases where the text alone leaves the label uncertain.
#' 
#' **Discuss:** Which case has higher precision? Which has higher recall? These datasets have different labels, languages and class frequencies, so their scores do not isolate the effect of the algorithm. Changing a model after examining test errors requires a fresh evaluation sample.
#' 
#' ## 5. Write a short practice report
#' 
#' **5 minutes.** Write five sentences covering the data and labels, split, features, classifier settings, and test results. Include one error you read. No separate submission is required.
#' 
#' ## Optional: try another classifier
#' 
#' Finish the core practice first. These blocks are displayed for reference and do not run in the main R script. To try one, run its code separately after completing the required steps.
#' 
#' ### Logistic regression with quanteda.textmodels
#' 
#' Keep the same training matrix and held-out test matrix. `textmodel_lr()` selects its penalty using cross-validation within the training data. Run this section only after C01–C08.
#' 

#' 
#' ### Reuse the mlr3 SVM for hate speech
#' 
#' The required grandstanding exercise already uses `mlr3learners` and `e1071`. Use the small classroom vocabulary for this demonstration: converting to a data frame creates a dense matrix. For large text datasets, consider learners/backends that support sparse features.
#' 

#' 
#' `$train()` fits the classifier. `$predict()` returns a prediction object; `$score()` compares its predictions with the held-out labels. This optional model uses the same split and training-derived vocabulary as NB.
#' 
#' ## Data notes
#' 
#' The lab reads three CSVs directly: `hate_speech_practice.csv` (4,000 comments), `hate_speech_reference.csv` (1,968 human references), and `grandstanding_practice.csv` (3,499 excerpts). The existing labels are unchanged. Their preparation removes duplicated/conflicting text labels and excludes every raw human-reference text from the hate-speech practice pool before sampling. It does not select a vocabulary or fit a model.
#' 
#' Both classifiers use text counts only. Grandstanding’s conversion to a data frame makes a dense table; the modest 629-word vocabulary is for this classroom example. For larger text matrices, use learners/backends that support sparse features.
#' 
#' The original source CSVs remain in `Data`. `prepare_practice_data.R` reproduces the cleaned CSVs using base R and stringi; students do not need to run it for the core exercise. See `Data/README.md` and `practice_manifest.json` for cleaning rules and counts. Label and score fields never enter X.
#' 
#' The split uses mlr3 `partition()` with seed 7192 and label stratification. Hate speech fits multinomial NB via quanteda.textmodels; grandstanding fits a linear SVM via mlr3. The SVM uses type C-classification, a linear kernel, cost 1 and scale FALSE. Seed 7193 makes its probability fitting reproducible. Its results are not a reproduction of Park’s original research model. These splits separate texts, not necessarily authors, hearings, threads or time periods.
#' 
#' ## Reading connections
#' 
#' - [Wang, Day & Wu (2022)](https://doi.org/10.1109/ACCESS.2022.3160712): source of the hate-speech data.
#' - [Park (2021)](https://doi.org/10.1086/709147): source of the grandstanding data.
#' - [quanteda](https://quanteda.io/reference/index.html) and [quanteda.textmodels](https://quanteda.io/quanteda.textmodels/): text features and Naive Bayes.
#' - mlr3: [partition](https://mlr3.mlr-org.com/reference/partition.html), [PredictionClassif](https://mlr3.mlr-org.com/reference/PredictionClassif.html), and [SVM learner](https://mlr3learners.mlr-org.com/reference/mlr_learners_classif.svm.html).
