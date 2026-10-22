# Run from the course root; retain handout prose as comments in student scripts.
for (stem in c("Lab_Session_W6", "Lab_Session_W6_Answers")) {
  destination <- if (stem == "Lab_Session_W6") "W6/lab" else "W6/lab/answers"
  output <- file.path(destination, paste0(stem, ".R"))
  knitr::purl(file.path("W6/lab/source", paste0(stem, ".qmd")),
    output = output,
    documentation = 2, quiet = TRUE)
  # purl adds spaces to blank prose comments; keep generated scripts tidy.
  writeLines(sub("[ \t]+$", "", readLines(output, warn = FALSE)),
    output, useBytes = TRUE)
}
