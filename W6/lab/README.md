# W6 Take-home Lab: Document Classification

Ungraded practice; no submission. Allow 60–90 minutes for the core exercise.

1. Extract the ZIP and open `W6/lab/Lab_Session_W6.html` as the student handout.
2. Open `Lab_Session_W6.R` in RStudio and set the working directory to its folder, beside `Data/`.
3. Complete the installation and loading check in section 1. All six packages should load without errors, and `lrn("classif.svm")$id` should return `"classif.svm"`. Then run C01 and sections 2–4 in order in the same R session: hate-speech NB, grandstanding SVM, and error reading.
4. Compare your results with `answers/Lab_Session_W6_Answers.html`. Its R script runs from the same lab folder, one level above `answers/`.

The handout follows the W4 format: starting instructions, an R syntax guide, numbered exercises with discussion prompts, optional extensions, and reading connections. All 24 C01–C08 / G01–G03 checkpoints, including all substeps, match the slides. The source QMDs do not need to be rendered. No custom function or workflow.R is loaded.

Section 4 includes the **Read performance with the text** slide demonstration. Its code also appears in `error_reading.R`, which can run after section 3 in the same R session. It prints a grandstanding prediction error, its reference label and probability, then the full statement.

Install quanteda, quanteda.textmodels, mlr3, mlr3learners, e1071 and stringi. Hate speech uses Wang, Day & Wu (2022) and quanteda.textmodels::textmodel_nb(). Grandstanding uses Park (2021) and mlr3 lrn("classif.svm"), $train(), $predict_newdata() and $score(). quanteda builds both sets of text features. mlr3 partition() reserves test rows; positive classes are explicit.

Data/README.md documents original labels and the cleaned CSVs. prepare_practice_data.R reproduces them before class and is separate from the student exercise. The human-reference check applies only to hate speech. These are classroom reanalyses, separate from the original publications’ model results.

optional_classifiers.R shows logistic regression and reuses mlr3 SVM for the hate-speech features. Those extensions are not executed in the core R script. Worked answers and actual output are available in the lab HTML.
