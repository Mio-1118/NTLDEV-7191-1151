# Irish budget speech data

We use fourteen speeches on the 2010 Irish budget, debated in December 2009. The file `irish_budget2010.csv` contains the original texts and metadata from `quanteda.textmodels::data_corpus_irishbudget2010`, package version 0.9.10. We retain the original wording and punctuation. The `budget_year` field records 2010; the speeches were delivered in December 2009.

| Field | Meaning |
|---|---|
| doc_id | Stable ID derived from the corpus speech number |
| speaker | Speaker surname from the corpus |
| party | Party abbreviation from the corpus |
| budget_year | Original corpus year variable |
| source_document | Original corpus document name |
| text | Full original speech |

In the R exercise, we load the corpus directly from the package. We can use this CSV to read the same speeches or work with them in another program. The CSV contains texts and metadata. We assign the −1/+1 Wordscores reference scores in `Lab_Session_W7.R`; independently validated position scores would require additional evidence.

Source study: Lowe, Will, and Kenneth Benoit. 2013. “Validating Estimates of Latent Traits from Textual Data Using Human Judgment as a Benchmark.” *Political Analysis* 21(3): 298–313. [DOI](https://doi.org/10.1093/pan/mpt002).
