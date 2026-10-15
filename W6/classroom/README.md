# W6: quanteda NB and mlr3 linear SVM

Open R in this unzipped folder so its Data folder is available. Run W6_classification.R, C01–C08 then G01–G03 including lettered and numbered substeps, in one R session. All 24 checkpoints match the slides. No custom function or workflow.R is loaded.

After G03, run `error_reading.R` in that same session for the **Read performance with the text** demonstration. It finds a held-out grandstanding error, displays the reference/prediction/probability, and prints the full statement. It uses the fitted model directly and does not retrain it.

Install quanteda, quanteda.textmodels, mlr3, mlr3learners, e1071 and stringi. Hate speech uses Wang, Day & Wu (2022) and quanteda.textmodels::textmodel_nb(). Grandstanding uses Park (2021) and mlr3 lrn("classif.svm"), $train(), $predict_newdata() and $score(). quanteda builds both sets of text features. mlr3 partition() reserves test rows; positive classes are explicit.

Data/README.md documents original labels and the cleaned CSVs. prepare_practice_data.R reproduces them before class and is separate from the student exercise. The human-reference check applies only to hate speech. These are classroom reanalyses, separate from the original publications’ model results.

optional_classifiers.R shows logistic regression and reuses mlr3 SVM for the hate-speech features. Those extensions are not executed in the core R script. Worked answers and actual output are available in the lab HTML.
