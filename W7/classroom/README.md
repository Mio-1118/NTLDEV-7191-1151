# W7 Wordscores and Wordfish

We use Wordscores and Wordfish to examine support for the 2010 Irish budget. We compare the models' rankings, read a speech on which they disagree, and check how the results change when we choose a different reference text.

With `quanteda` and `quanteda.textmodels` installed, we open `W7_scaling.R` and run S01–S08b, including the lettered substeps, in one R session. We follow the same steps as the slides and pause after each output to discuss its interpretation.

The fourteen speeches come with `quanteda.textmodels` as `data_corpus_irishbudget2010`. They concern the 2010 Irish budget, debated in December 2009. We load the corpus directly from the package. The `Data` folder contains a CSV copy of the original texts and metadata for reading and reuse.

| Steps | What we examine |
|---|---|
| S01–S02c | The corpus, speakers and count DFM |
| S03–S04c | Reference choices, word scores, vocabulary coverage and raw document scores |
| S05a–S05c | Wordfish positions, standard errors and word parameters |
| S06a–S06b | Ranking agreement and disagreements among twelve new texts |
| S07a–S07b | The selected speech and its surrounding argument |
| S08a–S08b | Sensitivity to the positive reference on eleven common new texts |

At S03, we assign Brian Lenihan +1 and Richard Bruton −1 to represent support for and opposition to this budget. We leave the other twelve reference scores unknown. At S08, we replace Lenihan with Brian Cowen at +1. We then compare rankings within the same eleven speeches, excluding Lenihan, Bruton and Cowen from both rankings.

For preprocessing, we remove punctuation, symbols and numbers, and lowercase the words. We retain stopwords and use the counts without stemming, trimming or TF-IDF weighting. Both methods start from the same count matrix. With `smooth = 0`, Wordscores learns scores for the reference vocabulary. At S04b, we match the prediction columns to that vocabulary and calculate the share of tokens retained in each speech. Wordfish uses the full count matrix.

At S06, we compare the models using Spearman rank correlation and label the three largest ranking disagreements in the plot. The axes have different units. Rank agreement describes how similarly the models order these texts; independent human judgments would provide additional evidence about budget support. Wordfish standard errors describe uncertainty conditional on the fitted model.

At S07, we return to the speech with the largest rank gap. With the data and settings used here, this is Joan Burton's speech. We read its opening and sentences 5–7, asking how the quotation and surrounding argument affect our interpretation. If we change the data or model, we first check which speech is selected and which passages we need to read.

The recorded run uses quanteda 4.3.1 and quanteda.textmodels 0.9.10. We use one processing thread and set seed 7197 immediately before fitting Wordfish. Other package versions may produce small numerical differences. The results are our classroom estimates, using the preprocessing and settings described above.

Research context: [Lowe & Benoit (2013)](https://doi.org/10.1093/pan/mpt002). Methods: [Wordscores](https://doi.org/10.1017/S0003055403000698) and [Wordfish](https://doi.org/10.1111/j.1540-5907.2008.00338.x).
