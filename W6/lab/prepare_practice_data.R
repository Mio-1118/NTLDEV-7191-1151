# Instructor preparation, separate from the student lab. Run from the course root.
# Uses base R and stringi; retains the existing labels and original CSVs.
data_dirs <- c('W6/lab/Data', 'Data', '../Data')
data_dir <- data_dirs[dir.exists(data_dirs)][1]
stopifnot(!is.na(data_dir))
raw <- read.csv(file.path(data_dir, 'merged-hate-speeches.csv'), stringsAsFactors=FALSE)
raw$doc_id <- sprintf('hs_%05d', seq_len(nrow(raw)))
raw$label <- factor(ifelse(raw$hate_speech == 1, 'HateSpeech', 'NonHateSpeech'),
                    levels=c('NonHateSpeech', 'HateSpeech'))
raw$key <- tolower(gsub('[[:space:]\\x{FEFF}]+', '',
  stringi::stri_trans_nfkc(enc2utf8(raw$text)), perl=TRUE))
pairs <- unique(raw[c('key','label')])
conflicts <- unique(pairs$key[duplicated(pairs$key) | duplicated(pairs$key, fromLast=TRUE)])
valid <- raw[!raw$key %in% conflicts, ]
clean <- valid[!duplicated(valid$key), c('doc_id','text','label','key')]

bench_raw <- read.csv(file.path(data_dir, 'hate_speech_benchmark.csv'), stringsAsFactors=FALSE)
bench_raw$key <- tolower(gsub('[[:space:]\\x{FEFF}]+', '',
  stringi::stri_trans_nfkc(enc2utf8(bench_raw$text)), perl=TRUE))
pairs <- unique(bench_raw[c('key','label')])
bench_conflicts <- unique(pairs$key[duplicated(pairs$key) | duplicated(pairs$key, fromLast=TRUE)])
bench_valid <- bench_raw[!bench_raw$key %in% bench_conflicts, ]
benchmark <- bench_valid[!duplicated(bench_valid$key), ]
for (k in seq_len(nrow(benchmark))) {
  benchmark$source[k] <- paste(sort(unique(bench_valid$source[
    bench_valid$key == benchmark$key[k]])), collapse='+')
}
benchmark$label <- factor(ifelse(benchmark$label == 1, 'HateSpeech', 'NonHateSpeech'),
                          levels=c('NonHateSpeech', 'HateSpeech'))
# Exclude ALL raw reference text keys, including conflicting reference groups.
eligible <- clean[!clean$key %in% bench_raw$key, ]
sizes <- floor(4000 * table(eligible$label) / nrow(eligible))
sizes[length(sizes)] <- 4000 - sum(sizes[-length(sizes)])
set.seed(7191)
ids <- integer()
for (category in levels(eligible$label)) {
  ids <- c(ids, sample(which(eligible$label == category), sizes[category]))
}
hate <- eligible[sort(ids), ]

park_raw <- read.csv(file.path(data_dir, 'gscore_julia_park.csv'), stringsAsFactors=FALSE)
park_raw$doc_id <- sprintf('gs_%05d', seq_len(nrow(park_raw)))
park_raw$text <- park_raw$speech
park_raw$label <- factor(ifelse(park_raw$rescaled_gs == 1, 'Grandstanding', 'NonGrandstanding'),
                         levels=c('NonGrandstanding', 'Grandstanding'))
park_raw$key <- tolower(gsub('[[:space:]]+', ' ', trimws(
  stringi::stri_trans_nfkc(park_raw$text))))
pairs <- unique(park_raw[c('key','label')])
park_conflicts <- unique(pairs$key[duplicated(pairs$key) | duplicated(pairs$key, fromLast=TRUE)])
park_valid <- park_raw[!park_raw$key %in% park_conflicts, ]
grandstanding <- park_valid[!duplicated(park_valid$key), c('doc_id','text','label','key')]

stopifnot(nrow(raw)==31071, nrow(eligible)==23615, nrow(hate)==4000,
          nrow(benchmark)==1968, nrow(grandstanding)==3499,
          !any(hate$key %in% bench_raw$key), !anyDuplicated(grandstanding$key))
write.csv(hate, file.path(data_dir, 'hate_speech_practice.csv'), row.names=FALSE, fileEncoding='UTF-8')
write.csv(benchmark, file.path(data_dir, 'hate_speech_reference.csv'), row.names=FALSE, fileEncoding='UTF-8')
write.csv(grandstanding, file.path(data_dir, 'grandstanding_practice.csv'), row.names=FALSE, fileEncoding='UTF-8')
manifest <- list(
  preparation_script='W6/scripts/prepare_practice_data.R', sample_seed=7191,
  hate=list(raw=nrow(raw), conflict_rows=sum(raw$key %in% conflicts),
    duplicates=nrow(valid)-nrow(clean), benchmark_overlap=nrow(clean)-nrow(eligible),
    eligible=nrow(eligible), practice=nrow(hate), counts=as.list(table(hate$label))),
  reference=list(raw=nrow(bench_raw), conflict_rows=sum(bench_raw$key %in% bench_conflicts),
    duplicates=nrow(bench_valid)-nrow(benchmark), rows=nrow(benchmark)),
  grandstanding=list(raw=nrow(park_raw), conflict_rows=sum(park_raw$key %in% park_conflicts),
    duplicates=nrow(park_valid)-nrow(grandstanding), rows=nrow(grandstanding)),
  files=as.list(tools::md5sum(file.path(data_dir,c('hate_speech_practice.csv',
    'hate_speech_reference.csv','grandstanding_practice.csv')))))
jsonlite::write_json(manifest, file.path(data_dir, 'practice_manifest.json'),
                     pretty=TRUE, auto_unbox=TRUE)
cat('Prepared CSVs: 4000 hate-speech comments, 1968 human references, 3499 grandstanding excerpts.\n')
