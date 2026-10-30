# W7 Lab: Scaling Political Texts

[Lab HTML](https://raw.githack.com/davidycliao/NTLDEV-7191-1151/main/W7/lab/Lab_Session_W7.html) · [R script](Lab_Session_W7.R) · [Lab ZIP](https://github.com/davidycliao/NTLDEV-7191-1151/raw/refs/heads/main/W7/downloads/week7-lab.zip)

We use Wordscores and Wordfish to examine support for the 2010 Irish budget. We compare their rankings, read a speech on which they disagree, and check sensitivity to a different positive reference text. This is ungraded practice; no submission is required. We allow 60–75 minutes, including discussion and speech reading.

We plot each model separately before comparing them: S04d shows raw Wordscores, S05d shows Wordfish positions, and S06b retains the two-model scatterplot. The two single-model plots include all fourteen speeches; the comparison plot uses the twelve new texts for Wordscores.

We download and extract the Lab ZIP, open `Lab_Session_W7.html` in a browser, and run `Lab_Session_W7.R` in RStudio. We work through S01–S08b, including all lettered substeps, in one R session. Each step in the HTML presents the code, its actual output and a direct explanation of the values or plotted results. We can read the HTML offline; we do not need Quarto to use the handout.

We need `quanteda`, `quanteda.textmodels` and `quanteda.textplots`. If they are not installed, we run:

```r
install.packages(c("quanteda", "quanteda.textmodels", "quanteda.textplots"),
  repos = "https://cloud.r-project.org")
```

The displayed run uses quanteda 4.3.1, quanteda.textmodels 0.9.10 and quanteda.textplots 0.96.1, one processing thread and seed 7197 before Wordfish. With other package versions, we may see small numerical differences.

| Steps | What we examine |
|---|---|
| S01–S02c | The corpus, metadata, tokens and count matrix |
| S03–S04d | Wordscores references, learned word scores, coverage, raw predictions and their plot |
| S05a–S05d | Wordfish orientation, positions, model standard errors, word parameters and the position plot |
| S06a–S07b | Ranking agreement, the two-model scatterplot, disagreements and the original speech context |
| S08a–S08b | A different positive reference and rankings among eleven common new texts |

We load the fourteen speeches directly from `quanteda.textmodels::data_corpus_irishbudget2010`. The debate took place in December 2009 and concerned the 2010 budget. `Data/irish_budget2010.csv` supplies the original texts and metadata for reading and reuse; the [data README](Data/README.md) describes its fields. We keep the data folder beside the R script, although fitting uses the package corpus directly.

We distinguish the reference values we assign, the positions we estimate, and independent judgments we would need for validation. A correlation between the two models describes their ranking agreement. It does not establish accuracy against human judgments, and the Wordfish standard errors do not establish the substantive meaning of its dimension.

S04d and S05d use [`quanteda.textplots::textplot_scale1d()`](https://quanteda.io/articles/pkgdown/examples/plotting.html#plot-fitted-scaling-models), with `ggplot2::labs()` and `ggplot2::theme_minimal()` for formatting. The bars are 95% normal intervals, extending 1.96 standard errors either side of each estimate. They do not validate the political meaning of a score. The reference labels in the Wordscores plot identify the two input speeches; their raw predictions differ from the assigned −1/+1 values.

The nineteen checkpoint IDs and executable code follow the W7 classroom script `W7_scaling.R`. We use this lab to read the same outputs with direct explanations of their meaning.

To edit and render the handout, we use `source/Lab_Session_W7.qmd`. With Quarto, R, `knitr`, `rmarkdown` and the three analysis and plotting packages installed, we run the following from the extracted `week7-lab` folder:

```sh
quarto render source/Lab_Session_W7.qmd --embed-resources --execute-dir .
```

We rerun the model steps when we render the QMD. We move the new `source/Lab_Session_W7.html` beside `Lab_Session_W7.R`, replacing the supplied HTML, so its relative file links remain usable. The supplied HTML already contains the executed results.

[W7 student slides](https://raw.githack.com/davidycliao/NTLDEV-7191-1151/main/W7/slide/week7.html) · [Course homepage](https://github.com/davidycliao/NTLDEV-7191-1151#slides-and-lab-sessions)
