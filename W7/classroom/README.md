# W7 Wordscores and Wordfish

We use Wordscores and Wordfish to examine support for the 2010 Irish budget. We compare the models' rankings, read a speech on which they disagree, and check how the results change when we choose a different reference text.

With `quanteda`, `quanteda.textmodels` and `quanteda.textplots` installed, we open `W7_scaling.R` and run S01–S08b, including the lettered substeps, in one R session. We follow the same steps as the slides and use the explanations after each output to read the results.

The fourteen speeches come with `quanteda.textmodels` as `data_corpus_irishbudget2010`. They concern the 2010 Irish budget, debated in December 2009. We load the corpus directly from the package. The `Data` folder contains a CSV copy of the original texts and metadata for reading and reuse.

| Steps | What we examine |
|---|---|
| S01–S02c | The corpus, speakers and count DFM |
| S03–S04d | Reference choices, word scores, vocabulary coverage, raw document scores and their plot |
| S05a–S05d | Wordfish positions, standard errors, word parameters and the position plot |
| S06a–S06b | Ranking agreement and disagreements among twelve new texts |
| S07a–S07b | The selected speech and its surrounding argument |
| S08a–S08b | Sensitivity to the positive reference on eleven common new texts |

At S03, we assign Brian Lenihan +1 and Richard Bruton −1 to represent support for and opposition to this budget. We leave the other twelve reference scores unknown. At S08, we replace Lenihan with Brian Cowen at +1. We then compare rankings within the same eleven speeches, excluding Lenihan, Bruton and Cowen from both rankings.

For preprocessing, we remove punctuation, symbols and numbers, and lowercase the words. We retain stopwords and use the counts without stemming, trimming or TF-IDF weighting. Both methods start from the same count matrix. With `smooth = 0`, Wordscores learns scores for the reference vocabulary. At S04b, we match the prediction columns to that vocabulary and calculate the share of tokens retained in each speech. Wordfish uses the full count matrix.

S04d and S05d first plot each model separately with `textplot_scale1d()`, following the [quanteda plotting example](https://quanteda.io/articles/pkgdown/examples/plotting.html#plot-fitted-scaling-models). Both plots show fourteen speeches with approximate 95% intervals. The Wordscores reference labels mark rescored predictions, not the assigned endpoints. The intervals describe model or scoring uncertainty and do not validate budget-support meaning.

At S06, we compare the models using Spearman rank correlation and label the three largest ranking disagreements in the plot. The axes have different units. Rank agreement describes how similarly the models order these texts; independent human judgments would provide additional evidence about budget support. Wordfish standard errors describe uncertainty conditional on the fitted model.

At S07, we return to the speech with the largest rank gap. With the data and settings used here, this is Joan Burton's speech. We read its opening and sentences 5–7, asking how the quotation and surrounding argument affect our interpretation. If we change the data or model, we first check which speech is selected and which passages we need to read.

The recorded run uses quanteda 4.3.1, quanteda.textmodels 0.9.10, quanteda.textplots 0.96.1 and ggplot2 4.0.2. We use one processing thread and set seed 7197 immediately before fitting Wordfish. Other package versions may produce small numerical differences. The results are our classroom estimates, using the preprocessing and settings described above.

Research context: [Lowe & Benoit (2013)](https://doi.org/10.1093/pan/mpt002). Methods: [Wordscores](https://doi.org/10.1017/S0003055403000698) and [Wordfish](https://doi.org/10.1111/j.1540-5907.2008.00338.x).
