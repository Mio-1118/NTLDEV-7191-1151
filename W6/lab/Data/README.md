# W6 classification practice data: hate speech and grandstanding

Original study: Wang, Chih-Chien, Min-Yuh Day, and Chun-Lian Wu. 2022. “Political Hate Speech Detection and Lexicon Building: A Study in Taiwan.” *IEEE Access* 10:44337–44346. https://doi.org/10.1109/ACCESS.2022.3160712. IEEE Xplore is the publication platform.

`merged-hate-speeches.csv` is the instructor-authorized existing Flair fine-tuning copy from `Dropbox/taiwanese_hate_speech/merged-hate-speeches.csv`: 31,071 rows, `text`, `hate_speech`, `label`; 17,548 positives and 13,523 negatives. Preserve its existing binary labels. They are not recomputed from individual coder ratings or model probabilities. The file is a local reorganisation, not a claim to reproduce the paper’s exact corpus counts or original BERT performance.

`hate_speech_benchmark.csv` is an exact cell-value export of the two supplied 1,000-comment validation spreadsheets. Text comes from 留言 and the reference category from 是否仇恨. Original coder1/coder2/coder3 values are retained. Their rating-to-category aggregation is not reconstructed. The original BERT/Lexicon prediction columns do not become predictors or reference labels. Source spreadsheets remain available locally.

## Reading the merged human-reference file

For the exercise, open **`hate_speech_reference.csv`** directly. It combines and cleans the two original validation files; students do not need to open Excel or fit a BERT model. The prepared file contains 1,968 distinct comments: 209 HateSpeech and 1,759 NonHateSpeech.

| Original location | Prepared CSV column | Meaning in the exercise |
|---|---|---|
| Column A: `留言` | `text` | Original comment to classify |
| Column I: `是否仇恨` | `label` | Final reference category: 1 becomes HateSpeech; 0 becomes NonHateSpeech |
| Original filename | `source` | BERT or Lexicon records the input file; BERT+Lexicon marks 15 comments present in both |
| Columns C, E, G: `標註員1`, `標註員2`, `標註員3` | `coder1`, `coder2`, `coder3` | Original coder values, retained as metadata |
| Column B: `Bert標註結果` or `Lexicon標註結果` | Excluded | Original model predictions, unused in this exercise |

The original files are `Bert-1000筆一般與仇恨言論驗證.xlsx` and `Lexicon-1000筆一般與仇恨言論驗證.xlsx`. Each contains one worksheet named `工作表1`. BERT and Lexicon therefore identify filenames and the respective original prediction columns, rather than worksheet names. In the prepared CSV they appear only in `source` and source-derived row IDs. Use `text` for features and `label` for evaluation; source and coder metadata are excluded from the classifier.

## Preparation and evaluation

Before class, `W6/scripts/prepare_practice_data.R` normalises text keys (Unicode NFKC, whitespace/BOM removal, lowercasing), removes all rows in conflicting-label groups and duplicates, excludes every raw benchmark text key, and draws a fixed 4,000-comment sample with existing class proportions (seed 7191). The 31,071-row source yields 23,985 distinct unambiguous texts after removing 1,275 conflicting rows and 5,811 duplicates; 370 benchmark overlaps are excluded, leaving 23,615 eligible. The teaching sample has 2,378 HateSpeech and 1,622 NonHateSpeech labels.

The separate benchmark removes eight rows belonging to four conflicting-label text groups and 24 duplicate rows, leaving 1,968 distinct reference-labelled comments (209 positive, 1,759 negative). Source is BERT, Lexicon, or BERT+Lexicon for the 15 shared comments. No benchmark text or outcome enters training, feature fitting, model fitting or vocabulary selection. Feature-empty benchmark texts remain in evaluation.

Only Chinese character-count features enter X. Labels, original model predictions, coder scores, IDs and source metadata are excluded. The normalised-text check cannot guarantee separation by user, news story, thread or time because those identifiers are not supplied in this copy.

`hate_source_manifest.json` records input provenance and exported CSV SHA-256 hashes. `prepare_hate_data.py` reproduces exports from the existing local source files. Current W6 metrics are classroom NB (hate speech) and linear SVM (grandstanding) reanalyses. Earlier multi-model and EU versions are preserved in W6/archive.


`gscore_julia_park.csv` is the instructor-supplied grandstanding training copy (3,500 rows). Park, Ju Yeon. 2021. “When Do Politicians Grandstand? Measuring Message Politics in Committee Hearings.” *The Journal of Politics* 83(1):214–228. https://doi.org/10.1086/709147. Replication: https://doi.org/10.7910/DVN/GSMBFX.

The classroom uses `speech` as text and the supplied binary `rescaled_gs` as the target (0=NonGrandstanding, 1=Grandstanding). The file does not document its original binary conversion cutoff and does not supply individual coder votes. `sentimentit_score` is an original grandstanding score, not a generic sentiment measure, and is excluded from predictors. English comparison keys use NFKC/lowercase and collapsed whitespace. One same-label duplicate is removed, leaving 3,499 rows (1,846 negative, 1,653 positive); mlr3 `partition()` with label stratification, ratio .8 and seed 7192 gives 2,799 train and 700 test in the current run.

Hate speech uses quanteda.textmodels multinomial NB with smooth=1 and prior=docfreq. Grandstanding uses mlr3/ mlr3learners linear SVM with type C-classification, kernel linear, cost=1, scale=FALSE and predict_type=prob. SVM probability fitting uses seed 7193. Hate speech uses Han-character counts; grandstanding uses lowercased English word counts without English stopwords. Only training document frequency determines the 1% feature cutoff; test matrices match that vocabulary. These are text-level splits, not claims of user, hearing, thread or time independence.


## Files read directly by the current lab

- `hate_speech_practice.csv`: 4,000 cleaned comments, with original text/labels and a normalized comparison key.
- `hate_speech_reference.csv`: 1,968 cleaned human references, preserving source and coder metadata.
- `grandstanding_practice.csv`: 3,499 distinct Park (2021) excerpts, with label names derived directly from the existing `rescaled_gs` field.
- `practice_manifest.json`: cleaning counts and MD5 hashes for the three generated CSVs.

Students read these files with `read.csv()`; they do not call preparation helpers. `prepare_practice_data.R`, included beside the student R script, reproduces these CSVs from the preserved originals using base R/stringi. It never selects a text vocabulary or fits a model. The script is separate from the classroom exercise.

The current split uses the existing mlr3 `partition()` function, replacing the earlier custom 80/20 implementation. Hate speech: 3,200 train / 800 test, 603 retained character features. Grandstanding: 2,799 train / 700 test, 629 retained word features. Figures and metrics in the slides/answers were recomputed with this split. Test row IDs and labels match mlr3 evaluation objects explicitly. `positive` is HateSpeech or Grandstanding; `classif.fbeta` uses beta=1 (F1). The human-reference set includes 17 zero-feature documents. Package versions are recorded in W6/analysis/classification_practice_summary.json.

Grandstanding SVM uses 629 numeric text predictors and a separate label column; doc_id, key, rescaled_gs and original score fields never enter X. The task sets Grandstanding as positive, and test label factors follow the same class order. The existing score 2.003 for gs_01045 is used only to illustrate a high-score statement; the fitted SVM probability is a different quantity.
