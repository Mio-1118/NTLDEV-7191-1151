# W7: Wordscores and Wordfish on the Irish 2010 budget speeches
# We run S01-S08b, including all lettered substeps, in one R session.
# We use quanteda, quanteda.textmodels, quanteda.textplots and base R.
# We compare our estimates and read the speeches to interpret disagreements.

# S01: Packages and the built-in corpus
# install.packages(c("quanteda", "quanteda.textmodels",
#                    "quanteda.textplots"))
library(quanteda)
library(quanteda.textmodels)
library(quanteda.textplots)
quanteda_options(threads = 1)
options(width = 72, digits = 4)
corp_irish <- data_corpus_irishbudget2010
c(quanteda = as.character(packageVersion("quanteda")),
  textmodels = as.character(packageVersion("quanteda.textmodels")),
  textplots = as.character(packageVersion("quanteda.textplots")))
ndoc(corp_irish)

# S02a: Speakers and stable document IDs
meta <- data.frame(
  doc_id = paste0("ie_", docvars(corp_irish, "number")),
  speaker = docvars(corp_irish, "name"),
  party = docvars(corp_irish, "party"))
docnames(corp_irish) <- meta$doc_id
print(meta, row.names = FALSE)

# S02b: Tokenize a working copy
toks_irish <- tokens(corp_irish, remove_punct = TRUE,
  remove_symbols = TRUE, remove_numbers = TRUE)
toks_irish <- tokens_tolower(toks_irish)
head(as.list(toks_irish)[[1]], 12)

# S02c: Build the common count matrix
counts <- dfm(toks_irish)
dim(counts)
any(ntoken(counts) == 0)
topfeatures(counts, 6)

# S03: Define the Wordscores references
ref_scores <- rep(NA_real_, ndoc(counts))
names(ref_scores) <- docnames(counts)
ref_ids <- c("ie_01", "ie_02")
ref_scores[ref_ids] <- c(1, -1)
print(data.frame(speaker = meta$speaker[match(ref_ids, meta$doc_id)],
  reference = ref_scores[ref_ids]), row.names = FALSE)

# S04a: Fit Wordscores and inspect word scores
ws <- textmodel_wordscores(counts, y = ref_scores, smooth = 0)
probe_words <- c("budget", "government", "tax",
                 "jobs", "fair", "recovery")
print(data.frame(word = probe_words,
  score = round(coef(ws)[probe_words], 3)), row.names = FALSE)

# S04b: Align the scoring vocabulary and inspect coverage
ws_counts <- dfm_match(counts, features = names(coef(ws)))
ws_coverage <- ntoken(ws_counts) / ntoken(counts)
dim(ws_counts)
summary(ws_coverage)

# S04c: Predict raw Wordscores for every speech
ws_pred <- predict(ws, newdata = ws_counts, rescaling = "none")
results <- meta
results$reference <- ref_scores
results$ws_raw <- as.numeric(ws_pred)
results$coverage <- ws_coverage
print(data.frame(speaker = results$speaker, party = results$party,
  reference = results$reference,
  ws_raw = round(results$ws_raw, 3)), row.names = FALSE)

# S04d: Plot raw Wordscores with model-based intervals
ws_plot <- predict(ws, newdata = ws_counts,
  se.fit = TRUE, rescaling = "none")
ws_labels <- paste0(meta$speaker,
  ifelse(is.na(ref_scores), "", " [reference]"))
textplot_scale1d(ws_plot, doclabels = ws_labels, sort = TRUE) +
  ggplot2::labs(x = NULL, y = "Raw Wordscores") +
  ggplot2::theme_minimal(base_size = 24)

# S05a: Fit Wordfish and fix its orientation
wf_dir <- match(c("ie_02", "ie_01"), docnames(counts))
set.seed(7197)
wf <- textmodel_wordfish(counts, dir = wf_dir,
  dispersion = "poisson")
data.frame(speaker = meta$speaker[wf_dir],
  theta = round(wf$theta[wf_dir], 3))

# S05b: Inspect Wordfish positions and model standard errors
results$wf_theta <- wf$theta
results$wf_se <- wf$se.theta
print(data.frame(speaker = results$speaker, party = results$party,
  theta = round(results$wf_theta, 3),
  se = round(results$wf_se, 3)), row.names = FALSE)

# S05c: Inspect word discrimination and baseline frequency
word_id <- match(probe_words, wf$features)
print(data.frame(word = probe_words,
  beta = round(wf$beta[word_id], 3),
  psi = round(wf$psi[word_id], 3)), row.names = FALSE)

# S05d: Plot Wordfish positions with model-based intervals
textplot_scale1d(wf, doclabels = meta$speaker, sort = TRUE) +
  ggplot2::labs(x = NULL, y = "Wordfish position (theta)") +
  ggplot2::theme_minimal(base_size = 24)

# S06a: Compare rankings among the twelve new texts
comparison <- results[is.na(results$reference), ]
comparison$ws_rank <- rank(comparison$ws_raw)
comparison$wf_rank <- rank(comparison$wf_theta)
comparison$gap <- abs(comparison$ws_rank - comparison$wf_rank)
comparison <- comparison[order(-comparison$gap, comparison$doc_id), ]
round(cor(comparison$ws_raw, comparison$wf_theta,
  method = "spearman"), 3)
print(head(comparison[c("speaker", "ws_rank", "wf_rank", "gap")], 6),
  row.names = FALSE)

# S06b: Plot the new texts on both scales
plot(comparison$ws_raw, comparison$wf_theta,
  type = "n", xlim = c(-0.08, 0.24),
  xlab = "Wordscores (raw)", ylab = "Wordfish (theta)")
abline(h = 0, v = 0, col = "grey45", lty = 2, lwd = 1.8)
points(comparison$ws_raw, comparison$wf_theta,
  pch = 19, col = "#0271bb")
text(comparison$ws_raw[1:3], comparison$wf_theta[1:3],
  labels = comparison$speaker[1:3], pos = 4, cex = 0.85)

# S07a: Identify and read the largest ranking disagreement
read_id <- comparison$doc_id[1]
print(comparison[1, c("doc_id", "speaker", "ws_rank", "wf_rank")],
  row.names = FALSE)
read_sentences <- as.character(corpus_reshape(
  corp_irish[read_id], to = "sentences"))
cat(strwrap(read_sentences[1], width = 66), sep = "\n")

# S07b: Read more of the same speech
# In this corpus, the selected speech is Burton's. Read sentences 5-7.
cat(strwrap(paste(read_sentences[5:7], collapse = " "),
  width = 66), sep = "\n")
# For the full speech in your console:
# cat(as.character(corp_irish[read_id]))

# S08a: Replace the positive reference and refit Wordscores
ref_alt <- ref_scores
ref_alt[c("ie_01", "ie_05")] <- c(NA, 1)
ws_alt <- textmodel_wordscores(counts, y = ref_alt, smooth = 0)
ws_alt_counts <- dfm_match(counts, features = names(coef(ws_alt)))
ws_alt_pred <- predict(ws_alt, newdata = ws_alt_counts,
  rescaling = "none")
print(data.frame(speaker = meta$speaker[!is.na(ref_alt)],
  reference = ref_alt[!is.na(ref_alt)]), row.names = FALSE)

# S08b: Compare ranks within the same eleven new texts
common_new <- is.na(ref_scores) & is.na(ref_alt)
sensitivity <- meta[common_new, c("doc_id", "speaker")]
sensitivity$before <- rank(ws_pred[common_new])
sensitivity$after <- rank(ws_alt_pred[common_new])
sensitivity$change <- sensitivity$after - sensitivity$before
print(sensitivity[c("speaker", "before", "after", "change")],
  row.names = FALSE)
